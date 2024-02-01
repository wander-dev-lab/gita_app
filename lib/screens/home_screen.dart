import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:animated_list_item/animated_list_item.dart';
import 'package:animations/animations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gita_app/models/verses_model.dart';
import 'package:gita_app/screens/verse_details_screen.dart';
import 'package:gita_app/screens/verse_image_edit_screen.dart';
import 'package:gita_app/screens/verses_screen.dart';
import 'package:gita_app/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/chapter_share_model.dart';
import '../models/chapters_model.dart';
import '../models/notification_store_model.dart';
import '../models/shared_lines_model.dart';
import '../models/verse_translation_model.dart';
import '../providers/app_providers.dart';
import '../services/keys.dart';
import '../services/storage_service.dart';
import 'lines_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
    required this.flutterTts,
    required this.wordIdx,
    required this.scrollController,
  }) : super(key: key);

  final FlutterTts flutterTts;
  final int wordIdx;
  final ScrollController scrollController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isLoading = false,
      isFlipped = false,
      isBannerAdLoaded1 = false,
      isBannerAdLoaded2 = false,
      isBannerAdLoaded3 = false,
      isBannerAdLoaded4 = false,
      isBannerAdLoaded5 = false,
      isLoadingTranslation = false;
  List<ChaptersModel> chapters = [];
  List<VersesModel> verses = [];
  List<int> completedChapters = [];
  List<int> completedVerses = [];
  String selectedOption = '';
  int? lastDeletedChapterID;
  late AnimationController _animationController;
  BannerAd? _bannerAd1, _bannerAd2, _bannerAd3, _bannerAd4, _bannerAd5;
  AdSize adSize = AdSize.banner;
  math.Random random = math.Random();
  int randomChapter = math.Random().nextInt(18) + 1;
  int? randomVerse;
  ChaptersModel? chapter,
      lastCompletedChapter,
      lastPlayedChapter,
      lastCheckedChapter;
  VersesModel? verse;
  final gt = GoogleTranslator();
  String? translatedVerseHindi, translatedVerseEnglish;
  // final ScrollController _scrollController = ScrollController();
  // bool isAtTop = false;
  // bool isAtBottom = false;

  Future<void> fetchVerses(ChaptersModel currentChapter, int verseID) async {
    isLoading = true;
    setState(() {});
    // String hindiTranslation, englishTranslation;
    verses = await JsonStorage.getVersesOfChapter(currentChapter.slug);

    if (verses.isEmpty) {
      http.Response response = await http.get(
        Uri.parse(
          "${Keys.apiBaseChaptersUrl}/${currentChapter.chapterNumber}/verses/",
        ),
        headers: {
          Keys.rapidAPIKey: Keys.rapidAPIKeyVal,
          Keys.rapidAPIHost: Keys.rapidAPIHostVal,
          "content-type": "application/json",
          "X-RateLimit-rapid-free-plans-hard-limit-Limit": "500000",
          "X-RateLimit-rapid-free-plans-hard-limit-Remaining": "499991",
          "X-RateLimit-rapid-free-plans-hard-limit-Reset": "552766",
          "Server": "RapidAPI-1.2.8",
          "X-RapidAPI-Version": "1.2.8",
          "X-RapidAPI-Region": "AWS - us-east-1",
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes))
                .cast<Map<String, dynamic>>();
        verses = versesModelFromJson(json.encode(jsonList));
        await JsonStorage.saveVersesOfChapter(verses, currentChapter.slug);

        // for (var verse in verses) {
        //   hindiTranslation = await translateToEn(verse.text, "hi");
        //   englishTranslation = await translateToEn(verse.text, "en");
        //   await JsonStorage.saveVerseTranslation(
        //     verse.slug,
        //     VerseTranslationModel(
        //       verseHindi: hindiTranslation,
        //       verseEnglish: englishTranslation,
        //     ),
        //   );
        //   log(englishTranslation);
        // }
        log(response.statusCode.toString());
      }
    }

    verse = verses[verseID];

    isLoading = false;
    setState(() {});
  }

  Future<void> fetchCompletedVerses() async {
    completedVerses = await JsonStorage.getCompletedVerses();
    setState(() {});
  }

  void _addCompleteStatus(int chapterID) async {
    await JsonStorage.addCompletedChapter(chapterID);
    ChaptersModel chapter =
        ChaptersModel.fromJson(await JsonStorage.getNextChapter(chapterID));
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedChapterNotification();
    bool isCompletedChapter = await JsonStorage.isChapterCompleted(chapter.id);

    int notificationID = (notificationStoreModel != null)
        ? notificationStoreModel.notificationId
        : await JsonStorage.getNotificationID() ?? 0;

    DateTime notificationTime =
        await JsonStorage.addAndGetNotificationTimeLastCompletedChapter();
    NotificationCalendar notificationCalendar = NotificationCalendar(
      year: notificationTime.year,
      month: notificationTime.month,
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      second: 0,
      millisecond: 0,
      repeats: true,
    );

    await AwesomeNotifications().cancelSchedule(notificationID);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: notificationID,
          channelKey: Keys.completedChapterChannelKey,
          notificationLayout: NotificationLayout.BigText,
          title: "Gita Chapter Update",
          body:
              "You last completed the chapter ${chapter.chapterNumber}.\nLet's continue your growth.",
          payload: {
            "time": notificationTime.toString(),
            "lang": "English",
            "type": "chapter",
            "chapter": jsonEncode(chapter),
            "isCompleted": !isCompletedChapter ? "0" : "1",
            "wordIdx": "0",
            "langIndex": "0",
          }),
      schedule: notificationCalendar,
    );
    completedVerses = await JsonStorage.getCompletedChapters();
    setState(() {});
  }

  void _addCompleteStatusVerse(int verseId) async {
    NotificationStoreModel? notificationStoreModelVerse =
        await JsonStorage.getLastCompletedVerseNotification();

    VersesModel? currentVerse =
        await JsonStorage.getVerseOfChapter(chapter!.slug, verseId);

    DateTime notificationTime =
        await JsonStorage.addAndGetNotificationTimeLastCompletedVerses();
    NotificationCalendar notificationCalendar = NotificationCalendar(
      year: notificationTime.year,
      month: notificationTime.month,
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      second: 0,
      millisecond: 0,
      repeats: true,
    );
    int notificationID = (notificationStoreModelVerse != null)
        ? notificationStoreModelVerse.notificationId
        : await JsonStorage.getNotificationID() ?? 0;

    if (currentVerse != null) {
      await AwesomeNotifications().cancelSchedule(notificationID);
      bool isCompletedVerse =
          await JsonStorage.isVerseCompleted(currentVerse.id);
      bool isCompletedChapter =
          await JsonStorage.isChapterCompleted(chapter!.id);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notificationID,
            channelKey: Keys.completedVerseChannelKey,
            notificationLayout: NotificationLayout.BigText,
            title: "Continue Your Bhagavad Gita Progress",
            body:
                "👏 Completed Verse $verseId! Explore more verses in the Bhagavad Gita 📜🚶‍♂️ to deepen your wisdom journey. 🌟",
            payload: {
              "time": notificationTime.toString(),
              "lang": "English",
              "type": "verse",
              "chapter": jsonEncode(chapter),
              "isCompleted": !isCompletedVerse ? "0" : "1",
              "isCompletedChapter": !isCompletedChapter ? "0" : "1",
              "wordIdx": "0",
              "langIndex": "0",
              "verseDetails": jsonEncode(currentVerse),
            }),
        schedule: notificationCalendar,
      );
      await JsonStorage.setLastCompletedVerse(verseId);
      await JsonStorage.setLastCompletedVerseNotification(
        NotificationStoreModel(
          id: verseId,
          notificationId: notificationID,
        ),
      );
    }

    await JsonStorage.addCompletedVerse(verseId);
    await fetchCompletedVerses();
    setState(() {});
  }

  void _deleteCompleteStatus(int chapterID) async {
    await JsonStorage.deleteCompletedChapter(chapterID);
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedChapterNotification();
    if (notificationStoreModel != null &&
        notificationStoreModel.id == chapterID) {
      await AwesomeNotifications()
          .cancelSchedule(notificationStoreModel.notificationId);
    }
    completedVerses = await JsonStorage.getCompletedChapters();
    setState(() {});
  }

  void _deleteCompleteStatusVerse(int verseID) async {
    await JsonStorage.deleteCompletedVerse(verseID);
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedVerseNotification();
    if (notificationStoreModel != null &&
        notificationStoreModel.id == verseID) {
      await AwesomeNotifications()
          .cancelSchedule(notificationStoreModel.notificationId);
    }
    completedVerses = await JsonStorage.getCompletedVerses();
    setState(() {});
  }

  bool _isValueInList(int value, List<int> integerList) {
    if (integerList.contains(value)) {
      return true; // Value is present in the list
    } else {
      return false; // Value is not present in the list
    }
  }

  bool isTodayTheDayAfter(DateTime storedDate) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return tomorrow.year == storedDate.year &&
        tomorrow.month == storedDate.month &&
        tomorrow.day == storedDate.day;
  }

  Future<bool> checkIfDayAfter(int storedLastUpdatedTimestamp) async {
    final storedDate =
        DateTime.fromMillisecondsSinceEpoch(storedLastUpdatedTimestamp);
    return isTodayTheDayAfter(storedDate);
  }

  void getUserData() async {
    isLoading = true;
    setState(() {});
    await fetchChapters();
    await fetchCompletedChapters();
    await fetchCompletedVerses();
    await fetchLastCheckedChapter();
    await fetchLastCompletedChapter();
    await fetchLastPlayedChapter();
    filterChapters();
    selectedOption = await JsonStorage.getTheme() ?? "Light";
    // log(selectedOption);

    final storedDate = await JsonStorage.getLastUpdatedTimestamp();
    final chapterData = await JsonStorage.getCurrentChapter(randomChapter);

    if (storedDate != null && chapterData.isNotEmpty) {
      if (await checkIfDayAfter(storedDate)) {
        chapter = ChaptersModel.fromJson(
          chapterData,
        );
        randomVerse = random.nextInt(chapter!.versesCount) + 1;
        await JsonStorage.setLastUpdatedTimestamp(
            DateTime.now().millisecondsSinceEpoch);
        await JsonStorage.setTodayChapterID(randomChapter);
        await JsonStorage.setTodayVerseID(randomVerse!);
      }
    } else {
      math.Random random = math.Random();
      randomChapter = random.nextInt(18) + 1;
      chapter = ChaptersModel.fromJson(
        await JsonStorage.getCurrentChapter(randomChapter),
      );
      randomVerse = random.nextInt(chapter!.versesCount) + 1;
      await JsonStorage.setLastUpdatedTimestamp(
          DateTime.now().millisecondsSinceEpoch);
      await JsonStorage.setTodayChapterID(randomChapter);
      await JsonStorage.setTodayVerseID(randomVerse!);
    }

    chapter = ChaptersModel.fromJson(
      await JsonStorage.getCurrentChapter(
          await JsonStorage.getTodayChapterID()),
    );

    fetchVerses(chapter!, await JsonStorage.getTodayVerseID());

    lastCompletedChapter = await fetchLastCompletedChapter();
    setState(() {});

    lastCheckedChapter = await fetchLastCheckedChapter();
    setState(() {});

    lastPlayedChapter = await fetchLastPlayedChapter();
    setState(() {});

    isLoading = false;
    setState(() {});
  }

  Future<void> fetchChapters() async {
    chapters = await JsonStorage.getChapters();
  }

  Future<void> fetchCompletedChapters() async {
    completedChapters = await JsonStorage.getCompletedChapters();
    setState(() {});
  }

  void filterChapters() {
    chapters = chapters.where((chapter) {
      return completedChapters.contains(chapter.id);
    }).toList();
  }

  bool isValueInList(int value, List<int> integerList) {
    if (integerList.contains(value)) {
      return true; // Value is present in the list
    } else {
      return false; // Value is not present in the list
    }
  }

  int calculateNumberOfLines(
      String text, TextStyle textStyle, double screenWidth) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null, // Unlimited lines
    )..layout(maxWidth: screenWidth);

    final numberOfLines =
        (textPainter.size.height / textPainter.preferredLineHeight).ceil();
    return numberOfLines;
  }

  Future<String> translateTo(String text, String to) async =>
      await gt.translate(text, to: to).then((value) => value.text);

  Future<void> translateToEn(String sen, String to, String slug) async {
    // TransliterationResponse? _response =
    //     await Transliteration.transliterate(sen, Languages.ENGLISH);
    // String res = _response!.transliterationSuggestions.toString();
    // log(res);
    translatedVerseHindi = "";
    translatedVerseEnglish = "";
    setState(() {});

    final verseTranslationModel = await JsonStorage.getVerseTranslation(slug);
    if (verseTranslationModel.verseEnglish == "Error" &&
        verseTranslationModel.verseHindi == "Error") {
      try {
        var resEng = await gt.translate(sen, to: "en");
        translatedVerseEnglish = resEng.text;
        var resHind = await gt.translate(sen, to: "hi");
        translatedVerseHindi = resHind.text;

        log("Direct");

        await JsonStorage.saveVerseTranslation(
          slug,
          VerseTranslationModel(
            verseHindi: translatedVerseHindi!,
            verseEnglish: translatedVerseEnglish!,
          ),
        );
      } catch (e) {
        // Handle the exception here, for example, by displaying an error message
        // print("Translation Error: $e");
      }
    } else {
      log("Storage");

      translatedVerseEnglish = verseTranslationModel.verseEnglish;
      translatedVerseHindi = verseTranslationModel.verseHindi;
    }

    setState(() {});
  }

  Future<ChaptersModel?> fetchLastCompletedChapter() async {
    NotificationStoreModel? lastCompletedChapter =
        await JsonStorage.getLastCompletedChapterNotification();
    ChaptersModel? lastCompletedChapterDetails;

    if (lastCompletedChapter != null) {
      Map<String, dynamic> data =
          await JsonStorage.getCurrentChapter(lastCompletedChapter.id);
      if (data.isNotEmpty) {
        lastCompletedChapterDetails = ChaptersModel.fromJson(data);
      }
    }

    return lastCompletedChapterDetails;
  }

  Future<ChaptersModel?> fetchLastCheckedChapter() async {
    NotificationStoreModel? lastCheckedChapter =
        await JsonStorage.getLastCheckedChapterNotification();
    ChaptersModel? lastCheckedChapterDetails;

    if (lastCheckedChapter != null) {
      Map<String, dynamic> data =
          await JsonStorage.getCurrentChapter(lastCheckedChapter.id);
      if (data.isNotEmpty) {
        lastCheckedChapterDetails = ChaptersModel.fromJson(data);
      }
    }

    return lastCheckedChapterDetails;
  }

  Future<ChaptersModel?> fetchLastPlayedChapter() async {
    NotificationStoreModel? lastPlayedChapter =
        await JsonStorage.getLastPlayedChapterNotification();
    ChaptersModel? lastPlayedChapterDetails;

    if (lastPlayedChapter != null) {
      Map<String, dynamic> data =
          await JsonStorage.getCurrentChapter(lastPlayedChapter.id);
      if (data.isNotEmpty) {
        lastPlayedChapterDetails = ChaptersModel.fromJson(data);
      }
    }

    return lastPlayedChapterDetails;
  }

  // void _checkScrollPosition() {
  //   final maxScroll = _scrollController.position.maxScrollExtent;
  //   final currentScroll = _scrollController.position.pixels;
  //
  //   // Check if at the top
  //   if (currentScroll <= 0) {
  //     if (!isAtTop) {
  //       isAtTop = true;
  //       HapticFeedback.vibrate();
  //     }
  //   } else {
  //     isAtTop = false;
  //   }
  //
  //   // Check if at the bottom
  //   if (currentScroll >= maxScroll) {
  //     if (!isAtBottom) {
  //       isAtBottom = true;
  //       HapticFeedback.vibrate();
  //     }
  //   } else {
  //     isAtBottom = false;
  //   }
  // }

  @override
  void initState() {
    getUserData();
    _animationController = AnimationController(
      duration: Duration(
        milliseconds: chapters.isEmpty ? 500 : chapters.length * 500,
      ),
      vsync: this,
    );
    _animationController.forward();

    // _scrollController.addListener(_checkScrollPosition);

    _bannerAd1 = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/5567896801",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded1 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd1?.dispose();
          isBannerAdLoaded1 = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    );
    _bannerAd2 = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/6334468970",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded2 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd2?.dispose();
          isBannerAdLoaded2 = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    );
    _bannerAd3 = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/7499925576",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded3 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd3?.dispose();
          isBannerAdLoaded3 = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    );
    _bannerAd4 = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/2383615672",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded4 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd4?.dispose();
          isBannerAdLoaded4 = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    );
    _bannerAd5 = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/7803177906",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded5 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd5?.dispose();
          isBannerAdLoaded5 = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    );

    _bannerAd1?.load();
    _bannerAd2?.load();
    _bannerAd3?.load();
    _bannerAd4?.load();
    _bannerAd5?.load();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // _scrollController.dispose();
    completedChapters.clear();
    chapters.clear();
    verses.clear();
    completedChapters.clear();
    completedVerses.clear();
    _bannerAd1?.dispose();
    _bannerAd2?.dispose();
    _bannerAd3?.dispose();
    _bannerAd4?.dispose();
    _bannerAd5?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: (() async {
            getUserData();
          }),
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: AppColors.scrollPhysics,
            slivers: [
              //Today chapter
              if (chapter != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      "Chapter of the day",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (chapter != null)
                SliverToBoxAdapter(
                  child: CupertinoContextMenu.builder(
                      actions: [
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.share,
                          onPressed: (() {
                            log(chapter!.chapterSummary);

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (nextCtx) => LinesSelectionScreen(
                                  lines: chapter!.chapterSummary
                                      .replaceAll(RegExp(r'\d+\.\s'), '')
                                      .split(RegExp(r'\.\s')),
                                  chapterName: chapter!.nameTranslated,
                                  chapterID: chapter!.id,
                                ),
                              ),
                            );
                          }),
                          child: const Text(
                            "Share",
                            style: TextStyle(
                              color: AppColors.blackLow,
                            ),
                          ),
                        ),
                        if (!isValueInList(chapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.check_circle_outline,
                            onPressed: (() {
                              Navigator.pop(context);
                              _addCompleteStatus(chapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Complete",
                              style: TextStyle(
                                color: AppColors.blackLow,
                              ),
                            ),
                          ),
                        if (isValueInList(chapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.cancel_outlined,
                            onPressed: (() {
                              Navigator.pop(context);
                              _deleteCompleteStatus(chapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Incomplete",
                              style: TextStyle(
                                color: AppColors.red,
                              ),
                            ),
                          ),
                      ],
                      enableHapticFeedback: true,
                      builder: (BuildContext ctx, Animation<double> animation) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 120,
                          width: MediaQuery.of(context).size.width - 30,
                          margin: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 5,
                            bottom: 10,
                          ),
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                            left: 15,
                            right: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.containerColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppColors.shadow,
                            gradient: AppColors.gradient,
                          ),
                          child: OpenContainer(
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            tappable: false,
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: AppColors.transparent,
                            openColor: AppColors.transparent,
                            openBuilder: ((openCtx, _) {
                              return VersesScreen(
                                langIndex: 0,
                                wordIdx: widget.wordIdx,
                                flutterTts: widget.flutterTts,
                                chapter: chapter!,
                                isCompleted: !isValueInList(
                                    chapter!.id, completedChapters),
                              );
                            }),
                            closedBuilder: ((closedCtx, openContainer) {
                              return GestureDetector(
                                onTap: openContainer,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FlipCard(
                                      onFlip: (() {
                                        if (!isValueInList(
                                            chapter!.id, completedChapters)) {
                                          _addCompleteStatus(chapter!.id);
                                        } else {
                                          _deleteCompleteStatus(chapter!.id);
                                        }
                                      }),
                                      onFlipDone: ((flipped) {
                                        lastDeletedChapterID = chapter!.id;
                                        getUserData();
                                      }),
                                      front: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: AppColors.borderWidth,
                                            color: !isValueInList(chapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              chapter!.chapterNumber.toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      back: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: !isValueInList(chapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              chapter!.chapterNumber.toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                chapter!.nameTranslated,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Number of Verses: ",
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    chapter!.versesCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .verseCountColor,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            chapter!.chapterSummary,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: AppColors.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                ),

              //Today chapter ad1
              if (isBannerAdLoaded1 && chapter != null)
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              if (isBannerAdLoaded1 && chapter != null)
                SliverToBoxAdapter(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: adSize.height.toDouble(),
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AdWidget(
                      ad: _bannerAd1!,
                    ),
                  ),
                ),

              //Today verse
              if (verse != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      "Verse of the day of chapter ${chapter!.id}",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (verse != null)
                SliverToBoxAdapter(
                  child: Consumer<AllAppProviders>(
                    builder: (ctx, allAppProvider, child) {
                      return CupertinoContextMenu.builder(
                          actions: [
                            CupertinoContextMenuAction(
                              trailingIcon: CupertinoIcons.share,
                              onPressed: (() async {
                                // log(chapters[listIdx].chapterSummary);
                                Navigator.pop(context);
                                isLoadingTranslation = true;
                                setState(() {});

                                bool chapterShareDetailsFetched = false,
                                    verseIDTranslationModelFetched = false,
                                    verseTranslationModelFetched = false;
                                String chapterIDHin = "",
                                    chapterIDSan = "",
                                    chapterNameHin = "",
                                    chapterNameSan = "",
                                    verseIDHin = "",
                                    verseIDSan = "";

                                ChapterShareModel? chapterShareModel =
                                    await JsonStorage.getChapterShareDetails(
                                        chapter!.id);
                                if (chapterShareModel != null) {
                                  chapterIDHin = chapterShareModel.chapterIdHin;
                                  chapterIDSan = chapterShareModel.chapterIdSan;
                                  chapterNameHin =
                                      chapterShareModel.chapterNameHin;
                                  chapterNameSan =
                                      chapterShareModel.chapterNameSan;
                                  log("from storage chapterShareModel");
                                  chapterShareDetailsFetched = true;
                                } else {
                                  chapterIDHin = await translateTo(
                                      chapter!.id.toString(), 'hi');
                                  chapterIDSan = await translateTo(
                                      chapter!.id.toString(), 'sa');
                                  chapterNameHin = await translateTo(
                                      chapter!.nameTranslated.toString(), 'hi');
                                  chapterNameSan = await translateTo(
                                      chapter!.nameTranslated.toString(), 'sa');
                                  await JsonStorage.setChapterShareDetails(
                                    ChapterShareModel(
                                      chapterIdHin: chapterIDHin,
                                      chapterIdSan: chapterIDSan,
                                      chapterNameHin: chapterNameHin,
                                      chapterNameSan: chapterNameSan,
                                    ),
                                    chapter!.id,
                                  );
                                  log("from network chapterShareModel");
                                  chapterShareDetailsFetched = true;
                                }

                                TranslationModel? verseIDTranslationModel =
                                    await JsonStorage.getVerseIDTranslation(
                                        verse!.id);

                                if (verseIDTranslationModel != null) {
                                  verseIDHin = verseIDTranslationModel.hin;
                                  verseIDSan = verseIDTranslationModel.san;
                                  log("verseIDTranslationModel from storage");
                                  verseIDTranslationModelFetched = true;
                                } else {
                                  verseIDHin = await gt
                                      .translate(verse!.id.toString(), to: "hi")
                                      .then(
                                        (value) => value.text,
                                      );

                                  verseIDSan = await gt
                                      .translate(verse!.id.toString(), to: "sa")
                                      .then(
                                        (value) => value.text,
                                      );

                                  await JsonStorage.setVerseIDTranslation(
                                    TranslationModel(
                                      eng: verse!.id.toString(),
                                      san: verseIDSan,
                                      hin: verseIDHin,
                                    ),
                                    verse!.id,
                                  );

                                  log("verseIDTranslationModel from storage");

                                  verseIDTranslationModelFetched = true;
                                }

                                await JsonStorage.getSharedVerseTranslation(
                                        verse!.id)
                                    .then((verseTranslationModelVal) async {
                                  if (verseTranslationModelVal != null) {
                                    verseTranslationModelFetched = true;
                                    log("verseTranslationModel from storage");
                                  } else {
                                    await JsonStorage.setSharedVerseTranslation(
                                      verse!.text,
                                      verse!.id,
                                    );
                                    verseTranslationModelVal = await JsonStorage
                                        .getSharedVerseTranslation(verse!.id);
                                    log("verseTranslationModel from network");
                                    verseTranslationModelFetched = true;
                                  }

                                  if (chapterShareDetailsFetched &&
                                      verseIDTranslationModelFetched &&
                                      verseTranslationModelFetched &&
                                      verseTranslationModelVal != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (nextCtx) =>
                                            VerseImageEditScreen(
                                          verse: verse!.text,
                                          verseEng:
                                              verseTranslationModelVal!.eng,
                                          verseHin:
                                              verseTranslationModelVal.hin,
                                          chapterNameEng:
                                              chapter!.nameTranslated,
                                          chapterIDEng: chapter!.id,
                                          verseIDEng: verse!.id,
                                          chapterIDHin: chapterIDHin,
                                          chapterIDSan: chapterIDSan,
                                          verseIDHin: verseIDHin,
                                          verseIDSan: verseIDSan,
                                          chapterNameSan: chapter!.name,
                                          chapterNameHin: chapterNameHin,
                                          verseStringEng: 'Verse number: ',
                                          verseStringSan: "श्लोक संख्या : ",
                                          verseStringHin: "श्लोक संख्या: ",
                                        ),
                                      ),
                                    );
                                  }
                                });

                                isLoadingTranslation = false;
                                setState(() {});
                              }),
                              child: const Text(
                                "Share",
                                style: TextStyle(
                                  color: AppColors.blackLow,
                                ),
                              ),
                            ),
                            if (!_isValueInList(verse!.id, completedVerses))
                              CupertinoContextMenuAction(
                                trailingIcon: Icons.check_circle_outline,
                                onPressed: (() {
                                  Navigator.pop(context);
                                  _addCompleteStatus(verse!.id);
                                }),
                                child: const Text(
                                  "Complete",
                                  style: TextStyle(
                                    color: AppColors.blackLow,
                                  ),
                                ),
                              ),
                            if (_isValueInList(verse!.id, completedVerses))
                              CupertinoContextMenuAction(
                                trailingIcon: Icons.cancel_outlined,
                                onPressed: (() {
                                  Navigator.pop(context);
                                  _deleteCompleteStatus(verse!.id);
                                }),
                                child: const Text(
                                  "Incomplete",
                                  style: TextStyle(
                                    color: AppColors.red,
                                  ),
                                ),
                              ),
                          ],
                          builder:
                              (BuildContext ctx, Animation<double> animation) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: MediaQuery.of(context).size.width - 30,
                              margin: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 5,
                                bottom: 10,
                              ),
                              padding: const EdgeInsets.only(
                                top: 30,
                                bottom: 30,
                                left: 10,
                                right: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.containerColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: AppColors.shadow,
                                gradient: AppColors.gradient,
                              ),
                              child: OpenContainer(
                                transitionDuration: const Duration(
                                  milliseconds: 400,
                                ),
                                tappable: false,
                                closedElevation: 0,
                                openElevation: 0,
                                closedColor: AppColors.transparent,
                                openColor: AppColors.transparent,
                                closedBuilder: ((closedCtx, openContainer) {
                                  return GestureDetector(
                                    onTap: openContainer,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        FlipCard(
                                          onFlip: (() {
                                            if (!_isValueInList(
                                                verse!.id, completedVerses)) {
                                              _addCompleteStatusVerse(
                                                  verse!.id);
                                            } else {
                                              _deleteCompleteStatusVerse(
                                                  verse!.id);
                                            }
                                          }),
                                          onFlipDone: ((flipped) {
                                            setState(() {});
                                          }),
                                          front: AnimatedContainer(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: AppColors.borderWidth,
                                                color: !_isValueInList(
                                                        verse!.id,
                                                        completedVerses)
                                                    ? Colors.redAccent
                                                    : AppColors.green,
                                              ),
                                            ),
                                            duration: const Duration(
                                                milliseconds: 300),
                                            alignment: Alignment.center,
                                            child: Container(
                                              margin: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: AppColors.green
                                                    .withOpacity(0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  verse!.verseNumber.toString(),
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          back: AnimatedContainer(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: AppColors.borderWidth,
                                                color: !_isValueInList(
                                                        verse!.id,
                                                        completedVerses)
                                                    ? Colors.redAccent
                                                    : AppColors.green,
                                              ),
                                            ),
                                            // !_isValueInList(
                                            //     verses[listIdx].id,
                                            //     completedVerses)
                                            duration: const Duration(
                                                milliseconds: 300),

                                            alignment: Alignment.center,
                                            child: Container(
                                              margin: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: AppColors.green
                                                    .withOpacity(0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  verse!.verseNumber.toString(),
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 15,
                                        ),
                                        Expanded(
                                          child: Text(
                                            verse!.text.replaceAll("\n", " "),
                                            maxLines: calculateNumberOfLines(
                                              verse!.text,
                                              GoogleFonts.poppins(
                                                color: AppColors.textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                              MediaQuery.of(context).size.width,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),

                                        // Column(
                                        //   crossAxisAlignment: CrossAxisAlignment.start,
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.spaceEvenly,
                                        //   children: [
                                        //     SizedBox(
                                        //       width: MediaQuery.of(context).size.width -
                                        //           105,
                                        //       child: Text(
                                        //         verses[listIdx].text,
                                        //         maxLines: 2,
                                        //         overflow: TextOverflow.ellipsis,
                                        //         style: GoogleFonts.poppins(
                                        //           color: AppColors.white,
                                        //           fontWeight: FontWeight.bold,
                                        //           fontSize: 17,
                                        //         ),
                                        //       ),
                                        //     ),
                                        //     // SizedBox(
                                        //     //   width: MediaQuery.of(context).size.width /
                                        //     //       1.5,
                                        //     //   child: Text(
                                        //     //     verses[listIdx].text,
                                        //     //     overflow: TextOverflow.ellipsis,
                                        //     //     maxLines: 2,
                                        //     //     style: TextStyle(
                                        //     //       color:
                                        //     //           AppColors.white.withOpacity(0.7),
                                        //     //     ),
                                        //     //   ),
                                        //     // ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  );
                                }),
                                openBuilder: ((openCtx, _) {
                                  return VerseDetailsScreen(
                                    wordIdx: widget.wordIdx,
                                    flutterTts: widget.flutterTts,
                                    chapter: chapter!,
                                    isCompletedChapter: !isValueInList(
                                        chapter!.id, completedChapters),
                                    chapterNumber: chapter!.chapterNumber,
                                    verseDetails: verse!,
                                    isCompleted: _isValueInList(
                                      verse!.id,
                                      completedVerses,
                                    ),
                                  );
                                }),
                              ),
                            );
                          });
                    },
                  ),
                ),

              //Today verse ad2
              if (isBannerAdLoaded2 && verse != null)
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              if (isBannerAdLoaded2 && verse != null)
                SliverToBoxAdapter(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: adSize.height.toDouble(),
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AdWidget(
                      ad: _bannerAd2!,
                    ),
                  ),
                ),

              //Last Completed Chapter
              if (lastCompletedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      "Recently Completed Chapter",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (lastCompletedChapter != null)
                SliverToBoxAdapter(
                  child: CupertinoContextMenu.builder(
                      actions: [
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.share,
                          onPressed: (() {
                            // log(chapter!.chapterSummary);

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (nextCtx) => LinesSelectionScreen(
                                  lines: lastCompletedChapter!.chapterSummary
                                      .replaceAll(RegExp(r'\d+\.\s'), '')
                                      .split(RegExp(r'\.\s')),
                                  chapterName:
                                      lastCompletedChapter!.nameTranslated,
                                  chapterID: lastCompletedChapter!.id,
                                ),
                              ),
                            );
                          }),
                          child: const Text(
                            "Share",
                            style: TextStyle(
                              color: AppColors.blackLow,
                            ),
                          ),
                        ),
                        if (!isValueInList(
                            lastCompletedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.check_circle_outline,
                            onPressed: (() {
                              Navigator.pop(context);
                              _addCompleteStatus(lastCompletedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Complete",
                              style: TextStyle(
                                color: AppColors.blackLow,
                              ),
                            ),
                          ),
                        if (isValueInList(
                            lastCompletedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.cancel_outlined,
                            onPressed: (() {
                              Navigator.pop(context);
                              _deleteCompleteStatus(lastCompletedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Incomplete",
                              style: TextStyle(
                                color: AppColors.red,
                              ),
                            ),
                          ),
                      ],
                      enableHapticFeedback: true,
                      builder: (BuildContext ctx, Animation<double> animation) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 120,
                          width: MediaQuery.of(context).size.width - 30,
                          margin: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 5,
                            bottom: 10,
                          ),
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                            left: 15,
                            right: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.containerColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppColors.shadow,
                            gradient: AppColors.gradient,
                          ),
                          child: OpenContainer(
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            tappable: false,
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: AppColors.transparent,
                            openColor: AppColors.transparent,
                            openBuilder: ((openCtx, _) {
                              return VersesScreen(
                                langIndex: 0,
                                wordIdx: widget.wordIdx,
                                flutterTts: widget.flutterTts,
                                chapter: lastCompletedChapter!,
                                isCompleted: !isValueInList(
                                    lastCompletedChapter!.id,
                                    completedChapters),
                              );
                            }),
                            closedBuilder: ((closedCtx, openContainer) {
                              return GestureDetector(
                                onTap: openContainer,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FlipCard(
                                      onFlip: (() {
                                        if (!isValueInList(
                                            lastCompletedChapter!.id,
                                            completedChapters)) {
                                          _addCompleteStatus(
                                              lastCompletedChapter!.id);
                                        } else {
                                          _deleteCompleteStatus(
                                              lastCompletedChapter!.id);
                                        }
                                      }),
                                      onFlipDone: ((flipped) {
                                        lastDeletedChapterID =
                                            lastCompletedChapter!.id;
                                        getUserData();
                                      }),
                                      front: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: AppColors.borderWidth,
                                            color: !isValueInList(
                                                    lastCompletedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastCompletedChapter!
                                                  .chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      back: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: !isValueInList(
                                                    lastCompletedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastCompletedChapter!
                                                  .chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                lastCompletedChapter!
                                                    .nameTranslated,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Number of Verses: ",
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lastCompletedChapter!
                                                        .versesCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .verseCountColor,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            lastCompletedChapter!
                                                .chapterSummary,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: AppColors.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                ),

              //Last Completed Chapter ad3
              if (isBannerAdLoaded3 && lastCompletedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              if (isBannerAdLoaded3 && lastCompletedChapter != null)
                SliverToBoxAdapter(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: adSize.height.toDouble(),
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AdWidget(
                      ad: _bannerAd3!,
                    ),
                  ),
                ),

              //Last Played Chapter
              if (lastPlayedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      "Recently Played Chapter",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (lastPlayedChapter != null)
                SliverToBoxAdapter(
                  child: CupertinoContextMenu.builder(
                      actions: [
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.share,
                          onPressed: (() {
                            // log(chapter!.chapterSummary);

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (nextCtx) => LinesSelectionScreen(
                                  lines: lastPlayedChapter!.chapterSummary
                                      .replaceAll(RegExp(r'\d+\.\s'), '')
                                      .split(RegExp(r'\.\s')),
                                  chapterName:
                                      lastPlayedChapter!.nameTranslated,
                                  chapterID: lastPlayedChapter!.id,
                                ),
                              ),
                            );
                          }),
                          child: const Text(
                            "Share",
                            style: TextStyle(
                              color: AppColors.blackLow,
                            ),
                          ),
                        ),
                        if (!isValueInList(
                            lastPlayedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.check_circle_outline,
                            onPressed: (() {
                              Navigator.pop(context);
                              _addCompleteStatus(lastPlayedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Complete",
                              style: TextStyle(
                                color: AppColors.blackLow,
                              ),
                            ),
                          ),
                        if (isValueInList(
                            lastPlayedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.cancel_outlined,
                            onPressed: (() {
                              Navigator.pop(context);
                              _deleteCompleteStatus(lastPlayedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Incomplete",
                              style: TextStyle(
                                color: AppColors.red,
                              ),
                            ),
                          ),
                      ],
                      enableHapticFeedback: true,
                      builder: (BuildContext ctx, Animation<double> animation) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 120,
                          width: MediaQuery.of(context).size.width - 30,
                          margin: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 5,
                            bottom: 10,
                          ),
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                            left: 15,
                            right: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.containerColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppColors.shadow,
                            gradient: AppColors.gradient,
                          ),
                          child: OpenContainer(
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            tappable: false,
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: AppColors.transparent,
                            openColor: AppColors.transparent,
                            openBuilder: ((openCtx, _) {
                              return VersesScreen(
                                langIndex: 0,
                                wordIdx: widget.wordIdx,
                                flutterTts: widget.flutterTts,
                                chapter: lastPlayedChapter!,
                                isCompleted: !isValueInList(
                                    lastPlayedChapter!.id, completedChapters),
                              );
                            }),
                            closedBuilder: ((closedCtx, openContainer) {
                              return GestureDetector(
                                onTap: openContainer,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FlipCard(
                                      onFlip: (() {
                                        if (!isValueInList(
                                            lastPlayedChapter!.id,
                                            completedChapters)) {
                                          _addCompleteStatus(
                                              lastPlayedChapter!.id);
                                        } else {
                                          _deleteCompleteStatus(
                                              lastPlayedChapter!.id);
                                        }
                                      }),
                                      onFlipDone: ((flipped) {
                                        lastDeletedChapterID =
                                            lastPlayedChapter!.id;
                                        getUserData();
                                      }),
                                      front: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: AppColors.borderWidth,
                                            color: !isValueInList(
                                                    lastPlayedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        // transform: Matrix4.rotationY(
                                        //     isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastPlayedChapter!.chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      back: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: !isValueInList(
                                                    lastPlayedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastPlayedChapter!.chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                lastPlayedChapter!
                                                    .nameTranslated,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Number of Verses: ",
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lastPlayedChapter!
                                                        .versesCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .verseCountColor,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            lastPlayedChapter!.chapterSummary,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: AppColors.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                ),

              //Last Played Chapter ad4
              if (isBannerAdLoaded4 && lastPlayedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              if (isBannerAdLoaded4 && lastPlayedChapter != null)
                SliverToBoxAdapter(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: adSize.height.toDouble(),
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AdWidget(
                      ad: _bannerAd4!,
                    ),
                  ),
                ),

              //Last Checked Chapter
              if (lastCheckedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      "Recently Visited Chapter",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (lastCheckedChapter != null)
                SliverToBoxAdapter(
                  child: CupertinoContextMenu.builder(
                      actions: [
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.share,
                          onPressed: (() {
                            // log(chapter!.chapterSummary);

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (nextCtx) => LinesSelectionScreen(
                                  lines: lastCheckedChapter!.chapterSummary
                                      .replaceAll(RegExp(r'\d+\.\s'), '')
                                      .split(RegExp(r'\.\s')),
                                  chapterName:
                                      lastCheckedChapter!.nameTranslated,
                                  chapterID: lastCheckedChapter!.id,
                                ),
                              ),
                            );
                          }),
                          child: const Text(
                            "Share",
                            style: TextStyle(
                              color: AppColors.blackLow,
                            ),
                          ),
                        ),
                        if (!isValueInList(
                            lastCheckedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.check_circle_outline,
                            onPressed: (() {
                              Navigator.pop(context);
                              _addCompleteStatus(lastCheckedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Complete",
                              style: TextStyle(
                                color: AppColors.blackLow,
                              ),
                            ),
                          ),
                        if (isValueInList(
                            lastCheckedChapter!.id, completedChapters))
                          CupertinoContextMenuAction(
                            trailingIcon: Icons.cancel_outlined,
                            onPressed: (() {
                              Navigator.pop(context);
                              _deleteCompleteStatus(lastCheckedChapter!.id);
                              getUserData();
                            }),
                            child: const Text(
                              "Incomplete",
                              style: TextStyle(
                                color: AppColors.red,
                              ),
                            ),
                          ),
                      ],
                      enableHapticFeedback: true,
                      builder: (BuildContext ctx, Animation<double> animation) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 120,
                          width: MediaQuery.of(context).size.width - 30,
                          margin: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 5,
                            bottom: 10,
                          ),
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                            left: 15,
                            right: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.containerColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppColors.shadow,
                            gradient: AppColors.gradient,
                          ),
                          child: OpenContainer(
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            tappable: false,
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: AppColors.transparent,
                            openColor: AppColors.transparent,
                            openBuilder: ((openCtx, _) {
                              return VersesScreen(
                                langIndex: 0,
                                wordIdx: widget.wordIdx,
                                flutterTts: widget.flutterTts,
                                chapter: lastCheckedChapter!,
                                isCompleted: !isValueInList(
                                    lastCheckedChapter!.id, completedChapters),
                              );
                            }),
                            closedBuilder: ((closedCtx, openContainer) {
                              return GestureDetector(
                                onTap: openContainer,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FlipCard(
                                      onFlip: (() {
                                        if (!isValueInList(
                                            lastCheckedChapter!.id,
                                            completedChapters)) {
                                          _addCompleteStatus(
                                              lastCheckedChapter!.id);
                                        } else {
                                          _deleteCompleteStatus(
                                              lastCheckedChapter!.id);
                                        }
                                      }),
                                      onFlipDone: ((flipped) {
                                        lastDeletedChapterID =
                                            lastCheckedChapter!.id;
                                        getUserData();
                                      }),
                                      front: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: AppColors.borderWidth,
                                            color: !isValueInList(
                                                    lastCheckedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastCheckedChapter!.chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      back: AnimatedContainer(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: !isValueInList(
                                                    lastCheckedChapter!.id,
                                                    completedChapters)
                                                ? Colors.redAccent
                                                : AppColors.green,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transform: Matrix4.rotationY(
                                            isFlipped ? 3.14159265 : 0),
                                        child: Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.green
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastCheckedChapter!.chapterNumber
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                lastCheckedChapter!
                                                    .nameTranslated,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Number of Verses: ",
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lastCheckedChapter!
                                                        .versesCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .verseCountColor,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            lastCheckedChapter!.chapterSummary,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: AppColors.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                ),

              //Last Checked Chapter ad5
              if (isBannerAdLoaded5 && lastCheckedChapter != null)
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              if (isBannerAdLoaded5 && lastCheckedChapter != null)
                SliverToBoxAdapter(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: adSize.height.toDouble(),
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AdWidget(
                      ad: _bannerAd5!,
                    ),
                  ),
                ),

              //Completed Chapters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Text(
                    "Completed Chapters",
                    style: TextStyle(
                      color: AppColors.textColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isLoading && chapters.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (listContext, listIdx) {
                      if (chapters.isNotEmpty) {
                        return AnimatedListItem(
                          animationType: AnimationType.fade,
                          index: listIdx,
                          length: chapters.length,
                          aniController: _animationController,
                          child: CupertinoContextMenu.builder(
                            actions: [
                              CupertinoContextMenuAction(
                                trailingIcon: CupertinoIcons.share,
                                onPressed: (() {
                                  log(chapters[listIdx].chapterSummary);

                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (nextCtx) =>
                                          LinesSelectionScreen(
                                        lines: chapters[listIdx]
                                            .chapterSummary
                                            .replaceAll(RegExp(r'\d+\.\s'), '')
                                            .split(RegExp(r'\.\s')),
                                        chapterName:
                                            chapters[listIdx].nameTranslated,
                                        chapterID: chapters[listIdx].id,
                                      ),
                                    ),
                                  );
                                }),
                                child: const Text(
                                  "Share",
                                  style: TextStyle(
                                    color: AppColors.blackLow,
                                  ),
                                ),
                              ),
                              if (!isValueInList(
                                  chapters[listIdx].id, completedChapters))
                                CupertinoContextMenuAction(
                                  trailingIcon: Icons.check_circle_outline,
                                  onPressed: (() {
                                    Navigator.pop(context);
                                    _addCompleteStatus(chapters[listIdx].id);
                                  }),
                                  child: const Text(
                                    "Complete",
                                    style: TextStyle(
                                      color: AppColors.blackLow,
                                    ),
                                  ),
                                ),
                              if (isValueInList(
                                  chapters[listIdx].id, completedChapters))
                                CupertinoContextMenuAction(
                                  trailingIcon: Icons.cancel_outlined,
                                  onPressed: (() {
                                    Navigator.pop(context);
                                    _deleteCompleteStatus(chapters[listIdx].id);
                                  }),
                                  child: const Text(
                                    "Incomplete",
                                    style: TextStyle(
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                            ],
                            enableHapticFeedback: true,
                            builder: ((BuildContext ctx,
                                Animation<double> animation) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 130,
                                width: MediaQuery.of(context).size.width - 18,
                                margin: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: 5,
                                  bottom: 10,
                                ),
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: 10,
                                  right: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.containerColor,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: AppColors.shadow,
                                  gradient: AppColors.gradient,
                                ),
                                child: OpenContainer(
                                  transitionDuration: const Duration(
                                    milliseconds: 400,
                                  ),
                                  tappable: false,
                                  closedElevation: 0,
                                  openElevation: 0,
                                  closedColor: AppColors.transparent,
                                  openColor: AppColors.transparent,
                                  openBuilder: ((openCtx, _) {
                                    return VersesScreen(
                                      langIndex: 0,
                                      wordIdx: widget.wordIdx,
                                      flutterTts: widget.flutterTts,
                                      chapter: chapters[listIdx],
                                      isCompleted: !isValueInList(
                                          chapters[listIdx].id,
                                          completedChapters),
                                    );
                                  }),
                                  closedBuilder: ((closedCtx, openContainer) {
                                    return GestureDetector(
                                      // onTap: (() async {
                                      //   Navigator.push(
                                      //     context,
                                      //     MaterialPageRoute(
                                      //       builder: (nextContext) => VersesScreen(
                                      //         wordIdx: widget.wordIdx,
                                      //         flutterTts: widget.flutterTts,
                                      //         chapter: chapters[listIdx],
                                      //         isCompleted: !isValueInList(
                                      //             chapters[listIdx].id, completedChapters),
                                      //       ),
                                      //     ),
                                      //   );
                                      // }),
                                      onTap: openContainer,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FlipCard(
                                            onFlip: (() {
                                              _deleteCompleteStatus(
                                                  chapters[listIdx].id);
                                            }),
                                            onFlipDone: ((flipped) {
                                              lastDeletedChapterID =
                                                  chapters[listIdx].id;
                                              getUserData();
                                              ScaffoldMessenger.of(listContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  margin: EdgeInsets.only(
                                                    bottom: 30,
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        10,
                                                    right:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            10,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  dismissDirection:
                                                      DismissDirection
                                                          .horizontal,
                                                  backgroundColor:
                                                      AppColors.mainColorLight,
                                                  content: Text(
                                                    "Chapter ${chapters[listIdx].id} is removed.",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  action: SnackBarAction(
                                                    label: "Undo",
                                                    textColor:
                                                        AppColors.textColor,
                                                    onPressed: (() {
                                                      _addCompleteStatus(
                                                          lastDeletedChapterID!);
                                                      getUserData();
                                                    }),
                                                  ),
                                                ),
                                              );
                                            }),
                                            front: AnimatedContainer(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  width: AppColors.borderWidth,
                                                  color: !isValueInList(
                                                          chapters[listIdx].id,
                                                          completedChapters)
                                                      ? Colors.redAccent
                                                      : AppColors.green,
                                                ),
                                              ),
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              transform: Matrix4.rotationY(
                                                  isFlipped ? 3.14159265 : 0),
                                              child: Container(
                                                margin: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.green
                                                      .withOpacity(0.9),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    chapters[listIdx]
                                                        .chapterNumber
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            back: AnimatedContainer(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: !isValueInList(
                                                          chapters[listIdx].id,
                                                          completedChapters)
                                                      ? Colors.redAccent
                                                      : AppColors.green,
                                                ),
                                              ),
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              transform: Matrix4.rotationY(
                                                  isFlipped ? 3.14159265 : 0),
                                              child: Container(
                                                margin: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.green
                                                      .withOpacity(0.9),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    chapters[listIdx]
                                                        .chapterNumber
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 15,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      chapters[listIdx]
                                                          .nameTranslated,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Number of Verses: ",
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .textColor,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          chapters[listIdx]
                                                              .versesCount
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .verseCountColor,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  chapters[listIdx]
                                                      .chapterSummary,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    color: AppColors.textColor
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        );
                      } else if (isLoading) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            child: (Platform.isIOS)
                                ? const CupertinoActivityIndicator(
                                    color: AppColors.green,
                                    radius: 16,
                                  )
                                : const CircularProgressIndicator(
                                    color: AppColors.green,
                                    strokeWidth: 2,
                                  ),
                          ),
                        );
                      }
                      return Center(
                        child: Lottie.asset(
                          "assets/empty_animation.json",
                        ),
                      );
                    },
                    childCount: chapters.length,
                  ),
                ),
              if (isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: (Platform.isIOS)
                          ? const CupertinoActivityIndicator(
                              color: AppColors.green,
                              radius: 16,
                            )
                          : const CircularProgressIndicator(
                              color: AppColors.green,
                              strokeWidth: 2,
                            ),
                    ),
                  ),
                ),
              if (!isLoading && chapters.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Lottie.asset("assets/empty_animation.json"),
                  ),
                ),
              if (!isLoading && chapters.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 70,
                  ),
                ),
            ],
          ),
        ),
        if (isLoadingTranslation)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blackLow.withOpacity(0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
