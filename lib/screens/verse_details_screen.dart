import 'dart:convert';
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gita_app/models/notification_store_model.dart';
import 'package:gita_app/models/verse_translation_model.dart';
import 'package:gita_app/models/verses_model.dart';
import 'package:gita_app/screens/verse_image_edit_screen.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/chapter_share_model.dart';
import '../models/chapters_model.dart';
import '../models/shared_lines_model.dart';
import '../services/keys.dart';

class VerseDetailsScreen extends StatefulWidget {
  const VerseDetailsScreen({
    Key? key,
    required this.chapterNumber,
    required this.verseDetails,
    required this.isCompleted,
    required this.chapter,
    required this.isCompletedChapter,
    required this.flutterTts,
    required this.wordIdx,
  }) : super(key: key);

  final int chapterNumber, wordIdx;
  final VersesModel verseDetails;
  final bool isCompleted;
  final ChaptersModel chapter;
  final bool isCompletedChapter;
  final FlutterTts flutterTts;

  @override
  State<VerseDetailsScreen> createState() => _VerseDetailsScreenState();
}

class _VerseDetailsScreenState extends State<VerseDetailsScreen>
    with TickerProviderStateMixin {
  List<String> languagesTranslation = [];
  List<String> languagesCommentaries = [];
  List<Commentary> filteredTranslations = [];
  List<Commentary> filteredCommentaries = [];
  int selectedTranslationFilterIdx = -1,
      selectedCommentariesFilterIdx = -1,
      currentWordIndex = -1;
  String? translatedVerseHindi, translatedVerseEnglish;
  late TabController _summaryTabController;
  final gt = GoogleTranslator();
  // FlutterTts flutterTts = FlutterTts();
  final verseTextStyle = TextStyle(
    color: AppColors.textColor,
    fontWeight: FontWeight.bold,
    fontSize: 15,
    height: 1.5,
  );
  TextStyle translationTextStyle = const TextStyle(
    color: AppColors.white,
  );
  BannerAd? _bannerAd1, _bannerAd2, _bannerAd3, _bannerAd4;
  bool isBannerAd1Loaded = false,
      isBannerAd2Loaded = false,
      isBannerAd3Loaded = false,
      isBannerAd4Loaded = false,
      isLoadingTranslation = false,
      isCompleted = false;
  TranslationModel? verseTranslationModel;
  final ScrollController _scrollController = ScrollController();
  bool isAtTop = false;
  bool isAtBottom = false;

  void filterTranslationLanguages(int filterIdx) {
    filteredTranslations = widget.verseDetails.translations
        .where((translation) =>
            translation.language == languagesTranslation[filterIdx])
        .toList();
    setState(() {});
  }

  void filterCommentaryLanguages(int filterIdx) {
    filteredCommentaries = widget.verseDetails.commentaries
        .where((commentary) =>
            commentary.language == languagesCommentaries[filterIdx])
        .toList();
    setState(() {});
  }

  void addTranslationLanguages() {
    for (var translation in widget.verseDetails.translations) {
      String language = translation.language;
      if (!languagesTranslation.contains(language)) {
        languagesTranslation.add(language);
      }
    }

    setState(() {});
  }

  void addCommentaryLanguages() {
    for (var commentary in widget.verseDetails.commentaries) {
      String language = commentary.language;
      if (!languagesCommentaries.contains(language)) {
        languagesCommentaries.add(language);
      }
    }

    setState(() {});
  }

  void getDetails() async {
    // translatedVerse = widget.verseDetails.text;
    // if (Platform.isAndroid) {
    //   List voices = await flutterTts.getVoices;
    //   final defaultVoice = await flutterTts.getDefaultVoice;
    //
    //   log(defaultVoice.toString());
    //
    //   // print("Default Android Voice:");
    //   // print("Name: ${defaultVoice["name"]}");
    //   // print("Locale: ${defaultVoice.locale}");
    //   // print("Quality: ${defaultVoice.quality}");
    // }

    verseTranslationModel =
        await JsonStorage.getSharedVerseTranslation(widget.verseDetails.id);

    if (verseTranslationModel != null) {
      log("verseTranslationModel from storage");
    } else {
      await JsonStorage.setSharedVerseTranslation(
        widget.verseDetails.text,
        widget.verseDetails.id,
      );
      verseTranslationModel =
          await JsonStorage.getSharedVerseTranslation(widget.verseDetails.id);
      log("verseTranslationModel from network");
    }

    setState(() {});
  }

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

  void setLastCheckedVerseNotification(int verseID) async {
    // int? lastVerseID = await JsonStorage.getLastCheckedVerse();
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCheckedVerseNotification();
    VersesModel? verse = await JsonStorage.getVerseOfChapter(
        widget.chapter.slug, widget.verseDetails.id);
    bool isCompletedChapter = await JsonStorage.isChapterCompleted(verseID);
    bool isCompleted = await JsonStorage.isVerseCompleted(verse!.id);
    int notificationID = (notificationStoreModel != null)
        ? notificationStoreModel.notificationId
        : await JsonStorage.getNotificationID() ?? 0;

    await AwesomeNotifications().cancelSchedule(notificationID);
    DateTime notificationTime =
        await JsonStorage.addAndGetNotificationTimeLastCheckedVerses();

    NotificationCalendar notificationCalendar = NotificationCalendar(
      year: notificationTime.year,
      month: notificationTime.month,
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      second: 0,
      millisecond: 0,
      repeats: true,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: notificationID,
          channelKey: Keys.lastCheckedVerseChannelKey,
          notificationLayout: NotificationLayout.BigText,
          title: "Continue Your Bhagavad Gita Study",
          body:
              "📖 Verse ${verse.verseNumber} of Chapter ${widget.chapter.chapterNumber}: ${widget.chapter.nameTranslated} in the Bhagavad Gita awaits your wisdom. Dive in, grow spiritually. 🌟",
          payload: {
            "time": notificationTime.toString(),
            "lang": "English",
            "type": "verse",
            "chapter": jsonEncode(widget.chapter),
            "isCompleted": !isCompleted ? "0" : "1",
            "isCompletedChapter": !isCompletedChapter ? "0" : "1",
            "wordIdx": "0",
            "langIndex": "0",
            "verseDetails": jsonEncode(verse),
          }),
      schedule: notificationCalendar,
    );
    await JsonStorage.setLastCheckedVerse(verseID);
    await JsonStorage.setLastCheckedVerseNotification(
      NotificationStoreModel(
        id: verseID,
        notificationId: notificationID,
      ),
    );
  }

  Future<String> translateTo(String text, String to) async =>
      await gt.translate(text, to: to).then((value) => value.text);

  void _addCompleteStatus(int verseId) async {
    NotificationStoreModel? notificationStoreModelVerse =
        await JsonStorage.getLastCompletedVerseNotification();

    VersesModel? nextVerse =
        await JsonStorage.getVerseOfChapter(widget.chapter.slug, verseId + 1);

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
                "👏 Completed Verse $verseId! Explore more verses in the Bhagavad Gita 📜🚶‍♂️ to deepen your wisdom journey. 🌟",
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
    setState(() {});
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
    _summaryTabController = TabController(
      length: 3,
      vsync: this,
    );
    getDetails();

    _bannerAd1 = BannerAd(
      size: AdSize.fullBanner,
      adUnitId: "ca-app-pub-7050103229809241/2401310433",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isBannerAd1Loaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isBannerAd1Loaded = false;
        setState(() {});
        _bannerAd1?.dispose();
      })),
      request: const AdRequest(),
    );
    _bannerAd2 = BannerAd(
      size: AdSize.largeBanner,
      adUnitId: "ca-app-pub-7050103229809241/4705121717",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isBannerAd2Loaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isBannerAd2Loaded = false;
        setState(() {});
        _bannerAd2?.dispose();
      })),
      request: const AdRequest(),
    );
    _bannerAd3 = BannerAd(
      size: AdSize.largeBanner,
      adUnitId: "ca-app-pub-7050103229809241/8515578056",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isBannerAd3Loaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isBannerAd3Loaded = false;
        setState(() {});
        _bannerAd3?.dispose();
      })),
      request: const AdRequest(),
    );
    _bannerAd4 = BannerAd(
      size: AdSize.largeBanner,
      adUnitId: "ca-app-pub-7050103229809241/4253448156",
      listener: BannerAdListener(onAdLoaded: ((ad) {
        isBannerAd4Loaded = true;
        setState(() {});
      }), onAdFailedToLoad: ((ad, err) {
        isBannerAd4Loaded = false;
        setState(() {});
        _bannerAd4?.dispose();
      })),
      request: const AdRequest(),
    );

    _bannerAd1?.load();
    _bannerAd2?.load();
    _bannerAd3?.load();
    _bannerAd4?.load();

    _scrollController.addListener(_checkScrollPosition);

    setLastCheckedVerseNotification(widget.verseDetails.id);

    addTranslationLanguages();
    addCommentaryLanguages();
    super.initState();
  }

  @override
  void dispose() {
    languagesTranslation.clear();
    languagesCommentaries.clear();
    filteredTranslations.clear();
    filteredCommentaries.clear();
    _summaryTabController.dispose();
    _scrollController.dispose();
    _bannerAd1?.dispose();
    _bannerAd2?.dispose();
    _bannerAd3?.dispose();
    _bannerAd4?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.decelerate,
        width: _bannerAd1!.size.width.toDouble(),
        height: isBannerAd1Loaded ? _bannerAd1!.size.height.toDouble() : 0,
        child: AdWidget(ad: _bannerAd1!),
      ),
      body: SafeArea(
        child: (verseTranslationModel != null)
            ? Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    physics: AppColors.scrollPhysics,
                    slivers: [
                      SliverAppBar(
                        toolbarHeight: 56,
                        backgroundColor: AppColors.transparent,
                        shadowColor: Colors.black.withOpacity(0.5),
                        elevation: 0,
                        floating: true,
                        leading: IconButton(
                          icon: Icon(
                            Icons.keyboard_backspace,
                            color: AppColors.textColor,
                          ),
                          onPressed: (() {
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (nextCtx) => VersesScreen(
                            //       wordIdx: widget.wordIdx,
                            //       flutterTts: widget.flutterTts,
                            //       chapter: widget.chapter,
                            //       isCompleted: widget.isCompletedChapter,
                            //     ),
                            //   ),
                            // );
                            Navigator.pop(context);
                          }),
                        ),
                        actions: [
                          IconButton(
                            onPressed: (() {
                              // log(widget.chapter.chapterSummary);
                              if (!isCompleted) {
                                _addCompleteStatus(widget.verseDetails.id);
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
                          IconButton(
                            onPressed: (() async {
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
                                      widget.chapter.id);
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
                                    widget.chapter.id.toString(), 'hi');
                                chapterIDSan = await translateTo(
                                    widget.chapter.id.toString(), 'sa');
                                chapterNameHin = await translateTo(
                                    widget.chapter.nameTranslated.toString(),
                                    'hi');
                                chapterNameSan = await translateTo(
                                    widget.chapter.nameTranslated.toString(),
                                    'sa');
                                await JsonStorage.setChapterShareDetails(
                                  ChapterShareModel(
                                    chapterIdHin: chapterIDHin,
                                    chapterIdSan: chapterIDSan,
                                    chapterNameHin: chapterNameHin,
                                    chapterNameSan: chapterNameSan,
                                  ),
                                  widget.chapter.id,
                                );
                                log("from network chapterShareModel");
                                chapterShareDetailsFetched = true;
                              }

                              TranslationModel? verseIDTranslationModel =
                                  await JsonStorage.getVerseIDTranslation(
                                      widget.verseDetails.id);

                              if (verseIDTranslationModel != null) {
                                verseIDHin = verseIDTranslationModel.hin;
                                verseIDSan = verseIDTranslationModel.san;
                                log("verseIDTranslationModel from storage");
                                verseIDTranslationModelFetched = true;
                              } else {
                                verseIDHin = await gt
                                    .translate(
                                        widget.verseDetails.id.toString(),
                                        to: "hi")
                                    .then(
                                      (value) => value.text,
                                    );

                                verseIDSan = await gt
                                    .translate(
                                        widget.verseDetails.id.toString(),
                                        to: "sa")
                                    .then(
                                      (value) => value.text,
                                    );

                                await JsonStorage.setVerseIDTranslation(
                                  TranslationModel(
                                    eng: widget.verseDetails.id.toString(),
                                    san: verseIDSan,
                                    hin: verseIDHin,
                                  ),
                                  widget.verseDetails.id,
                                );

                                log("verseIDTranslationModel from storage");

                                verseIDTranslationModelFetched = true;
                              }

                              TranslationModel? verseTranslationModel =
                                  await JsonStorage.getSharedVerseTranslation(
                                      widget.verseDetails.id);

                              if (verseTranslationModel != null) {
                                verseTranslationModelFetched = true;
                                log("verseTranslationModel from storage");
                              } else {
                                await JsonStorage.setSharedVerseTranslation(
                                  widget.verseDetails.text,
                                  widget.verseDetails.id,
                                );
                                verseTranslationModel =
                                    await JsonStorage.getSharedVerseTranslation(
                                        widget.verseDetails.id);
                                log("verseTranslationModel from network");
                                verseTranslationModelFetched = true;
                              }

                              if (chapterShareDetailsFetched &&
                                  verseIDTranslationModelFetched &&
                                  verseTranslationModelFetched &&
                                  verseTranslationModel != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (nextCtx) => VerseImageEditScreen(
                                      verse: widget.verseDetails.text,
                                      verseEng: verseTranslationModel!.eng,
                                      verseHin: verseTranslationModel.hin,
                                      chapterNameEng:
                                          widget.chapter.nameTranslated,
                                      chapterIDEng: widget.chapter.id,
                                      verseIDEng: widget.verseDetails.id,
                                      chapterIDHin: chapterIDHin,
                                      chapterIDSan: chapterIDSan,
                                      verseIDHin: verseIDHin,
                                      verseIDSan: verseIDSan,
                                      chapterNameSan: widget.chapter.name,
                                      chapterNameHin: chapterNameHin,
                                      verseStringEng: 'Verse number: ',
                                      verseStringSan: "श्लोक संख्या : ",
                                      verseStringHin: "श्लोक संख्या: ",
                                    ),
                                  ),
                                );
                              }

                              isLoadingTranslation = false;
                              setState(() {});
                            }),
                            icon: Icon(
                              CupertinoIcons.share,
                              color: AppColors.textColor,
                            ),
                            splashRadius: 20,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                        ],
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                          ),
                          child: Center(
                            child: Text(
                              "Verse: ${widget.chapterNumber}.${widget.verseDetails.verseNumber}",
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AnimatedContainer(
                              //   duration: Duration(milliseconds: 300),
                              //   child: Row(
                              //     children: [
                              //       Text(
                              //         "Verse",
                              //         style: TextStyle(
                              //           color: AppColors.white.withOpacity(0.5),
                              //         ),
                              //       ),
                              //       Container(
                              //         margin: EdgeInsets.only(
                              //           left: 3,
                              //           right: 4,
                              //         ),
                              //         width: 1.5,
                              //         height: 12,
                              //         decoration: BoxDecoration(
                              //           color: AppColors.white.withOpacity(0.5),
                              //         ),
                              //       ),
                              //       Text(
                              //         "Sanskrit",
                              //         style: TextStyle(
                              //           color: AppColors.white.withOpacity(0.5),
                              //         ),
                              //       ),
                              //       CircleSpacer(),
                              //       Text(
                              //         "English",
                              //         style: TextStyle(
                              //           color: AppColors.white.withOpacity(0.5),
                              //         ),
                              //       ),
                              //       CircleSpacer(),
                              //       Text(
                              //         "Hindi",
                              //         style: TextStyle(
                              //           color: AppColors.white.withOpacity(0.5),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              Row(
                                children: [
                                  Text(
                                    "Verse",
                                    style: TextStyle(
                                      color:
                                          AppColors.textColor.withOpacity(0.5),
                                    ),
                                  ),
                                  TabBar(
                                    controller: _summaryTabController,
                                    isScrollable: true,
                                    unselectedLabelColor:
                                        AppColors.textColor.withOpacity(0.2),
                                    // unselectedLabelStyle: TextStyle(
                                    //   fontSize: 12,
                                    // ),
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelColor:
                                        AppColors.textColor.withOpacity(0.5),
                                    indicatorColor: AppColors.transparent,
                                    onTap: ((index) async {
                                      _summaryTabController.animateTo(index);
                                      switch (index) {
                                        case 1:
                                          await translateToEn(
                                              widget.verseDetails.text,
                                              "en",
                                              widget.verseDetails.slug);
                                        case 2:
                                          await translateToEn(
                                              widget.verseDetails.text,
                                              "hi",
                                              widget.verseDetails.slug);
                                      }

                                      setState(() {});
                                    }),
                                    tabs: const [
                                      Text(
                                        "Sanskrit",
                                      ),
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
                              GestureDetector(
                                  onHorizontalDragEnd: (details) async {
                                if (details.velocity.pixelsPerSecond.dx > 0) {
                                  switch (_summaryTabController.index) {
                                    case 2:
                                      {
                                        _summaryTabController.animateTo(1);
                                        // await translateToEn(
                                        //     widget.verseDetails.text,
                                        //     "en",
                                        //     widget.verseDetails.slug);
                                      }
                                    case 1:
                                      _summaryTabController.animateTo(0);
                                  }
                                } else if (details.velocity.pixelsPerSecond.dx <
                                    0) {
                                  switch (_summaryTabController.index) {
                                    case 0:
                                      {
                                        _summaryTabController.animateTo(1);
                                        // await translateToEn(
                                        //     widget.verseDetails.text,
                                        //     "en",
                                        //     widget.verseDetails.slug);
                                      }
                                    case 1:
                                      {
                                        _summaryTabController.animateTo(2);
                                        // await translateToEn(
                                        //     widget.verseDetails.text,
                                        //     "hi",
                                        //     widget.verseDetails.slug);
                                      }
                                  }
                                }
                                setState(() {});
                              }, child: StreamBuilder(
                                builder: (ctx, snapshot) {
                                  switch (_summaryTabController.index) {
                                    case 0:
                                      return Text(
                                        verseTranslationModel!.san.trim(),
                                        style: verseTextStyle,
                                      );
                                    case 1:
                                      return Text(
                                        style: verseTextStyle,
                                        verseTranslationModel!.eng.trim(),
                                      );
                                    case 2:
                                      return Text(
                                        style: verseTextStyle,
                                        verseTranslationModel!.hin.trim(),
                                      );
                                  }
                                  return Container();
                                },
                              )
                                  // : Center(
                                  //     child: Container(
                                  //       margin: const EdgeInsets.all(10),
                                  //       child: (Platform.isIOS)
                                  //           ? const CupertinoActivityIndicator(
                                  //               color: AppColors.green,
                                  //               radius: 16,
                                  //             )
                                  //           : const CircularProgressIndicator(
                                  //               color: AppColors.green,
                                  //               strokeWidth: 2,
                                  //             ),
                                  //     ),
                                  //   ),
                                  )
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Transliteration",
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                widget.verseDetails.transliteration.trim(),
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  height: 1.6,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      if (isBannerAd2Loaded)
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
                      if (isBannerAd2Loaded)
                        SliverToBoxAdapter(
                          child: Container(
                            width: _bannerAd2!.size.width.toDouble(),
                            height: _bannerAd2!.size.height.toDouble(),
                            margin: const EdgeInsets.only(
                              top: 5,
                              bottom: 10,
                            ),
                            child: AdWidget(
                              ad: _bannerAd2!,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
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
                            bottom: 10,
                            left: 15,
                            right: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.containerColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppColors.shadow,
                            gradient: AppColors.gradient,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Word-Meanings",
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                widget.verseDetails.wordMeanings
                                    .replaceAllMapped(
                                  RegExp(r';\s*|-|—'),
                                  (match) {
                                    if (match.group(0) == '-') {
                                      return ': ';
                                    } else if (match.group(0) == '—') {
                                      return ': ';
                                    } else {
                                      return '\n';
                                    }
                                  },
                                ),
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  height: 1.6,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      if (isBannerAd3Loaded)
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
                      if (isBannerAd3Loaded)
                        SliverToBoxAdapter(
                          child: Container(
                            width: _bannerAd3!.size.width.toDouble(),
                            height: _bannerAd3!.size.height.toDouble(),
                            margin: const EdgeInsets.only(top: 10),
                            child: AdWidget(
                              ad: _bannerAd3!,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 15,
                            bottom: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Translations",
                                    style: TextStyle(
                                      color:
                                          AppColors.textColor.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 7,
                                  ),
                                  if (selectedTranslationFilterIdx != -1)
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.containerColor,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: AppColors.borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          languagesTranslation[
                                                  selectedTranslationFilterIdx]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              GestureDetector(
                                onTap: (() {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: AppColors.transparent,
                                    elevation: 0,
                                    builder: (modalCtx) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          bottom: 15,
                                        ),
                                        padding: const EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                          top: 20,
                                          bottom: 15,
                                        ),
                                        height:
                                            languagesTranslation.length * 110,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: AppColors.containerColor,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Filters",
                                                  style: TextStyle(
                                                    color: AppColors.textColor
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: (() {
                                                    selectedTranslationFilterIdx =
                                                        -1;
                                                    setState(() {});
                                                    Navigator.pop(modalCtx);
                                                  }),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 10,
                                                      right: 10,
                                                      top: 5,
                                                      bottom: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .mainColorLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      boxShadow:
                                                          AppColors.shadow,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          AppColors.mainColor
                                                              .withOpacity(0.3),
                                                          AppColors.mainColor
                                                              .withOpacity(0.5),
                                                          AppColors.mainColor
                                                              .withOpacity(0.7),
                                                          AppColors.mainColor,
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            "Clear",
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .textColor,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Icon(
                                                            Icons.close,
                                                            color: AppColors
                                                                .textColor,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Expanded(
                                              child: ListView.separated(
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return GestureDetector(
                                                    onTap: (() {
                                                      selectedTranslationFilterIdx =
                                                          index;
                                                      filterTranslationLanguages(
                                                          index);
                                                      setState(() {});
                                                      Navigator.pop(modalCtx);
                                                    }),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                        top: 5,
                                                        bottom: 5,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 15,
                                                        right: 15,
                                                        top: 10,
                                                        bottom: 10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .containerColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        boxShadow:
                                                            AppColors.shadow,
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.3),
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.5),
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.7),
                                                            AppColors.mainColor,
                                                          ],
                                                        ),
                                                        border:
                                                            (selectedTranslationFilterIdx ==
                                                                    index)
                                                                ? Border.all(
                                                                    color: AppColors
                                                                        .textColor,
                                                                  )
                                                                : null,
                                                      ),
                                                      child: Text(
                                                        languagesTranslation[
                                                                index]
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textColor,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                separatorBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return const SizedBox(
                                                    height: 10,
                                                  );
                                                },
                                                itemCount:
                                                    languagesTranslation.length,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
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
                                      Icons.filter_list,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      if (selectedTranslationFilterIdx == -1)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (listContext, listIdx) {
                              if (widget.verseDetails.translations.isNotEmpty) {
                                return Container(
                                  width: MediaQuery.of(context).size.width - 30,
                                  margin: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 5,
                                    bottom: 10,
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.containerColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: AppColors.shadow,
                                    gradient: AppColors.gradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget
                                                    .verseDetails
                                                    .translations[listIdx]
                                                    .authorName
                                                    .trim(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                widget
                                                    .verseDetails
                                                    .translations[listIdx]
                                                    .language
                                                    .toUpperCase()
                                                    .trim(),
                                                style: TextStyle(
                                                  color:
                                                      AppColors.verseCountColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // if (widget.verseDetails.translations[listIdx]
                                          //         .language
                                          //         .toLowerCase() ==
                                          //     "english")
                                          //   GestureDetector(
                                          //     onTap: (() async {
                                          //       // final installed = await flutterTts
                                          //       //     .isLanguageAvailable("sa");
                                          //       // log(installed.toString());
                                          //       // currentWordIndex = -1;
                                          //       // isPlaying = true;
                                          //       // translationWords.clear();
                                          //       // translationWords = widget.verseDetails
                                          //       //     .translations[listIdx].description
                                          //       //     .split(" ");
                                          //       // changeDefaultColor();
                                          //       // setState(() {});
                                          //       await flutterTts.speak(widget.verseDetails
                                          //           .translations[listIdx].description
                                          //           .trim());
                                          //     }),
                                          //     child: Container(
                                          //       padding: EdgeInsets.all(10),
                                          //       decoration: BoxDecoration(
                                          //         color: AppColors.containerColor,
                                          //         borderRadius: BorderRadius.circular(15),
                                          //         boxShadow: AppColors.shadow,
                                          //       ),
                                          //       child: Center(
                                          //         child: Icon(
                                          //           Icons.volume_up,
                                          //           color: AppColors.textColor,
                                          //           size: 20,
                                          //         ),
                                          //       ),
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      // isPlaying
                                      //     ? RichText(
                                      //         text: TextSpan(
                                      //           children: translationWords
                                      //               .asMap()
                                      //               .map((index, word) {
                                      //                 TextStyle textStyle = index <=
                                      //                         currentWordIndex
                                      //                     ? TextStyle(
                                      //                         fontWeight: FontWeight.bold,
                                      //                         color: brightness ==
                                      //                                 Brightness.light
                                      //                             ? AppColors.white
                                      //                             : AppColors.green,
                                      //                       )
                                      //                     : TextStyle(
                                      //                         color: brightness ==
                                      //                                 Brightness.light
                                      //                             ? Colors.black
                                      //                             : AppColors.white,
                                      //                       );
                                      //
                                      //                 return MapEntry(
                                      //                   index,
                                      //                   TextSpan(
                                      //                     text: "$word ",
                                      //                     style: textStyle,
                                      //                   ),
                                      //                 );
                                      //               })
                                      //               .values
                                      //               .toList(),
                                      //         ),
                                      //       )
                                      //     : Text(
                                      //         widget.verseDetails.translations[listIdx]
                                      //             .description
                                      //             .trim(),
                                      //         style: isPlaying
                                      //             ? TextStyle(
                                      //                 color: Colors.black,
                                      //               )
                                      //             : TextStyle(
                                      //                 color: AppColors.textColor
                                      //                     .withOpacity(0.7),
                                      //               ),
                                      //       ),
                                      Text(
                                        widget.verseDetails
                                            .translations[listIdx].description
                                            .trim(),
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              // else if (isLoading) {
                              //   return const Center(
                              //     child: CircularProgressIndicator(
                              //       color: AppColors.green,
                              //     ),
                              //   );
                              // }
                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 300,
                                  child: Lottie.asset(
                                    "assets/empty_animation.json",
                                  ),
                                ),
                              );
                            },
                            childCount: widget.verseDetails.translations.length,
                          ),
                        ),
                      if (selectedTranslationFilterIdx != -1)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (listContext, listIdx) {
                              if (filteredTranslations.isNotEmpty) {
                                return Container(
                                  width: MediaQuery.of(context).size.width - 30,
                                  margin: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 5,
                                    bottom: 10,
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.containerColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: AppColors.shadow,
                                    gradient: AppColors.gradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                filteredTranslations[listIdx]
                                                    .authorName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                filteredTranslations[listIdx]
                                                    .language
                                                    .toUpperCase()
                                                    .toString(),
                                                style: TextStyle(
                                                  color:
                                                      AppColors.verseCountColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // if (filteredTranslations[listIdx]
                                          //         .language
                                          //         .toLowerCase() ==
                                          //     "english")
                                          //   GestureDetector(
                                          //     onTap: (() async {
                                          //       // final installed = await flutterTts
                                          //       //     .isLanguageAvailable("sa");
                                          //       // log(installed.toString());
                                          //       await widget.flutterTts.speak(
                                          //           filteredTranslations[listIdx]
                                          //               .description
                                          //               .trim());
                                          //     }),
                                          //     child: Container(
                                          //       padding: const EdgeInsets.all(10),
                                          //       decoration: BoxDecoration(
                                          //         color: AppColors.containerColor,
                                          //         borderRadius:
                                          //             BorderRadius.circular(15),
                                          //         boxShadow: AppColors.shadow,
                                          //       ),
                                          //       child: Center(
                                          //         child: Icon(
                                          //           Icons.volume_up,
                                          //           color: AppColors.textColor,
                                          //           size: 20,
                                          //         ),
                                          //       ),
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        filteredTranslations[listIdx]
                                            .description
                                            .toString(),
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              // else if (isLoading) {
                              //   return const Center(
                              //     child: CircularProgressIndicator(
                              //       color: AppColors.green,
                              //     ),
                              //   );
                              // }
                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 300,
                                  child: Lottie.asset(
                                    "assets/empty_animation.json",
                                  ),
                                ),
                              );
                            },
                            childCount: filteredTranslations.length,
                          ),
                        ),
                      if (isBannerAd4Loaded)
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
                      if (isBannerAd4Loaded)
                        SliverToBoxAdapter(
                          child: Container(
                            width: _bannerAd4!.size.width.toDouble(),
                            height: _bannerAd4!.size.height.toDouble(),
                            margin: const EdgeInsets.only(top: 10),
                            child: AdWidget(
                              ad: _bannerAd4!,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 15,
                            bottom: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Commentaries",
                                    style: TextStyle(
                                      color:
                                          AppColors.textColor.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 7,
                                  ),
                                  if (selectedCommentariesFilterIdx != -1)
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.containerColor,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: AppColors.borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          languagesCommentaries[
                                                  selectedCommentariesFilterIdx]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              GestureDetector(
                                onTap: (() {
                                  // log(languages.length.toString());
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: AppColors.transparent,
                                    elevation: 0,
                                    builder: (modalCtx) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          bottom: 15,
                                        ),
                                        padding: const EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                          top: 20,
                                          bottom: 15,
                                        ),
                                        height:
                                            languagesCommentaries.length * 110,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: AppColors.containerColor,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Filters",
                                                  style: TextStyle(
                                                    color: AppColors.textColor
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: (() {
                                                    selectedCommentariesFilterIdx =
                                                        -1;
                                                    setState(() {});
                                                    Navigator.pop(modalCtx);
                                                  }),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 10,
                                                      right: 10,
                                                      top: 5,
                                                      bottom: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .containerColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      boxShadow:
                                                          AppColors.shadow,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          AppColors.mainColor
                                                              .withOpacity(0.3),
                                                          AppColors.mainColor
                                                              .withOpacity(0.5),
                                                          AppColors.mainColor
                                                              .withOpacity(0.7),
                                                          AppColors.mainColor,
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            "Clear",
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .textColor,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Icon(
                                                            Icons.close,
                                                            color: AppColors
                                                                .textColor,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Expanded(
                                              child: ListView.separated(
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return GestureDetector(
                                                    onTap: (() {
                                                      selectedCommentariesFilterIdx =
                                                          index;
                                                      filterCommentaryLanguages(
                                                          index);
                                                      setState(() {});
                                                      Navigator.pop(modalCtx);
                                                    }),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                        top: 5,
                                                        bottom: 5,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 15,
                                                        right: 15,
                                                        top: 10,
                                                        bottom: 10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .containerColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        boxShadow:
                                                            AppColors.shadow,
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.3),
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.5),
                                                            AppColors.mainColor
                                                                .withOpacity(
                                                                    0.7),
                                                            AppColors.mainColor,
                                                          ],
                                                        ),
                                                        border:
                                                            (selectedCommentariesFilterIdx ==
                                                                    index)
                                                                ? Border.all(
                                                                    color: AppColors
                                                                        .textColor,
                                                                  )
                                                                : null,
                                                      ),
                                                      child: Text(
                                                        languagesCommentaries[
                                                                index]
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textColor,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                separatorBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return const SizedBox(
                                                    height: 10,
                                                  );
                                                },
                                                itemCount: languagesCommentaries
                                                    .length,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
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
                                      Icons.filter_list,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      if (selectedCommentariesFilterIdx == -1)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (listContext, listIdx) {
                              if (widget.verseDetails.commentaries.isNotEmpty) {
                                return Container(
                                  width: MediaQuery.of(context).size.width - 30,
                                  margin: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 5,
                                    bottom: 10,
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.containerColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: AppColors.shadow,
                                    gradient: AppColors.gradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        widget.verseDetails
                                            .commentaries[listIdx].authorName
                                            .trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        widget.verseDetails
                                            .commentaries[listIdx].language
                                            .toUpperCase()
                                            .trim(),
                                        style: TextStyle(
                                          color: AppColors.verseCountColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        widget.verseDetails
                                            .commentaries[listIdx].description
                                            .trim(),
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 300,
                                  child: Lottie.asset(
                                    "assets/empty_animation.json",
                                  ),
                                ),
                              );
                            },
                            childCount: widget.verseDetails.commentaries.length,
                          ),
                        ),
                      if (selectedCommentariesFilterIdx != -1)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (listContext, listIdx) {
                              if (filteredCommentaries.isNotEmpty) {
                                return Container(
                                  width: MediaQuery.of(context).size.width - 30,
                                  margin: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 5,
                                    bottom: 10,
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.containerColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: AppColors.shadow,
                                    gradient: AppColors.gradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        filteredCommentaries[listIdx]
                                            .authorName
                                            .trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        filteredCommentaries[listIdx]
                                            .language
                                            .toUpperCase()
                                            .toString(),
                                        style: TextStyle(
                                          color: AppColors.verseCountColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        filteredCommentaries[listIdx]
                                            .description
                                            .trim(),
                                        style: TextStyle(
                                          color: AppColors.textColor
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 300,
                                  child: Lottie.asset(
                                    "assets/empty_animation.json",
                                  ),
                                ),
                              );
                            },
                            childCount: filteredCommentaries.length,
                          ),
                        ),
                    ],
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
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 1.5,
                ),
              ),
      ),
    );
  }
}

class CircleSpacer extends StatelessWidget {
  const CircleSpacer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 5,
        right: 5,
      ),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withOpacity(0.5),
      ),
    );
  }
}
