import 'dart:convert';
import 'dart:developer';

import 'package:animations/animations.dart';
import 'package:appcheck/appcheck.dart';
// import 'package:app_launcher/app_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gita_app/models/chapters_model.dart';
import 'package:gita_app/models/notification_store_model.dart';
import 'package:gita_app/models/user_login_model.dart';
import 'package:gita_app/models/verses_model.dart';
import 'package:gita_app/screens/chapters_screen.dart';
import 'package:gita_app/screens/home_screen.dart';
import 'package:gita_app/screens/verse_details_screen.dart';
import 'package:gita_app/screens/verses_screen.dart';
import 'package:gita_app/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';

// import 'package:url_launcher/url_launcher_string.dart';

import '../providers/theme_provider.dart';
import '../providers/tts_provider.dart';
import '../services/keys.dart';
import '../services/storage_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
    this.initialIndex,
  }) : super(key: key);

  final int? initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<int> completedChapters = [];
  List<int> completedVerses = [];
  int currentIndex = 0;
  String selectedOption = '';
  FlutterTts flutterTts = FlutterTts();
  TextStyle summaryTextStyle = const TextStyle(
    color: AppColors.white,
    height: 1.5,
    fontSize: 16,
  );
  bool hasNext = false,
      hasPrev = false,
      isLangChanging = false,
      isBannerAdLoaded = false;
  bool? isCompletedChapter;
  int currentWordIndex = -1;
  late ItemScrollController _itemScrollController;
  ChaptersModel? chapter;
  late TabController _tabBarController;
  BannerAd? _bannerAd;
  UserLoginModel? userLoginModel;
  bool phoneVisibility = false;
  bool desVisibility = false;
  bool skillVisibility = false;
  bool emailVisibility = true;
  bool isProfileLoading = false;
  AdSize adSize = AdSize.largeBanner;
  InterstitialAd? _interstitialAd;
  bool isInterstitialAdLoaded = false;
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();
  bool isAtTop = false;
  bool isAtBottom = false;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> fetchCompletedChapters() async {
    completedChapters = await JsonStorage.getCompletedChapters();

    setState(() {});
  }

  Future<void> fetchCompletedVerses() async {
    completedVerses = await JsonStorage.getCompletedVerses();

    setState(() {});
  }

  void getDetails() async {
    selectedOption = await JsonStorage.getTheme() ?? "System";
    userLoginModel = await JsonStorage.getUsrData();
    await fetchCompletedChapters();
    await fetchCompletedVerses();

    if (completedChapters.isEmpty) {
      currentIndex = 1;
    }

    await flutterTts.setSpeechRate(0.31);

    await flutterTts.setPitch(1.1);

    await flutterTts.setLanguage("en-IN");

    flutterTts.setStartHandler(() {
      Provider.of<TTSProvider>(context, listen: false)
          .playingStatusUpdate(true);
    });

    flutterTts.setCompletionHandler(() {
      log("complete");
      // Provider.of<TTSProvider>(context, listen: false)
      //     .setLyricsCompleteStatus(true);
      if (Provider.of<TTSProvider>(context, listen: false).isPlaying) {
        log("auto next");
        nextLyrics(Provider.of<TTSProvider>(context, listen: false));
        _itemScrollController.jumpTo(index: 0);
      }
    });

    flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      // log(currentWordIndex.toString());
      Provider.of<TTSProvider>(context, listen: false).wordIndexIncrease();
      // log(word);
    });
  }

  int calculateVisibleWords(String text, double containerWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: containerWidth);

    final words = text.split(' ');
    int visibleWords = 0;
    double currentWidth = 0.0;

    for (final word in words) {
      textPainter.text = TextSpan(text: '$word ');
      textPainter.layout();

      if (currentWidth + textPainter.width <= containerWidth) {
        currentWidth += textPainter.width;
        visibleWords++;
      } else {
        break;
      }
    }

    return visibleWords;
  }

  bool isMarqueeNeeded(String text, double containerWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: containerWidth);

    // Adjust this threshold as needed based on your design
    const double marqueeThreshold = 0.9; // 90% of container width

    return textPainter.width > containerWidth * marqueeThreshold;
  }

  bool isValueInList(int value, List<int> integerList) {
    if (integerList.contains(value)) {
      return true; // Value is present in the list
    } else {
      return false; // Value is not present in the list
    }
  }

  void nextLyrics(TTSProvider ttsProvider) async {
    // log("nextLyrics");
    final Map<String, dynamic> nextChapter =
        await JsonStorage.getNextChapter(ttsProvider.chapterID);

    if (nextChapter["hasNext"]) {
      flutterTts.stop();
      // ttsProvider.resetChapterID();
      NotificationStoreModel? notificationStoreModel =
          await JsonStorage.getLastPlayedChapterNotification();
      int notificationID = (notificationStoreModel != null)
          ? notificationStoreModel.notificationId
          : await JsonStorage.getNotificationID() ?? 0;

      await AwesomeNotifications().cancelSchedule(notificationID);
      // await AwesomeNotifications().cancelNotificationsByChannelKey(
      //     Keys.mediaNotificationChapterChannelKey);
      ttsProvider.resetLyricsWordsEnglish();
      ttsProvider.wordIndexReset();
      ttsProvider.resetChapterID();
      ttsProvider.resetChapterName();
      ttsProvider.setChapterID(nextChapter["id"]);
      bool completed =
          await JsonStorage.isChapterCompleted(ttsProvider.chapterID);
      ttsProvider.setCompleteStatus(completed);
      ttsProvider.playingStatusUpdate(true);
      ttsProvider.setLyricsCompleteStatus(false);
      DateTime notificationTime =
          await JsonStorage.addAndGetNotificationTimeLastPlayedChapter();
      NotificationCalendar notificationCalendar = NotificationCalendar(
        year: notificationTime.year,
        month: notificationTime.month,
        hour: notificationTime.hour,
        minute: notificationTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      );
      if (ttsProvider.chapterSummaryLang == "english") {
        ttsProvider.setChapterName(nextChapter["name_translated"].trim());
        ttsProvider.setLyricsWordsEnglish(
          nextChapter["chapter_summary"]
              .trim()
              .replaceAll("\n", " ")
              .split(" "),
        );
        await flutterTts.setLanguage("en-IN");

        log(isCompletedChapter.toString());

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationID,
              channelKey: Keys.lastPlayedChapterChannelKey,
              notificationLayout: NotificationLayout.BigText,
              title: "Continue Your Bhagavad Gita Journey",
              body:
                  "📖 Time for the next chapter! Dive in and grow spiritually. 🌟",
              payload: {
                "time": notificationTime.toString(),
                "lang": "English",
                "type": "chapter",
                "chapter": jsonEncode(nextChapter),
                "isCompleted": !completed ? "0" : "1",
                "wordIdx": ttsProvider.wordIndex.toString(),
                "langIndex":
                    ttsProvider.chapterSummaryLang == "english" ? "0" : "1",
              }),
          schedule: notificationCalendar,
        );

        await flutterTts.speak(nextChapter["chapter_summary"].trim());
      } else if (ttsProvider.chapterSummaryLang == "hindi") {
        ttsProvider.setChapterName(nextChapter["name"].trim());
        ttsProvider.setLyricsWordsEnglish(
          nextChapter["chapter_summary_hindi"]
              .trim()
              .replaceAll("\n", " ")
              .split(" "),
        );
        await flutterTts.setLanguage("hi-IN");

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationID,
              channelKey: Keys.lastPlayedChapterChannelKey,
              notificationLayout: NotificationLayout.BigText,
              title: "Ready for the Next Chapter?",
              body:
                  "🎮 Finished Chapter ${ttsProvider.chapterID}? Dive into the next for spiritual wisdom. Press to continue your enlightening journey! 🌟",
              payload: {
                "time": notificationTime.toString(),
                "lang": "Hindi",
                "type": "chapter",
                "chapter": jsonEncode(nextChapter),
                "isCompleted": !completed ? "0" : "1",
                "wordIdx": ttsProvider.wordIndex.toString(),
                "langIndex":
                    ttsProvider.chapterSummaryLang == "english" ? "0" : "1",
              }),
          schedule: notificationCalendar,
        );

        await JsonStorage.setLastPlayedChapterNotification(
          NotificationStoreModel(
            id: nextChapter["id"],
            notificationId: notificationID,
          ),
        );

        await flutterTts.speak(nextChapter["chapter_summary_hindi"].trim());
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 0,
            channelKey: Keys.mediaNotificationChapterChannelKey,
            title: ttsProvider.chapterName,
            body: "Now playing chapter ${ttsProvider.chapterID}",
            notificationLayout: NotificationLayout.Default,
            roundedBigPicture: true,
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            locked: true,
            category: NotificationCategory.Event,
            payload: {
              "time": notificationTime.toString(),
              "chapter": jsonEncode(chapter),
            }),
      );
      await JsonStorage.setLastPlayedChapterNotification(
        NotificationStoreModel(
          id: nextChapter["id"],
          notificationId: notificationID,
        ),
      );
      hasNext = true;
    } else {
      hasNext = false;
    }
  }

  void prevLyrics(TTSProvider ttsProvider) async {
    final Map<String, dynamic> prevChapter =
        await JsonStorage.getPrevChapter(ttsProvider.chapterID);

    if (prevChapter["hasNext"]) {
      _itemScrollController.jumpTo(index: 0);

      flutterTts.stop();
      NotificationStoreModel? notificationStoreModel =
          await JsonStorage.getLastPlayedChapterNotification();
      int notificationID = (notificationStoreModel != null)
          ? notificationStoreModel.notificationId
          : await JsonStorage.getNotificationID() ?? 0;

      await AwesomeNotifications().cancelSchedule(notificationID);
      // await AwesomeNotifications().cancelNotificationsByChannelKey(
      //     Keys.mediaNotificationChapterChannelKey);
      // ttsProvider.resetChapterID();
      ttsProvider.resetLyricsWordsEnglish();
      ttsProvider.wordIndexReset();
      ttsProvider.resetChapterID();
      ttsProvider.resetChapterName();
      ttsProvider.setChapterID(prevChapter["id"]);
      // changeDefaultColor();
      ttsProvider.playingStatusUpdate(true);
      bool completed =
          await JsonStorage.isChapterCompleted(ttsProvider.chapterID);
      ttsProvider.setCompleteStatus(completed);
      DateTime notificationTime =
          await JsonStorage.addAndGetNotificationTimeLastPlayedChapter();
      NotificationCalendar notificationCalendar = NotificationCalendar(
        year: notificationTime.year,
        month: notificationTime.month,
        hour: notificationTime.hour,
        minute: notificationTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      );
      if (ttsProvider.chapterSummaryLang == "english") {
        ttsProvider.setChapterName(prevChapter["name_translated"].trim());
        ttsProvider.setLyricsWordsEnglish(
          prevChapter["chapter_summary"]
              .trim()
              .replaceAll("\n", " ")
              .split(" "),
        );
        await flutterTts.setLanguage("en-IN");

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationID,
              channelKey: Keys.lastPlayedChapterChannelKey,
              notificationLayout: NotificationLayout.BigText,
              title: "Continue Your Bhagavad Gita Journey",
              body:
                  "📖 Explore more wisdom! Play Chapter ${ttsProvider.chapterID} of the Bhagavad Gita. Tap to continue your journey. 🌟",
              payload: {
                "time": notificationTime.toString(),
                "lang": "English",
                "type": "chapter",
                "chapter": jsonEncode(prevChapter),
                "isCompleted": !completed ? "0" : "1",
                "wordIdx": ttsProvider.wordIndex.toString(),
                "langIndex":
                    ttsProvider.chapterSummaryLang == "english" ? "0" : "1",
              }),
          schedule: notificationCalendar,
        );

        await flutterTts.speak(prevChapter["chapter_summary"].trim());
      } else if (ttsProvider.chapterSummaryLang == "hindi") {
        ttsProvider.setChapterName(prevChapter["name"].trim());
        ttsProvider.setLyricsWordsEnglish(
          prevChapter["chapter_summary_hindi"]
              .trim()
              .replaceAll("\n", " ")
              .split(" "),
        );
        await flutterTts.setLanguage("hi-IN");

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationID,
              channelKey: Keys.lastPlayedChapterChannelKey,
              notificationLayout: NotificationLayout.BigText,
              title: "Continue Your Bhagavad Gita Journey",
              body:
                  "📖 Explore the Bhagavad Gita! Finish ${ttsProvider.chapterID} and dive into the next chapter for timeless teachings. 🌟✨",
              payload: {
                "time": notificationTime.toString(),
                "lang": "Hindi",
                "type": "chapter",
                "chapter": jsonEncode(prevChapter),
                "isCompleted": !completed ? "0" : "1",
                "wordIdx": ttsProvider.wordIndex.toString(),
                "langIndex":
                    ttsProvider.chapterSummaryLang == "english" ? "0" : "1",
              }),
          // actionButtons: [
          //   NotificationActionButton(
          //     key: "continue",
          //     label: "Continue",
          //   ),
          // ],
          schedule: notificationCalendar,
        );

        await flutterTts.speak(prevChapter["chapter_summary_hindi"].trim());
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 0,
            channelKey: Keys.mediaNotificationChapterChannelKey,
            title: ttsProvider.chapterName,
            body: "Now playing chapter ${ttsProvider.chapterID}",
            notificationLayout: NotificationLayout.Default,
            roundedBigPicture: true,
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            locked: true,
            category: NotificationCategory.Event,
            payload: {
              "time": notificationTime.toString(),
              "chapter": jsonEncode(chapter),
            }),
      );
      await JsonStorage.setLastPlayedChapterNotification(
        NotificationStoreModel(
          id: prevChapter["id"],
          notificationId: notificationID,
        ),
      );
    }
  }

  void chapterDetailsFunc(TTSProvider ttsProvider) async {
    chapter = ChaptersModel.fromJson(
      await JsonStorage.getNextChapter(
        ttsProvider.chapterID - 1,
      ),
    );
    isCompletedChapter = await JsonStorage.isChapterCompleted(
      ttsProvider.chapterID,
    );
  }

  Future<int> completionRate() async {
    // ((totalDone / (totalTasks - totalDelete)) * 100).round();

    String uid = userLoginModel!.data.uid;
    String token = userLoginModel!.token;

    http.Response response = await http.get(
        Uri.parse("${Keys.apiUsersBaseUrl}/completionRate/$uid"),
        headers: {
          "content-type": "application/json",
          'Authorization': 'Bearer $token',
        });

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      log(responseJson.toString());
      if (responseJson["success"]) {
        return responseJson["completionRate"];
      }
    }

    return 0;
  }

  void stopPlayingChapter(TTSProvider ttsProvider) async {
    ttsProvider.resetLyricsWordsEnglish();
    ttsProvider.resetChapterName();
    ttsProvider.wordIndexReset();
    ttsProvider.resetCompleteStatus();
    ttsProvider.resetLyricsCompleteStatus();
    ttsProvider.playingStatusUpdate(false);
    await AwesomeNotifications().cancelNotificationsByChannelKey(
        Keys.mediaNotificationChapterChannelKey);
    await flutterTts.stop();
  }

  void _checkScrollPosition1() {
    final maxScroll = _scrollController1.position.maxScrollExtent;
    final currentScroll = _scrollController1.position.pixels;

    // Check if at the top
    if (currentScroll <= 0) {
      if (!isAtTop) {
        isAtTop = true;
        HapticFeedback.vibrate();
      }
    } else {
      isAtTop = false;
    }

    // Check if at the bottom
    if (currentScroll >= maxScroll) {
      if (!isAtBottom) {
        isAtBottom = true;
        HapticFeedback.vibrate();
      }
    } else {
      isAtBottom = false;
    }
  }

  void _checkScrollPosition2() {
    final maxScroll = _scrollController2.position.maxScrollExtent;
    final currentScroll = _scrollController2.position.pixels;

    // Check if at the top
    if (currentScroll <= 0) {
      if (!isAtTop) {
        isAtTop = true;
        HapticFeedback.vibrate();
      }
    } else {
      isAtTop = false;
    }

    // Check if at the bottom
    if (currentScroll >= maxScroll) {
      if (!isAtBottom) {
        isAtBottom = true;
        HapticFeedback.vibrate();
      }
    } else {
      isAtBottom = false;
    }
  }

  @override
  void initState() {
    getDetails();
    _itemScrollController = ItemScrollController();
    _tabBarController = TabController(
      length: 2,
      initialIndex: widget.initialIndex ?? 0,
      vsync: this,
    );

    _tabBarController.addListener(() {
      setState(() {});
    });

    _bannerAd = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/2231287028",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isBannerAdLoaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isBannerAdLoaded = false;
        setState(() {});
        _bannerAd?.dispose();
      })),
      request: const AdRequest(),
    );

    _bannerAd?.load();

    _scrollController1.addListener(_checkScrollPosition1);
    _scrollController2.addListener(_checkScrollPosition2);

    AwesomeNotifications().setListeners(
      onNotificationCreatedMethod: ((receivedNotification) {
        log("SCHEDULED DATE TIME ${receivedNotification.payload?["time"]}\nCREATED CHANNEL KEY ${receivedNotification.channelKey}");
        return Future.value();
      }),
      onActionReceivedMethod: ((receivedNotification) {
        log(receivedNotification.channelKey ?? "CHANNEL KEY NULL");
        if (receivedNotification.channelKey ==
                Keys.lastCheckedChapterChannelKey ||
            receivedNotification.channelKey ==
                Keys.completedChapterChannelKey) {
          if (receivedNotification.payload!["type"] == "chapter") {
            log(receivedNotification.payload.toString());
            return Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => VersesScreen(
                  chapter: ChaptersModel.fromJson(
                      jsonDecode(receivedNotification.payload!["chapter"]!)),
                  isCompleted:
                      (receivedNotification.payload!["isCompleted"] == "0")
                          ? false
                          : true,
                  flutterTts: flutterTts,
                  wordIdx: int.parse(receivedNotification.payload!["wordIdx"]!),
                  langIndex:
                      int.parse(receivedNotification.payload!["langIndex"]!),
                ),
              ),
            );
          } else {
            return Future.value();
          }
        } else if (receivedNotification.channelKey ==
                Keys.lastCheckedVerseChannelKey ||
            receivedNotification.channelKey == Keys.completedVerseChannelKey) {
          if (receivedNotification.payload!["type"] == "verse") {
            ChaptersModel chapter = ChaptersModel.fromJson(
                jsonDecode(receivedNotification.payload!["chapter"]!));
            log(chapter.toString());
            VersesModel verse = VersesModel.fromJson(
                jsonDecode(receivedNotification.payload!["verseDetails"]!));
            return Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => VerseDetailsScreen(
                  chapter: chapter,
                  isCompleted:
                      (receivedNotification.payload!["isCompleted"] == "0")
                          ? false
                          : true,
                  flutterTts: flutterTts,
                  wordIdx: int.parse(receivedNotification.payload!["wordIdx"]!),
                  chapterNumber: chapter.chapterNumber,
                  verseDetails: verse,
                  isCompletedChapter:
                      (receivedNotification.payload!["isCompletedChapter"] ==
                              "0")
                          ? false
                          : true,
                ),
              ),
            );
          } else {
            return Future.value();
          }
        } else if (receivedNotification.channelKey ==
            Keys.mediaNotificationChapterChannelKey) {
          log("media");
          return Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => VersesScreen(
                chapter: ChaptersModel.fromJson(
                    jsonDecode(receivedNotification.payload!["chapter"]!)),
                isCompleted:
                    (receivedNotification.payload!["isCompleted"] == "0")
                        ? false
                        : true,
                flutterTts: flutterTts,
                wordIdx: int.parse(receivedNotification.payload!["wordIdx"]!),
                langIndex:
                    int.parse(receivedNotification.payload!["langIndex"]!),
              ),
            ),
          );
        } else {
          return Future.value();
        }
      }),
    );

    super.initState();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _scrollController1.dispose();
    _scrollController2.dispose();
    completedChapters.clear();
    completedVerses.clear();
    flutterTts.stop();
    _tabBarController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.of(context).platformBrightness;

    // log(completedChapters.length.toString());
    if (selectedOption == "Light") {
      AppColors.applyBrightness(Brightness.light);
    } else if (selectedOption == "Dark") {
      AppColors.applyBrightness(Brightness.dark);
    } else {
      AppColors.applyBrightness(MediaQuery.platformBrightnessOf(context));
    }
    return WillPopScope(
      onWillPop: (() async {
        if (_tabBarController.index == 0) {
          await InterstitialAd.load(
            adUnitId: "ca-app-pub-7050103229809241/6903881395",
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: ((ad) {
                _interstitialAd = ad;
                isInterstitialAdLoaded = true;
                setState(() {});
              }),
              onAdFailedToLoad: ((ad) {
                _interstitialAd?.dispose();
                isInterstitialAdLoaded = false;
                setState(() {});
              }),
            ),
          );
          await _interstitialAd!.show();
          return true;
        } else {
          _tabBarController.animateTo(0);
          return false;
        }
      }),
      child: Consumer<ThemeProvider>(
        builder: (ctx, provider, child) {
          if (provider.isChanged) {
            if (provider.theme == "Light") {
              AppColors.applyBrightness(Brightness.light);
            } else if (provider.theme == "Dark") {
              AppColors.applyBrightness(Brightness.dark);
            } else {
              AppColors.applyBrightness(
                  MediaQuery.platformBrightnessOf(context));
            }
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.mainColor,
            drawer: const AppDrawer(),
            appBar: AppBar(
              backgroundColor: AppColors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: AppColors.textColor,
                ),
                onPressed: (() {
                  _openDrawer();
                  // setBrightness(brightness);
                }),
              ),
              actions: [
                if (userLoginModel != null)
                  Center(
                    child: (!isProfileLoading)
                        ? GestureDetector(
                            onLongPress: (() async {
                              HapticFeedback.selectionClick();

                              isProfileLoading = true;
                              setState(() {});
                              await completionRate().then((value) {
                                _buildShowModalBottomSheet(context, value);
                                isProfileLoading = false;
                                setState(() {});
                              });
                            }),
                            onTap: (() async {
                              HapticFeedback.selectionClick();

                              isProfileLoading = true;
                              setState(() {});
                              await completionRate().then((value) {
                                _buildShowModalBottomSheet(context, value);
                                isProfileLoading = false;
                                setState(() {});
                              });
                            }),
                            child: CircleAvatar(
                              backgroundColor: AppColors.transparent,
                              backgroundImage: NetworkImage(
                                userLoginModel!.data.usrProfilePic,
                              ),
                            ),
                          )
                        : const CircularProgressIndicator(
                            color: AppColors.green,
                            strokeWidth: 1.5,
                          ),
                  ),
                const SizedBox(
                  width: 15,
                ),
              ],
              centerTitle: true,
              title: (_tabBarController.index == 0)
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.mainColor.withOpacity(0.3),
                            AppColors.mainColor.withOpacity(0.5),
                            AppColors.mainColor.withOpacity(0.7),
                            AppColors.mainColor,
                          ],
                        ),
                      ),
                      child: SizedBox(
                        width: 55,
                        height: 55,
                        child: Image.asset(
                          "assets/logo_no_bg.png",
                          scale: 2,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.mainColor.withOpacity(0.3),
                            AppColors.mainColor.withOpacity(0.5),
                            AppColors.mainColor.withOpacity(0.7),
                            AppColors.mainColor,
                          ],
                        ),
                      ),
                      child: Text(
                        "Chapters",
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              // flexibleSpace: Container(
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.bottomCenter,
              //       end: Alignment.topCenter,
              //       colors: [
              //         AppColors.transparent,
              //         AppColors.mainColor,
              //       ],
              //     ),
              //   ),
              // ),
            ),
            bottomNavigationBar: Consumer<TTSProvider>(
              builder: (ctx, ttsProvider, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(
                    top: 15,
                    left: 10,
                    right: 10,
                    bottom: 10,
                  ),
                  width: MediaQuery.of(ctx).size.width,
                  height: (Provider.of<TTSProvider>(context, listen: false)
                          .isPlaying)
                      ? (isBannerAdLoaded == false)
                          ? 200
                          : (215 + _bannerAd!.size.height.toDouble())
                      : (isBannerAdLoaded == false)
                          ? 60
                          : (65 + _bannerAd!.size.height.toDouble()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.decelerate,
                        margin:
                            EdgeInsets.only(bottom: isBannerAdLoaded ? 15 : 0),
                        width: MediaQuery.of(context).size.width,
                        height: isBannerAdLoaded
                            ? _bannerAd!.size.height.toDouble()
                            : 0,
                        child: AdWidget(ad: _bannerAd!),
                      ),
                      Visibility(
                        visible:
                            (Provider.of<TTSProvider>(context, listen: false)
                                .isPlaying),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: (() async {
                                if (ttsProvider.chapterSummaryLang !=
                                    "english") {
                                  isLangChanging = true;
                                  setState(() {});
                                  ttsProvider.resetLyricsWordsEnglish();
                                  ttsProvider.wordIndexReset();
                                  ttsProvider.resetChapterName();
                                  ttsProvider.setChapterSummaryLang("english");
                                  ChaptersModel chapter =
                                      ChaptersModel.fromJson(
                                    await JsonStorage.getCurrentChapter(
                                      ttsProvider.chapterID,
                                    ),
                                  );

                                  flutterTts.stop();
                                  ttsProvider.resetChapterID();

                                  ttsProvider.setChapterName(
                                      chapter.nameTranslated.trim());
                                  ttsProvider.setChapterID(chapter.id);
                                  bool completed =
                                      await JsonStorage.isChapterCompleted(
                                          ttsProvider.chapterID);
                                  ttsProvider.setCompleteStatus(completed);
                                  // changeDefaultColor();
                                  ttsProvider.playingStatusUpdate(true);
                                  // ttsProvider.setLyricsCompleteStatus(true);
                                  // log(ttsProvider.chapterName);

                                  ttsProvider.setChapterSummary(
                                      chapter.chapterSummary.trim());

                                  ttsProvider.setLyricsWordsEnglish(
                                    chapter.chapterSummary
                                        .trim()
                                        .replaceAll("\n", " ")
                                        .split(" "),
                                  );
                                  _itemScrollController.jumpTo(index: 0);
                                  await flutterTts.setLanguage("en-IN");
                                  await AwesomeNotifications()
                                      .createNotification(
                                    content: NotificationContent(
                                      id: 0,
                                      channelKey: Keys
                                          .mediaNotificationChapterChannelKey,
                                      title: chapter.nameTranslated,
                                      body:
                                          "Now playing chapter ${chapter.chapterNumber}",
                                      notificationLayout:
                                          NotificationLayout.Default,
                                      roundedBigPicture: true,
                                      actionType: ActionType.KeepOnTop,
                                      autoDismissible: false,
                                      locked: true,
                                      category: NotificationCategory.Event,
                                    ),
                                  );

                                  await flutterTts
                                      .speak(chapter.chapterSummary.trim());

                                  isLangChanging = false;
                                  setState(() {});
                                }
                              }),
                              child: Text(
                                "ENGLISH",
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(
                                      (ttsProvider.chapterSummaryLang ==
                                              "english")
                                          ? 0.6
                                          : 0.2),
                                ),
                              ),
                            ),
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textColor.withOpacity(0.7),
                              ),
                            ),
                            GestureDetector(
                              onTap: (() async {
                                if (ttsProvider.chapterSummaryLang != "hindi") {
                                  isLangChanging = true;
                                  setState(() {});
                                  ttsProvider.resetLyricsWordsEnglish();
                                  ttsProvider.wordIndexReset();
                                  ttsProvider.resetChapterName();
                                  ttsProvider.setChapterSummaryLang("hindi");
                                  ChaptersModel chapter =
                                      ChaptersModel.fromJson(
                                    await JsonStorage.getCurrentChapter(
                                      ttsProvider.chapterID,
                                    ),
                                  );

                                  flutterTts.stop();
                                  ttsProvider.resetChapterID();
                                  // ttsProvider.resetLyricsWords();
                                  // ttsProvider.resetChapterID();
                                  // ttsProvider.resetChapterName();
                                  // ttsProvider.resetLyricsWords();
                                  // ttsProvider
                                  //     .setCompleteStatus(!widget.isCompleted);

                                  ttsProvider
                                      .setChapterName(chapter.name.trim());
                                  ttsProvider.setChapterID(chapter.id);
                                  bool completed =
                                      await JsonStorage.isChapterCompleted(
                                          ttsProvider.chapterID);
                                  ttsProvider.setCompleteStatus(completed);
                                  // changeDefaultColor();
                                  ttsProvider.playingStatusUpdate(true);
                                  // ttsProvider.setLyricsCompleteStatus(true);
                                  // log(ttsProvider.chapterName);

                                  ttsProvider.setChapterSummary(
                                      chapter.chapterSummaryHindi.trim());

                                  ttsProvider.setLyricsWordsEnglish(
                                    chapter.chapterSummaryHindi
                                        .trim()
                                        .replaceAll("\n", " ")
                                        .split(" "),
                                  );
                                  _itemScrollController.jumpTo(index: 0);
                                  await flutterTts.setLanguage("hi-IN");
                                  await AwesomeNotifications()
                                      .createNotification(
                                    content: NotificationContent(
                                      id: 0,
                                      channelKey: Keys
                                          .mediaNotificationChapterChannelKey,
                                      title: chapter.name,
                                      body:
                                          "Now playing chapter ${chapter.chapterNumber}",
                                      notificationLayout:
                                          NotificationLayout.Default,
                                      roundedBigPicture: true,
                                      actionType: ActionType.KeepOnTop,
                                      autoDismissible: false,
                                      locked: true,
                                      category: NotificationCategory.Event,
                                    ),
                                  );
                                  await flutterTts.speak(
                                      chapter.chapterSummaryHindi.trim());
                                  isLangChanging = false;
                                  setState(() {});
                                }
                              }),
                              child: Text(
                                "HINDI",
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(
                                      (ttsProvider.chapterSummaryLang ==
                                              "hindi")
                                          ? 0.6
                                          : 0.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible:
                            (Provider.of<TTSProvider>(context, listen: false)
                                .isPlaying),
                        child: const SizedBox(
                          height: 12,
                        ),
                      ),
                      Visibility(
                        visible:
                            (Provider.of<TTSProvider>(context, listen: false)
                                .isPlaying),
                        child: Container(
                          width: MediaQuery.of(ctx).size.width,
                          height: 100,
                          padding: const EdgeInsets.only(
                            left: 10,
                            top: 10,
                            bottom: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(15),
                            gradient: AppColors.gradient,
                            boxShadow:
                                // currentIndex == 1 ? null :
                                AppColors.shadow,
                          ),
                          child: OpenContainer(
                            transitionDuration: const Duration(
                              milliseconds: 600,
                            ),
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: AppColors.transparent,
                            openColor: AppColors.transparent,
                            middleColor: AppColors.transparent,
                            closedShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            openBuilder: ((versesCtx, _) {
                              chapterDetailsFunc(ttsProvider);

                              return VersesScreen(
                                chapter: chapter!,
                                isCompleted: !isCompletedChapter!,
                                flutterTts: flutterTts,
                                wordIdx: ttsProvider.wordIndex,
                                langIndex:
                                    ttsProvider.chapterSummaryLang == "english"
                                        ? 0
                                        : 1,
                              );
                            }),
                            closedBuilder: ((versesCtx, openFunc) {
                              return GestureDetector(
                                onHorizontalDragEnd: (details) async {
                                  if (details.velocity.pixelsPerSecond.dx > 0) {
                                    prevLyrics(ttsProvider);
                                  } else if (details
                                          .velocity.pixelsPerSecond.dx <
                                      0) {
                                    nextLyrics(ttsProvider);
                                  }

                                  _itemScrollController.jumpTo(index: 0);
                                  setState(() {});
                                },
                                onTap: openFunc,
                                child: Row(
                                  children: [
                                    if (ttsProvider.wordIndex != -1)
                                      IdContainer(
                                        isCompleted: ttsProvider.isCompleted,
                                        id: ttsProvider.chapterID.toString(),
                                      ),
                                    if (ttsProvider.wordIndex == -1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 2),
                                        child: Stack(
                                          children: [
                                            CircularProgressIndicator(
                                              color: AppColors.textColor,
                                              strokeWidth: 2,
                                            ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              top: 0,
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    ttsProvider.chapterID
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // if (isMarqueeNeeded(
                                          //     ttsProvider.chapterName.trim(),
                                          //     MediaQuery.of(versesCtx)
                                          //             .size
                                          //             .width -
                                          //         105))
                                          if (ttsProvider.chapterName
                                                  .trim()
                                                  .split(RegExp(r'\s+'))
                                                  .length >=
                                              3)
                                            SizedBox(
                                              height: 20,
                                              width: MediaQuery.of(ctx)
                                                      .size
                                                      .width -
                                                  105,
                                              child: Marquee(
                                                text: ttsProvider.chapterName
                                                    .trim(),
                                                style: TextStyle(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  letterSpacing: 1.3,
                                                ),
                                                velocity: 50,
                                                blankSpace: 40,
                                                // startPadding: 200,
                                              ),
                                            ),
                                          if (ttsProvider.chapterName
                                                  .trim()
                                                  .split(RegExp(r'\s+'))
                                                  .length <
                                              3)
                                            Text(
                                              ttsProvider.chapterName.trim(),
                                              style: TextStyle(
                                                color: AppColors.textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                letterSpacing: 1.3,
                                              ),
                                            ),
                                          const SizedBox(
                                            height: 7,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 25,
                                            child: ScrollablePositionedList
                                                .builder(
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemScrollController:
                                                  _itemScrollController,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: ttsProvider
                                                  .lyricsWordsEnglish.length,
                                              itemBuilder:
                                                  (wordsCtx, wordsIndex) {
                                                if (wordsIndex ==
                                                        ttsProvider.wordIndex ||
                                                    wordsIndex ==
                                                        ttsProvider.wordIndex -
                                                            1 ||
                                                    wordsIndex ==
                                                        ttsProvider.wordIndex -
                                                            2) {
                                                  Future.delayed(
                                                    Duration.zero,
                                                    (() {
                                                      _itemScrollController
                                                          .scrollTo(
                                                        index: ttsProvider
                                                            .wordIndex,
                                                        alignment: 0,
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 600,
                                                        ),
                                                      );
                                                    }),
                                                  );
                                                }
                                                TextStyle textStyle =
                                                    wordsIndex <=
                                                            ttsProvider
                                                                .wordIndex
                                                        ? GoogleFonts
                                                            .merriweather(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? AppColors
                                                                    .white
                                                                : AppColors
                                                                    .green,
                                                            height: 1.5,
                                                          )
                                                        : TextStyle(
                                                            color: brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? Colors.black
                                                                : AppColors
                                                                    .white,
                                                            height: 1.5,
                                                          );

                                                return AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  child: Text(
                                                    (ttsProvider.chapterSummaryLang ==
                                                            "english")
                                                        ? " ${ttsProvider.lyricsWordsEnglish[wordsIndex].trim()} "
                                                        : " ${ttsProvider.lyricsWordsEnglish[wordsIndex].trim()} ",
                                                    style: textStyle,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    if (ttsProvider.chapterID != 1)
                                      LyricsControlBtn(
                                        icon: (provider.theme == "Dark" ||
                                                provider.theme == "System")
                                            ? CupertinoIcons.backward_end_fill
                                            : CupertinoIcons.backward_end,
                                        iconColor: AppColors.textColor,
                                        onTap: (() async {
                                          prevLyrics(ttsProvider);
                                        }),
                                      ),
                                    LyricsControlBtn(
                                      icon: (provider.theme == "Dark" ||
                                              provider.theme == "System")
                                          ? Icons.stop_rounded
                                          : CupertinoIcons.stop,
                                      iconColor: ttsProvider.isPlaying
                                          ? AppColors.red
                                          : AppColors.textColor,
                                      onTap: (() async {
                                        stopPlayingChapter(ttsProvider);
                                      }),
                                    ),
                                    if (ttsProvider.chapterID != 18 || hasNext)
                                      if (ttsProvider.chapterID != 18 ||
                                          hasNext)
                                        LyricsControlBtn(
                                          icon: (provider.theme == "Dark" ||
                                                  provider.theme == "System")
                                              ? CupertinoIcons.forward_end_fill
                                              : CupertinoIcons.forward_end,
                                          iconColor: AppColors.textColor,
                                          onTap: (() async {
                                            nextLyrics(ttsProvider);
                                            _itemScrollController.jumpTo(
                                                index: 0);
                                          }),
                                        ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            (Provider.of<TTSProvider>(context, listen: false)
                                .isPlaying),
                        child: const SizedBox(
                          height: 15,
                        ),
                      ),
                      GNav(
                        selectedIndex: _tabBarController.index,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        gap: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: AppColors.textColor.withOpacity(0.7),
                        tabBackgroundColor: AppColors.green.withOpacity(0.8),
                        activeColor: AppColors.textColor,
                        tabBorder: Border.all(
                          color: AppColors.textColor,
                        ),
                        tabActiveBorder: Border.all(width: 0),
                        onTabChange: ((index) {
                          _tabBarController.animateTo(
                            index,
                            duration: const Duration(milliseconds: 700),
                          );
                        }),
                        tabs: [
                          GButton(
                            icon: (currentIndex == 0)
                                ? Icons.home_filled
                                : Icons.home_outlined,
                            iconColor: (currentIndex == 0)
                                ? AppColors.textColor
                                : AppColors.textColor.withOpacity(0.7),
                            text: "Home",
                          ),
                          GButton(
                            icon: (currentIndex == 0)
                                ? CupertinoIcons.book_fill
                                : CupertinoIcons.book,
                            iconColor: (currentIndex == 0)
                                ? AppColors.textColor
                                : AppColors.textColor.withOpacity(0.7),
                            text: "Chapters",
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            floatingActionButton: GestureDetector(
              onTap: (() async {
                // await LaunchApp.openApp(
                //     androidPackageName: "com.achivie.achivie");
                // await launchUrlString("com.achivie.achivie");
                // await AppLauncher.openApp(
                //   androidApplicationId: "com.google.android.apps.maps",
                // );
                const package = "com.achivie.achivie";
                try {
                  await AppCheck.checkAvailability(package).then((app) async {
                    await AppCheck.launchApp(package);
                  });
                } catch (e) {
                  await canLaunchUrl(
                    Uri.parse(
                        "https://play.google.com/store/apps/details?id=com.achivie.achivie"),
                  )
                      ? launchUrl(
                          Uri.parse(
                              "https://play.google.com/store/apps/details?id=com.achivie.achivie"),
                        )
                      : log("Error $e");
                }

                //
                // await AppCheck.isAppEnabled(package).then(
                //   (enabled) async => enabled
                //       ? log('$package enabled')
                //       : await canLaunchUrl(
                //           Uri.parse(
                //               "https://play.google.com/store/apps/details?id=com.achivie.achivie"),
                //         )
                //           ? launchUrl(
                //               Uri.parse(
                //                   "https://play.google.com/store/apps/details?id=com.achivie.achivie"),
                //             )
                //           : log("Error"),
                // );
                //

                // const url =
                //     'achivie://screen/newTask'; // Replace with your custom deep link
                // try {
                //   if (await canLaunchUrl(Uri.parse(url))) {
                //     await launchUrl(Uri.parse(url));
                //   } else {
                //     // Handle if the Achivie app is not installed or deep linking is not supported
                //     throw 'Could not launch $url';
                //   }
                // } catch (e) {
                //   // Handle any exceptions that occur during the launching process
                //   print('Error launching URL: $e');
                // }
              }),
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width / 3,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  // gradient: AppColors.gradient,
                  // boxShadow: AppColors.shadow,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    "Add Task",
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                controller: _tabBarController,
                physics: AppColors.scrollPhysics,
                children: [
                  HomeScreen(
                    flutterTts: flutterTts,
                    wordIdx: currentWordIndex,
                    scrollController: _scrollController1,
                  ),
                  ChapterScreen(
                    flutterTts: flutterTts,
                    wordIdx: currentWordIndex,
                    scrollController: _scrollController2,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<dynamic> _buildShowModalBottomSheet(
    BuildContext context,
    int usrCompletionRate,
  ) async {
    List<int> completedChapters = [];
    List<int> completedVerses = [];
    BannerAd? bannerAd1;
    AdSize adSize1 = AdSize.largeBanner;

    bannerAd1 = BannerAd(
      size: adSize1,
      adUnitId: "ca-app-pub-7050103229809241/6243166728",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        setState(() {});
        bannerAd1?.dispose();
      })),
      request: const AdRequest(),
    );

    completedChapters = await JsonStorage.getCompletedChapters();
    completedVerses = await JsonStorage.getCompletedVerses();

    int countElementsWithoutNegativeOne(List<int> numbers) {
      // Check if the array contains -1
      bool containsNegativeOne = numbers.contains(-1);

      if (containsNegativeOne) {
        // Filter out the -1 values and count the remaining elements
        int countWithoutNegativeOne =
            numbers.where((element) => element != -1).length;
        return countWithoutNegativeOne;
      } else {
        // If the array doesn't contain -1, count all elements
        return numbers.length;
      }
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.mainColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      builder: (modalCtx) {
        bannerAd1?.load();
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 25,
                ),
                child: Text(
                  "Achivie Profile",
                  style: TextStyle(
                    color: AppColors.verseCountColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                ),
                margin: const EdgeInsets.only(
                  right: 10,
                  left: 10,
                  top: 10,
                ),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.textColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (userLoginModel!.data.usrProfilePic.isNotEmpty)
                      Column(
                        children: [
                          CircleAvatar(
                            foregroundImage: NetworkImage(
                              userLoginModel!.data.usrProfilePic,
                            ),
                            backgroundColor: AppColors.mainColor,
                            radius: 50,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          if (usrCompletionRate <= 25)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.red,
                                    AppColors.orange,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Silver",
                                  style: TextStyle(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          if (usrCompletionRate > 25 && usrCompletionRate <= 50)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.goldDark,
                                    AppColors.gold,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Gold",
                                  style: TextStyle(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          if (usrCompletionRate > 50 &&
                              usrCompletionRate <= 100)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.diamondDark,
                                    AppColors.diamond,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Diamond",
                                  style: TextStyle(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (userLoginModel!.data.usrProfilePic.isEmpty)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.mainColor,
                        ),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${userLoginModel!.data.usrFirstName} ${userLoginModel!.data.usrLastName}",
                          style: const TextStyle(
                            color: AppColors.blackLow,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          userLoginModel!.data.usrDescription,
                          style: TextStyle(
                            overflow: TextOverflow.clip,
                            color: AppColors.blackLow.withOpacity(0.45),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            if (userLoginModel!.data.usrEmail.length >
                                (MediaQuery.of(context).size.height / 25)
                                    .round())
                              const Icon(
                                Icons.email,
                                color: AppColors.grey,
                                size: 20,
                              ),
                            if (userLoginModel!.data.usrEmail.length >
                                (MediaQuery.of(context).size.height / 25)
                                    .round())
                              const SizedBox(
                                width: 5,
                              ),
                            SizedBox(
                              width: (userLoginModel!.data.usrEmail.length >
                                      (MediaQuery.of(context).size.height / 20)
                                          .round())
                                  ? MediaQuery.of(context).size.width / 2.5
                                  : null,
                              child: Text(
                                userLoginModel!.data.usrEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  overflow: TextOverflow.clip,
                                  color: AppColors.blackLow.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          userLoginModel!.data.usrProfession,
                          style: const TextStyle(
                            overflow: TextOverflow.clip,
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              "Completion rate: ",
                              style: TextStyle(
                                color: AppColors.blackLow.withOpacity(0.6),
                              ),
                            ),
                            if (usrCompletionRate <= 25)
                              Text(
                                "${usrCompletionRate.toString()}%",
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (usrCompletionRate > 25 &&
                                usrCompletionRate <= 50)
                              Text(
                                "${usrCompletionRate.toString()}%",
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (usrCompletionRate > 50 &&
                                usrCompletionRate <= 100)
                              Text(
                                "${usrCompletionRate.toString()}%",
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: AssetImage(
                                "assets/logo-first-splash.png",
                              ),
                            ),
                            SizedBox(
                              width: 7,
                            ),
                            Center(
                              child: Text(
                                "achivie.com",
                                style: TextStyle(
                                  color: AppColors.blackLow,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Text(
                  "Gita Progress",
                  style: TextStyle(
                    color: AppColors.verseCountColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10,
                ),
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                  left: 15,
                  right: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.textColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Completed Chapters: ",
                          style: TextStyle(
                            color: AppColors.blackLow,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          countElementsWithoutNegativeOne(completedChapters)
                              .toString(),
                          style: TextStyle(
                            color: countElementsWithoutNegativeOne(
                                        completedChapters) <=
                                    6
                                ? AppColors.red
                                : (countElementsWithoutNegativeOne(
                                                completedChapters) >
                                            6 &&
                                        countElementsWithoutNegativeOne(
                                                completedChapters) <=
                                            12)
                                    ? AppColors.gold
                                    : AppColors.diamond,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Completed Verses: ",
                          style: TextStyle(
                            color: AppColors.blackLow,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          countElementsWithoutNegativeOne(completedVerses)
                              .toString(),
                          style: TextStyle(
                            color: countElementsWithoutNegativeOne(
                                        completedVerses) <=
                                    233
                                ? AppColors.red
                                : (countElementsWithoutNegativeOne(
                                                completedVerses) >
                                            233 &&
                                        countElementsWithoutNegativeOne(
                                                completedVerses) <=
                                            466)
                                    ? AppColors.gold
                                    : AppColors.diamond,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 10,
                  bottom: 10,
                ),
                child: Text(
                  "Advertisement",
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (bannerAd1 != null)
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  height: adSize1.height.toDouble(),
                  width: MediaQuery.of(context).size.width,
                  child: AdWidget(
                    ad: bannerAd1,
                  ),
                ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}

class LyricsControlBtn extends StatelessWidget {
  const LyricsControlBtn({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        // padding: const EdgeInsets.all(10),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.mainColorLight,
          borderRadius: BorderRadius.circular(15),
          boxShadow: AppColors.shadow,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.mainColor.withOpacity(0.3),
              AppColors.mainColor.withOpacity(0.5),
              AppColors.mainColor.withOpacity(0.7),
              AppColors.mainColor,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class IdContainer extends StatelessWidget {
  const IdContainer({
    super.key,
    required this.isCompleted,
    required this.id,
  });

  final bool isCompleted;
  final String id;

  @override
  Widget build(BuildContext context) {
    // log("completed : ${isCompleted.toString()}");

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textColor,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            id,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavBarChild extends StatelessWidget {
  const BottomNavBarChild({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.textStyle,
    required this.iconSize,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color iconColor;
  final TextStyle textStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            label,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
