import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:animated_list_item/animated_list_item.dart';
import 'package:animations/animations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gita_app/models/chapters_model.dart';
import 'package:gita_app/models/shared_lines_model.dart';
import 'package:gita_app/models/verses_model.dart';
import 'package:gita_app/providers/app_providers.dart';
import 'package:gita_app/screens/verse_details_screen.dart';
import 'package:gita_app/screens/verse_image_edit_screen.dart';
import 'package:gita_app/services/keys.dart';
import 'package:gita_app/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/chapter_share_model.dart';
import '../models/notification_store_model.dart';
import '../models/verse_translation_model.dart';
import '../providers/tts_provider.dart';
import '../services/storage_service.dart';
import 'lines_selection_screen.dart';

class VersesScreen extends StatefulWidget {
  const VersesScreen({
    Key? key,
    required this.chapter,
    required this.isCompleted,
    required this.flutterTts,
    required this.wordIdx,
    required this.langIndex,
  }) : super(key: key);

  final ChaptersModel chapter;
  final bool isCompleted;
  final FlutterTts flutterTts;
  final int wordIdx, langIndex;

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen>
    with TickerProviderStateMixin {
  List<VersesModel> verses = [];
  List<int> completedVerses = [];
  late AnimationController _animationController;
  late AnimationController _animationSummaryController;
  late Animation<double> _animationSummary;
  bool isLoading = false,
      isLoadingTranslation = false,
      isBannerAdLoaded = false,
      isListBannerAdLoaded = false,
      isCompleted = false;
  late TabController _summaryTabController;
  int currentChNameIdx = 1, currentWordIndex = -1;
  final gt = GoogleTranslator();
  TextStyle verseTextStyle = GoogleFonts.poppins(
    color: AppColors.textColor,
    fontWeight: FontWeight.bold,
    fontSize: 17,
  );
  int? animationIdx;
  BannerAd? _bannerAd, _listBannerAd;
  AdSize adSize1 = AdSize.fullBanner;
  final int bannerInterval = 5;
  String? translatedVerseHindi, translatedVerseEnglish;
  final ScrollController _scrollController = ScrollController();
  bool isAtTop = false;
  bool isAtBottom = false;
  String? selectedOption;

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

  Future<String> translateTo(String text, String to) async =>
      await gt.translate(text, to: to).then((value) => value.text);

  Future<void> fetchVerses() async {
    isLoading = true;
    setState(() {});
    // String hindiTranslation, englishTranslation;
    verses = await JsonStorage.getVersesOfChapter(widget.chapter.slug);

    if (verses.isEmpty) {
      http.Response response = await http.get(
        Uri.parse(
          "${Keys.apiBaseChaptersUrl}/${widget.chapter.chapterNumber}/verses/",
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
        await JsonStorage.saveVersesOfChapter(verses, widget.chapter.slug);

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

    log(verses[1].transliteration.toString());

    isLoading = false;
    setState(() {});
  }

  Future<void> fetchCompletedVerses() async {
    completedVerses = await JsonStorage.getCompletedVerses();
    setState(() {});
  }

  void _addCompleteStatus(int verseId) async {
    NotificationStoreModel? notificationStoreModelVerse =
        await JsonStorage.getLastCompletedVerseNotification();

    VersesModel? nextVerse =
        await JsonStorage.getVerseOfChapter(widget.chapter.slug, verseId + 1);

    log(notificationStoreModelVerse.toString());

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

    if (nextVerse != null) {
      await AwesomeNotifications().cancelSchedule(notificationID);
      bool isCompletedVerse = await JsonStorage.isVerseCompleted(nextVerse.id);
      bool isCompletedChapter =
          await JsonStorage.isChapterCompleted(widget.chapter.id);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notificationID,
            channelKey: Keys.completedVerseChannelKey,
            notificationLayout: NotificationLayout.BigText,
            title: "Continue Your Bhagavad Gita Progress",
            body:
                "Congratulations on completing Verse $verseId in the Bhagavad Gita. Take the next step to explore profound wisdom in the following verses.",
            payload: {
              "time": notificationTime.toString(),
              "lang": "English",
              "type": "verse",
              "chapter": jsonEncode(widget.chapter),
              "isCompleted": !isCompletedVerse ? "0" : "1",
              "isCompletedChapter": !isCompletedChapter ? "0" : "1",
              "wordIdx": "0",
              "langIndex": "0",
              "verseDetails": jsonEncode(nextVerse),
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
    getDetails();
    setState(() {});
  }

  void _addCompleteChapter(int chapterID) async {
    await JsonStorage.addCompletedChapter(chapterID);
    ChaptersModel chapter =
        ChaptersModel.fromJson(await JsonStorage.getNextChapter(chapterID));
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedChapterNotification();
    bool isCompletedChapter = await JsonStorage.isChapterCompleted(chapter.id);

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

    int notificationID = (notificationStoreModel != null)
        ? notificationStoreModel.notificationId
        : await JsonStorage.getNotificationID() ?? 0;

    await AwesomeNotifications().cancelSchedule(notificationID);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: notificationID,
          channelKey: Keys.completedChapterChannelKey,
          notificationLayout: NotificationLayout.BigText,
          title: "Your Progress in the Bhagavad Gita",
          body:
              "📖 Dive into the Bhagavad Gita! Finish Chapter ${chapter.chapterNumber} and gain wisdom on your spiritual journey. 🌟",
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

    await JsonStorage.setLastCheckedChapter(chapterID);
    await JsonStorage.setLastCheckedChapterNotification(
      NotificationStoreModel(
        id: chapterID,
        notificationId: notificationID,
      ),
    );
  }

  void _deleteCompleteStatus(int verseId) async {
    await JsonStorage.deleteCompletedVerse(verseId);
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedVerseNotification();
    if (notificationStoreModel != null &&
        notificationStoreModel.id == verseId) {
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

  void setLastCheckedChapterNotification(int chapterID) async {
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCheckedChapterNotification();
    Map<String, dynamic> chapter =
        await JsonStorage.getCurrentChapter(chapterID);
    int notificationID = (notificationStoreModel != null)
        ? notificationStoreModel.notificationId
        : await JsonStorage.getNotificationID() ?? 0;

    DateTime notificationTime =
        await JsonStorage.addAndGetNotificationTimeLastCheckedChapter();
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
          channelKey: Keys.lastCheckedChapterChannelKey,
          notificationLayout: NotificationLayout.BigText,
          title: "Bhagavad Gita Progress Update",
          body:
              "Resume your Bhagavad Gita journey in Chapter ${widget.chapter.chapterNumber}. Let timeless teachings guide your path.",
          payload: {
            "time": notificationTime.toString(),
            "lang": "English",
            "type": "chapter",
            "chapter": jsonEncode(chapter),
            "isCompleted": !isCompleted ? "0" : "1",
            "wordIdx": "0",
            "langIndex": "0",
          }),
      schedule: notificationCalendar,
    );
    await JsonStorage.setLastCheckedChapter(chapterID);
    await JsonStorage.setLastCheckedChapterNotification(
      NotificationStoreModel(
        id: chapterID,
        notificationId: notificationID,
      ),
    );
  }

  void getDetails() async {
    await fetchVerses();
    await fetchCompletedVerses();
    selectedOption = await JsonStorage.getTheme() ?? "System";

    isCompleted = !widget.isCompleted;
    setState(() {});
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

  void _checkScrollPosition() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

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
    _summaryTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.langIndex,
    );

    _summaryTabController.addListener(() {
      setState(() {});
    });

    _animationController = AnimationController(
      duration: Duration(
        milliseconds: widget.chapter.versesCount * 150,
      ),
      vsync: this,
    );
    _animationController.forward();

    _animationSummaryController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    );

    _animationSummaryController.forward();

    _bannerAd = BannerAd(
      size: adSize1,
      adUnitId: "ca-app-pub-7050103229809241/8139888122",
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

    _listBannerAd = BannerAd(
      size: AdSize.largeBanner,
      adUnitId: "ca-app-pub-7050103229809241/7015590288",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isListBannerAdLoaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isListBannerAdLoaded = false;
        setState(() {});
        _listBannerAd?.dispose();
      })),
      request: const AdRequest(),
    );

    _bannerAd?.load();
    _listBannerAd?.load();

    _scrollController.addListener(_checkScrollPosition);

    setLastCheckedChapterNotification(widget.chapter.id);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _summaryTabController.dispose();
    _animationController.dispose();
    _animationSummaryController.dispose();
    verses.clear();
    completedVerses.clear();
    _bannerAd?.dispose();
    _listBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Brightness brightness = selectedOption == "Light"
        ? Brightness.light
        : selectedOption == "Dark"
            ? Brightness.dark
            : MediaQuery.of(context).platformBrightness;
    _animationSummary = CurvedAnimation(
      parent: _animationSummaryController,
      curve: Curves.decelerate,
    );
    // log(_animationSummary.value.toString());
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.decelerate,
        width: _bannerAd!.size.width.toDouble(),
        height: isBannerAdLoaded ? _bannerAd!.size.height.toDouble() : 0,
        child: AdWidget(ad: _bannerAd!),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: (() async {
                await fetchCompletedVerses();
                setState(() {});
              }),
              child: CustomScrollView(
                controller: _scrollController,
                physics: AppColors.scrollPhysics,
                slivers: [
                  SliverAppBar(
                    leading: IconButton(
                      icon: Icon(
                        Icons.keyboard_backspace,
                        color: AppColors.textColor,
                      ),
                      onPressed: (() {
                        // widget.flutterTts.stop();
                        // widget.flutterTts.progressHandler!(
                        //     "hello main", 1, 2, "hello child");
                        Navigator.pop(context);
                      }),
                    ),
                    backgroundColor: AppColors.transparent,
                    shadowColor: Colors.black.withOpacity(0.5),
                    elevation: 0,
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: (() {
                          // log(widget.chapter.chapterSummary);
                          if (!isCompleted) {
                            _addCompleteChapter(widget.chapter.id);
                            isCompleted = true;
                            setState(() {});
                          }
                        }),
                        icon: Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: isCompleted
                              ? AppColors.green
                              : AppColors.textColor,
                        ),
                        splashRadius: 20,
                      ),
                      OpenContainer(
                        transitionDuration: const Duration(
                          milliseconds: 400,
                        ),
                        tappable: false,
                        closedElevation: 0,
                        openElevation: 0,
                        closedColor: AppColors.transparent,
                        openColor: AppColors.transparent,
                        closedBuilder: ((closedCtx, openContainer) {
                          return IconButton(
                            onPressed: openContainer,
                            icon: Icon(
                              CupertinoIcons.share,
                              color: AppColors.textColor,
                            ),
                            splashRadius: 20,
                          );
                        }),
                        openBuilder: ((openCtx, _) {
                          return LinesSelectionScreen(
                            lines: widget.chapter.chapterSummary
                                .replaceAll(RegExp(r'\d+\.\s'), '')
                                .split(RegExp(r'\.\s')),
                            chapterName: widget.chapter.nameTranslated,
                            chapterID: widget.chapter.id,
                          );
                        }),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                    title: Center(
                      child: (widget.chapter.nameTranslated
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .length >=
                              3)
                          ? SizedBox(
                              height: 20,
                              width: MediaQuery.of(context).size.width,
                              child: Marquee(
                                text:
                                    "${widget.chapter.chapterNumber}. ${widget.chapter.nameTranslated.trim()}",
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                velocity: 50,
                                blankSpace: 40,
                                fadingEdgeStartFraction: 0.3,
                                fadingEdgeEndFraction: 0.3,
                                // startPadding: 200,
                              ),
                            )
                          : Text(
                              "${widget.chapter.chapterNumber}. ${widget.chapter.nameTranslated.trim()}",
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _animationSummary,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 30,
                        margin: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 5,
                          bottom: 10,
                        ),
                        padding: const EdgeInsets.only(
                          top: 15,
                          bottom: 20,
                          left: 15,
                          right: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mainColorLight.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: AppColors.shadow,
                          gradient: AppColors.gradient,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Chapter Summary",
                                  style: TextStyle(
                                    color: AppColors.textColor.withOpacity(0.5),
                                  ),
                                ),
                                TabBar(
                                  controller: _summaryTabController,
                                  isScrollable: true,
                                  unselectedLabelColor:
                                      AppColors.textColor.withOpacity(0.2),
                                  // unselectedLabelStyle: TextStyle(
                                  //   fontWeight: FontWeight.bold,
                                  // ),
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  labelColor:
                                      AppColors.textColor.withOpacity(0.5),
                                  indicatorColor: AppColors.transparent,
                                  onTap: ((index) {
                                    _summaryTabController.animateTo(index);
                                    _summaryTabController.index = index;
                                    setState(() {});
                                  }),
                                  tabs: const [
                                    Text(
                                      "English",
                                    ),
                                    Text(
                                      "Hindi",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Consumer<TTSProvider>(
                                builder: (ctx, ttsProvider, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: (_summaryTabController.index == 0)
                                    ? widget.chapter.chapterSummary
                                            .split(' ')
                                            .length *
                                        3.3
                                    : ttsProvider.isPlaying
                                        ? widget.chapter.chapterSummaryHindi
                                                .split(' ')
                                                .length *
                                            2.5
                                        : widget.chapter.chapterSummaryHindi
                                                .split(' ')
                                                .length *
                                            2.1,
                                width: MediaQuery.of(context).size.width,
                                child: TabBarView(
                                  controller: _summaryTabController,
                                  children: [
                                    ttsProvider.isPlaying &&
                                            ttsProvider.chapterID ==
                                                widget.chapter.id &&
                                            ttsProvider.chapterSummaryLang ==
                                                "english"
                                        ? RichText(
                                            text: TextSpan(
                                              children:
                                                  ttsProvider.lyricsWordsEnglish
                                                      .asMap()
                                                      .map((index, word) {
                                                        // log(currentWordIndex.toString());

                                                        TextStyle textStyle =
                                                            index <=
                                                                    ttsProvider
                                                                        .wordIndex
                                                                ? GoogleFonts
                                                                    .merriweather(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                                                                        ? Colors
                                                                            .black
                                                                        : AppColors
                                                                            .white,
                                                                    height: 1.5,
                                                                  );

                                                        // widget.flutterTts.progressHandler!(
                                                        //     widget.chapter.chapterSummary
                                                        //         .trim(),
                                                        //     index,
                                                        //     currentWordIndex,
                                                        //     word);

                                                        return MapEntry(
                                                          index,
                                                          TextSpan(
                                                            text: "$word ",
                                                            style: textStyle,
                                                          ),
                                                        );
                                                      })
                                                      .values
                                                      .toList(),
                                            ),
                                          )
                                        : Text(
                                            widget.chapter.chapterSummary
                                                .trim(),
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              height: 1.7,
                                            ),
                                          ),
                                    ttsProvider.isPlaying &&
                                            ttsProvider.chapterID ==
                                                widget.chapter.id &&
                                            ttsProvider.chapterSummaryLang ==
                                                "hindi"
                                        ? RichText(
                                            text: TextSpan(
                                              children:
                                                  ttsProvider.lyricsWordsEnglish
                                                      .asMap()
                                                      .map((index, word) {
                                                        // log(currentWordIndex.toString());

                                                        TextStyle textStyle =
                                                            index <=
                                                                    ttsProvider
                                                                        .wordIndex
                                                                ? GoogleFonts
                                                                    .merriweather(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                                                                        ? Colors
                                                                            .black
                                                                        : AppColors
                                                                            .white,
                                                                    height: 1.5,
                                                                  );

                                                        // widget.flutterTts.progressHandler!(
                                                        //     widget.chapter.chapterSummary
                                                        //         .trim(),
                                                        //     index,
                                                        //     currentWordIndex,
                                                        //     word);

                                                        return MapEntry(
                                                          index,
                                                          TextSpan(
                                                            text: "$word ",
                                                            style: textStyle,
                                                          ),
                                                        );
                                                      })
                                                      .values
                                                      .toList(),
                                            ),
                                          )
                                        : Text(
                                            widget.chapter.chapterSummaryHindi
                                                .trim(),
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              height: 1.7,
                                            ),
                                          ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(
                              height: 10,
                            ),
                            Consumer<TTSProvider>(
                              builder: (ctx, ttsProvider, child) {
                                return GestureDetector(
                                  onTap: (() async {
                                    // final installed = await flutterTts
                                    //     .isLanguageAvailable("sa");
                                    // log(installed.toString());

                                    ttsProvider.resetLyricsWordsEnglish();
                                    ttsProvider.resetChapterName();
                                    ttsProvider.resetLyricsWordsEnglish();
                                    ttsProvider.wordIndexReset();
                                    ttsProvider.resetCompleteStatus();

                                    await AwesomeNotifications()
                                        .cancelNotificationsByChannelKey(Keys
                                            .mediaNotificationChapterChannelKey);

                                    // if (isStopped) {
                                    if (ttsProvider.isPlaying &&
                                        ttsProvider.chapterID ==
                                            widget.chapter.id) {
                                      log("same id playing, stopped");
                                      ttsProvider.playingStatusUpdate(false);
                                      ttsProvider.resetLyricsCompleteStatus();

                                      // ttsProvider.resetLyricsWords();
                                      // ttsProvider.resetChapterID();
                                      // ttsProvider.resetChapterName();
                                      await widget.flutterTts.stop();
                                    } else {
                                      // log(widget.chapter.chapterSummary);
                                      widget.flutterTts.stop();
                                      NotificationStoreModel?
                                          notificationStoreModel =
                                          await JsonStorage
                                              .getLastPlayedChapterNotification();
                                      int notificationID =
                                          (notificationStoreModel != null)
                                              ? notificationStoreModel
                                                  .notificationId
                                              : await JsonStorage
                                                      .getNotificationID() ??
                                                  0;
                                      await AwesomeNotifications()
                                          .cancelSchedule(notificationID);

                                      ttsProvider.resetChapterID();

                                      ttsProvider.setCompleteStatus(
                                          !widget.isCompleted);

                                      ttsProvider
                                          .setChapterID(widget.chapter.id);
                                      // changeDefaultColor();
                                      DateTime notificationTime = await JsonStorage
                                          .addAndGetNotificationTimeLastPlayedChapter();
                                      NotificationCalendar
                                          notificationCalendar =
                                          NotificationCalendar(
                                        year: notificationTime.year,
                                        month: notificationTime.month,
                                        hour: notificationTime.hour,
                                        minute: notificationTime.minute,
                                        second: 0,
                                        millisecond: 0,
                                        repeats: true,
                                      );

                                      ttsProvider.playingStatusUpdate(true);
                                      ttsProvider.setLyricsCompleteStatus(true);
                                      // log(ttsProvider.chapterName);

                                      ttsProvider.setChapterSummary(
                                          widget.chapter.chapterSummary.trim());

                                      if (_summaryTabController.index == 0) {
                                        ttsProvider.setLyricsWordsEnglish(
                                          widget.chapter.chapterSummary
                                              .trim()
                                              .replaceAll("\n", " ")
                                              .split(" "),
                                        );
                                        ttsProvider.setChapterName(widget
                                            .chapter.nameTranslated
                                            .trim());
                                        await widget.flutterTts
                                            .setLanguage("en-IN");

                                        ttsProvider
                                            .setChapterSummaryLang("english");

                                        await AwesomeNotifications()
                                            .createNotification(
                                          content: NotificationContent(
                                              id: notificationID,
                                              channelKey: Keys
                                                  .lastPlayedChapterChannelKey,
                                              notificationLayout:
                                                  NotificationLayout.BigText,
                                              title: "Gita Update",
                                              body:
                                                  "🎧 Keep going! Chapter ${ttsProvider.chapterID} is waiting. 📚🔊",
                                              payload: {
                                                "time":
                                                    notificationTime.toString(),
                                                "lang": "English",
                                                "type": "chapter",
                                                "chapter":
                                                    jsonEncode(widget.chapter),
                                                "isCompleted":
                                                    !isCompleted ? "0" : "1",
                                                "wordIdx": ttsProvider.wordIndex
                                                    .toString(),
                                                "langIndex": ttsProvider
                                                            .chapterSummaryLang ==
                                                        "english"
                                                    ? "0"
                                                    : "1",
                                              }),
                                          schedule: notificationCalendar,
                                        );

                                        await AwesomeNotifications()
                                            .createNotification(
                                          content: NotificationContent(
                                              id: 0,
                                              channelKey: Keys
                                                  .mediaNotificationChapterChannelKey,
                                              title:
                                                  widget.chapter.nameTranslated,
                                              body:
                                                  "Now playing chapter ${widget.chapter.chapterNumber}",
                                              notificationLayout:
                                                  NotificationLayout.Default,
                                              roundedBigPicture: true,
                                              actionType: ActionType.KeepOnTop,
                                              autoDismissible: false,
                                              locked: true,
                                              category:
                                                  NotificationCategory.Event,
                                              payload: {
                                                "time":
                                                    notificationTime.toString(),
                                                "chapter":
                                                    jsonEncode(widget.chapter),
                                              }),
                                        );

                                        await widget.flutterTts.speak(widget
                                            .chapter.chapterSummary
                                            .trim());
                                      } else {
                                        ttsProvider.setLyricsWordsEnglish(
                                          widget.chapter.chapterSummaryHindi
                                              .trim()
                                              .replaceAll("\n", " ")
                                              .split(" "),
                                        );
                                        ttsProvider.setChapterName(
                                            widget.chapter.name.trim());
                                        await widget.flutterTts
                                            .setLanguage("hi-IN");

                                        ttsProvider
                                            .setChapterSummaryLang("hindi");

                                        await AwesomeNotifications()
                                            .createNotification(
                                          content: NotificationContent(
                                              id: notificationID,
                                              channelKey: Keys
                                                  .lastPlayedChapterChannelKey,
                                              notificationLayout:
                                                  NotificationLayout.BigText,
                                              title: "Gita Update",
                                              body:
                                                  "📖 Ready to dive back into Chapter ${ttsProvider.chapterID}? Let's keep listening!",
                                              payload: {
                                                "time":
                                                    notificationTime.toString(),
                                                "lang": "Hindi",
                                                "type": "chapter",
                                                "chapter":
                                                    jsonEncode(widget.chapter),
                                                "isCompleted":
                                                    !isCompleted ? "0" : "1",
                                                "wordIdx": ttsProvider.wordIndex
                                                    .toString(),
                                                "langIndex": ttsProvider
                                                            .chapterSummaryLang ==
                                                        "english"
                                                    ? "0"
                                                    : "1",
                                              }),
                                          schedule: notificationCalendar,
                                        );

                                        await AwesomeNotifications()
                                            .createNotification(
                                          content: NotificationContent(
                                              id: 0,
                                              channelKey: Keys
                                                  .mediaNotificationChapterChannelKey,
                                              title: widget.chapter.name,
                                              body:
                                                  "Now playing chapter ${widget.chapter.chapterNumber}",
                                              notificationLayout:
                                                  NotificationLayout.Default,
                                              roundedBigPicture: true,
                                              actionType: ActionType.KeepOnTop,
                                              autoDismissible: false,
                                              locked: true,
                                              category:
                                                  NotificationCategory.Event,
                                              payload: {
                                                "time":
                                                    notificationTime.toString(),
                                                "chapter":
                                                    jsonEncode(widget.chapter),
                                              }),
                                        );

                                        await widget.flutterTts.speak(widget
                                            .chapter.chapterSummaryHindi
                                            .trim());
                                      }

                                      await JsonStorage
                                          .setLastPlayedChapterNotification(
                                        NotificationStoreModel(
                                          id: widget.chapter.id,
                                          notificationId: notificationID,
                                        ),
                                      );
                                    }
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.containerColor,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: AppColors.shadow,
                                      gradient: AppColors.gradient,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        ttsProvider.isPlaying &&
                                                ttsProvider.chapterID ==
                                                    widget.chapter.id
                                            ? Icons.stop
                                            : CupertinoIcons.speaker_2_fill,
                                        color: ttsProvider.isPlaying &&
                                                ttsProvider.chapterID ==
                                                    widget.chapter.id
                                            ? AppColors.red
                                            : AppColors.textColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isListBannerAdLoaded)
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
                  if (isListBannerAdLoaded)
                    SliverToBoxAdapter(
                      child: Container(
                        width: _listBannerAd!.size.width.toDouble(),
                        height: _listBannerAd!.size.height.toDouble(),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: AdWidget(
                          ad: _listBannerAd!,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        top: 10,
                        bottom: 10,
                      ),
                      child: Text(
                        "Verses",
                        style: TextStyle(
                          color: AppColors.textColor.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (!isLoading && verses.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (listContext, listIdx) {
                          if (verses.isNotEmpty) {
                            return AnimatedListItem(
                              index: listIdx,
                              length: verses.length,
                              aniController: _animationController,
                              animationType: AnimationType.fade,
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

                                            bool chapterShareDetailsFetched =
                                                    false,
                                                verseIDTranslationModelFetched =
                                                    false,
                                                verseTranslationModelFetched =
                                                    false;
                                            String chapterIDHin = "",
                                                chapterIDSan = "",
                                                chapterNameHin = "",
                                                chapterNameSan = "",
                                                verseIDHin = "",
                                                verseIDSan = "";

                                            ChapterShareModel?
                                                chapterShareModel =
                                                await JsonStorage
                                                    .getChapterShareDetails(
                                                        widget.chapter.id);
                                            if (chapterShareModel != null) {
                                              chapterIDHin = chapterShareModel
                                                  .chapterIdHin;
                                              chapterIDSan = chapterShareModel
                                                  .chapterIdSan;
                                              chapterNameHin = chapterShareModel
                                                  .chapterNameHin;
                                              chapterNameSan = chapterShareModel
                                                  .chapterNameSan;
                                              log("from storage chapterShareModel");
                                              chapterShareDetailsFetched = true;
                                            } else {
                                              chapterIDHin = await translateTo(
                                                  widget.chapter.id.toString(),
                                                  'hi');
                                              chapterIDSan = await translateTo(
                                                  widget.chapter.id.toString(),
                                                  'sa');
                                              chapterNameHin =
                                                  await translateTo(
                                                      widget.chapter
                                                          .nameTranslated
                                                          .toString(),
                                                      'hi');
                                              chapterNameSan =
                                                  await translateTo(
                                                      widget.chapter
                                                          .nameTranslated
                                                          .toString(),
                                                      'sa');
                                              await JsonStorage
                                                  .setChapterShareDetails(
                                                ChapterShareModel(
                                                  chapterIdHin: chapterIDHin,
                                                  chapterIdSan: chapterIDSan,
                                                  chapterNameHin:
                                                      chapterNameHin,
                                                  chapterNameSan:
                                                      chapterNameSan,
                                                ),
                                                widget.chapter.id,
                                              );
                                              log("from network chapterShareModel");
                                              chapterShareDetailsFetched = true;
                                            }

                                            TranslationModel?
                                                verseIDTranslationModel =
                                                await JsonStorage
                                                    .getVerseIDTranslation(
                                                        verses[listIdx].id);

                                            if (verseIDTranslationModel !=
                                                null) {
                                              verseIDHin =
                                                  verseIDTranslationModel.hin;
                                              verseIDSan =
                                                  verseIDTranslationModel.san;
                                              log("verseIDTranslationModel from storage");
                                              verseIDTranslationModelFetched =
                                                  true;
                                            } else {
                                              verseIDHin = await gt
                                                  .translate(
                                                      verses[listIdx]
                                                          .id
                                                          .toString(),
                                                      to: "hi")
                                                  .then(
                                                    (value) => value.text,
                                                  );

                                              verseIDSan = await gt
                                                  .translate(
                                                      verses[listIdx]
                                                          .id
                                                          .toString(),
                                                      to: "sa")
                                                  .then(
                                                    (value) => value.text,
                                                  );

                                              await JsonStorage
                                                  .setVerseIDTranslation(
                                                TranslationModel(
                                                  eng: verses[listIdx]
                                                      .id
                                                      .toString(),
                                                  san: verseIDSan,
                                                  hin: verseIDHin,
                                                ),
                                                verses[listIdx].id,
                                              );

                                              log("verseIDTranslationModel from storage");

                                              verseIDTranslationModelFetched =
                                                  true;
                                            }

                                            TranslationModel?
                                                verseTranslationModel =
                                                await JsonStorage
                                                    .getSharedVerseTranslation(
                                                        verses[listIdx].id);

                                            if (verseTranslationModel != null) {
                                              verseTranslationModelFetched =
                                                  true;
                                              log("verseTranslationModel from storage");
                                            } else {
                                              await JsonStorage
                                                  .setSharedVerseTranslation(
                                                verses[listIdx].text,
                                                verses[listIdx].id,
                                              );
                                              verseTranslationModel =
                                                  await JsonStorage
                                                      .getSharedVerseTranslation(
                                                          verses[listIdx].id);
                                              log("verseTranslationModel from network");
                                              verseTranslationModelFetched =
                                                  true;
                                            }

                                            allAppProvider.isLoadingFunc(false);
                                            if (chapterShareDetailsFetched &&
                                                verseIDTranslationModelFetched &&
                                                verseTranslationModelFetched &&
                                                verseTranslationModel != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (nextCtx) =>
                                                      VerseImageEditScreen(
                                                    verse: verses[listIdx].text,
                                                    verseEng:
                                                        verseTranslationModel!
                                                            .eng,
                                                    verseHin:
                                                        verseTranslationModel
                                                            .hin,
                                                    chapterNameEng: widget
                                                        .chapter.nameTranslated,
                                                    chapterIDEng:
                                                        widget.chapter.id,
                                                    verseIDEng:
                                                        verses[listIdx].id,
                                                    chapterIDHin: chapterIDHin,
                                                    chapterIDSan: chapterIDSan,
                                                    verseIDHin: verseIDHin,
                                                    verseIDSan: verseIDSan,
                                                    chapterNameSan:
                                                        widget.chapter.name,
                                                    chapterNameHin:
                                                        chapterNameHin,
                                                    verseStringEng:
                                                        'Verse number: ',
                                                    verseStringSan:
                                                        "श्लोक संख्या : ",
                                                    verseStringHin:
                                                        "श्लोक संख्या: ",
                                                  ),
                                                ),
                                              );
                                            }

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
                                        if (!_isValueInList(verses[listIdx].id,
                                            completedVerses))
                                          CupertinoContextMenuAction(
                                            trailingIcon:
                                                Icons.check_circle_outline,
                                            onPressed: (() {
                                              Navigator.pop(context);
                                              _addCompleteStatus(
                                                  verses[listIdx].id);
                                            }),
                                            child: const Text(
                                              "Complete",
                                              style: TextStyle(
                                                color: AppColors.blackLow,
                                              ),
                                            ),
                                          ),
                                        if (_isValueInList(verses[listIdx].id,
                                            completedVerses))
                                          CupertinoContextMenuAction(
                                            trailingIcon: Icons.cancel_outlined,
                                            onPressed: (() {
                                              Navigator.pop(context);
                                              _deleteCompleteStatus(
                                                  verses[listIdx].id);
                                            }),
                                            child: const Text(
                                              "Incomplete",
                                              style: TextStyle(
                                                color: AppColors.red,
                                              ),
                                            ),
                                          ),
                                      ],
                                      builder: (BuildContext ctx,
                                          Animation<double> animation) {
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 400),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              30,
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
                                            borderRadius:
                                                BorderRadius.circular(15),
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
                                            closedBuilder:
                                                ((closedCtx, openContainer) {
                                              return GestureDetector(
                                                onTap: openContainer,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    FlipCard(
                                                      onFlip: (() {
                                                        if (!_isValueInList(
                                                            verses[listIdx].id,
                                                            completedVerses)) {
                                                          _addCompleteStatus(
                                                              verses[listIdx]
                                                                  .id);
                                                        } else {
                                                          _deleteCompleteStatus(
                                                              verses[listIdx]
                                                                  .id);
                                                        }
                                                      }),
                                                      onFlipDone: ((flipped) {
                                                        setState(() {});
                                                      }),
                                                      front: AnimatedContainer(
                                                        width: 50,
                                                        height: 50,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            width: AppColors
                                                                .borderWidth,
                                                            color: !_isValueInList(
                                                                    verses[listIdx]
                                                                        .id,
                                                                    completedVerses)
                                                                ? Colors
                                                                    .redAccent
                                                                : AppColors
                                                                    .green,
                                                          ),
                                                        ),
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .all(3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColors
                                                                .green
                                                                .withOpacity(
                                                                    0.9),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              verses[listIdx]
                                                                  .verseNumber
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                color: AppColors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 17,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      back: AnimatedContainer(
                                                        width: 50,
                                                        height: 50,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            width: AppColors
                                                                .borderWidth,
                                                            color: !_isValueInList(
                                                                    verses[listIdx]
                                                                        .id,
                                                                    completedVerses)
                                                                ? Colors
                                                                    .redAccent
                                                                : AppColors
                                                                    .green,
                                                          ),
                                                        ),
                                                        // !_isValueInList(
                                                        //     verses[listIdx].id,
                                                        //     completedVerses)
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300),

                                                        alignment:
                                                            Alignment.center,
                                                        child: Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .all(3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColors
                                                                .green
                                                                .withOpacity(
                                                                    0.9),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              verses[listIdx]
                                                                  .verseNumber
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                color: AppColors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                                                        verses[listIdx]
                                                            .text
                                                            .replaceAll(
                                                                "\n", " "),
                                                        maxLines:
                                                            calculateNumberOfLines(
                                                          verses[listIdx].text,
                                                          verseTextStyle,
                                                          MediaQuery.of(
                                                                  listContext)
                                                              .size
                                                              .width,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: verseTextStyle,
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
                                                chapter: widget.chapter,
                                                isCompletedChapter:
                                                    widget.isCompleted,
                                                chapterNumber: widget
                                                    .chapter.chapterNumber,
                                                verseDetails: verses[listIdx],
                                                isCompleted: _isValueInList(
                                                  verses[listIdx].id,
                                                  completedVerses,
                                                ),
                                              );
                                            }),
                                          ),
                                        );
                                      });
                                },
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
                        childCount: verses.length,
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
                  if (!isLoading && verses.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Lottie.asset("assets/empty_animation.json"),
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
        ),
      ),
    );
  }
}
