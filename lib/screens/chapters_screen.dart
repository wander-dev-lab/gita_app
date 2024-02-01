import 'dart:convert';
import 'dart:developer';

import 'package:animated_list_item/animated_list_item.dart';
import 'package:animations/animations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gita_app/models/chapters_model.dart';
import 'package:gita_app/models/notification_store_model.dart';
import 'package:gita_app/providers/theme_provider.dart';
import 'package:gita_app/screens/lines_selection_screen.dart';
import 'package:gita_app/screens/splash_screen.dart';
import 'package:gita_app/screens/verses_screen.dart';
import 'package:gita_app/services/keys.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';
import 'package:gita_app/utils/snackbar_utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({
    Key? key,
    required this.flutterTts,
    required this.wordIdx,
    required this.scrollController,
  }) : super(key: key);

  final FlutterTts flutterTts;
  final int wordIdx;
  final ScrollController scrollController;

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen>
    with TickerProviderStateMixin {
  List<ChaptersModel> chapters = [];
  List<int> completedChapters = [];
  bool isLoading = false, isFlipped = false, isBannerAdLoaded = false;
  BannerAd? _bannerAd;
  final AdSize _adSize = AdSize.banner;
  // final ScrollController _scrollController = ScrollController();
  String selectedOption = 'System';
  late AnimationController _animationController;
  int? animationIdx;
  bool isAtTop = false;
  bool isAtBottom = false;

  void getUserData() async {
    await fetchChapters();
    await fetchCompletedChapters();
    selectedOption = await JsonStorage.getTheme() ?? "System";
    log(selectedOption);
    setState(() {});
  }

  Future<void> fetchChapters() async {
    isLoading = true;
    setState(() {});

    chapters = await JsonStorage.getChapters();

    if (chapters.isEmpty) {
      http.Response response = await http.get(
        Uri.parse(
          "${Keys.apiBaseChaptersUrl}/?limit=20",
        ),
        headers: {
          'X-RapidAPI-Key':
              '8680f6be21msh8fa7d85b9c5db32p1f561bjsn1d3c8a0210e1',
          'X-RapidAPI-Host': 'bhagavad-gita3.p.rapidapi.com',
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

        chapters = chaptersModelFromJson(
          json.encode(
            jsonList,
          ),
        );
        await JsonStorage.saveChapters(chapters);
        setState(() {});
      }
    }

    // chaptersLength = chapters.length;
    isLoading = false;
    setState(() {});
  }

  Future<void> fetchCompletedChapters() async {
    completedChapters = await JsonStorage.getCompletedChapters();
    setState(() {});
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
  void dispose() {
    _animationController.dispose();
    chapters.clear();
    completedChapters.clear();
    _bannerAd?.dispose();
    // _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getUserData();
    // animationIdx = math.Random().nextInt(animationTypes.length);
    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: 20 * 150,
      ),
      vsync: this,
    );
    _animationController.forward();
    _bannerAd = BannerAd(
      size: _adSize,
      adUnitId: "ca-app-pub-7050103229809241/1506964920",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd?.dispose();
          isBannerAdLoaded = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    )..load();
    // _scrollController.addListener(_checkScrollPosition);
    super.initState();
  }

  void _addCompleteStatus(int chapterId) async {
    await JsonStorage.addCompletedChapter(chapterId);
    ChaptersModel chapter =
        ChaptersModel.fromJson(await JsonStorage.getNextChapter(chapterId));
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
          title: "Continue Your Journey in the Bhagavad Gita",
          body:
              "Namaste! 🕉️ Explore Chapter ${chapter.chapterNumber} in the Bhagavad Gita for profound insights. 📖✨ Continue your spiritual journey now. 🌟📚",
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

    await JsonStorage.setLastCompletedChapter(chapterId);
    await JsonStorage.setLastCompletedChapterNotification(
      NotificationStoreModel(
        id: chapterId,
        notificationId: notificationID,
      ),
    );
    completedChapters = await JsonStorage.getCompletedChapters();
    setState(() {});
  }

  void _deleteCompleteStatus(int chapterId) async {
    await JsonStorage.deleteCompletedChapter(chapterId);
    NotificationStoreModel? notificationStoreModel =
        await JsonStorage.getLastCompletedChapterNotification();
    if (notificationStoreModel != null &&
        notificationStoreModel.id == chapterId) {
      await AwesomeNotifications()
          .cancelSchedule(notificationStoreModel.notificationId);
    }

    completedChapters = await JsonStorage.getCompletedChapters();
    setState(() {});
  }

  bool isValueInList(int value, List<int> integerList) {
    if (integerList.contains(value)) {
      return true; // Value is present in the list
    } else {
      return false; // Value is not present in the list
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedOption == "Light") {
      AppColors.applyBrightness(Brightness.light);
    } else if (selectedOption == "Dark") {
      AppColors.applyBrightness(Brightness.dark);
    } else {
      AppColors.applyBrightness(MediaQuery.platformBrightnessOf(context));
    }
    return Consumer<ThemeProvider>(
      builder: (ctx, provider, child) {
        if (provider.isChanged) {
          if (provider.theme == "Light") {
            AppColors.applyBrightness(Brightness.light);
          } else if (provider.theme == "Dark") {
            AppColors.applyBrightness(Brightness.dark);
          } else if (provider.theme == "System") {
            AppColors.applyBrightness(MediaQuery.platformBrightnessOf(context));
          }
        }

        return RefreshIndicator(
          onRefresh: fetchCompletedChapters,
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: AppColors.scrollPhysics,
            slivers: [
              if (!isLoading && chapters.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (listContext, itemIndex) {
                      if (chapters.isNotEmpty) {
                        return AnimatedListItem(
                          index: itemIndex,
                          length: chapters.length,
                          aniController: _animationController,
                          animationType: AnimationType.fade,
                          child: CupertinoContextMenu.builder(
                              actions: [
                                CupertinoContextMenuAction(
                                  trailingIcon: CupertinoIcons.share,
                                  onPressed: (() {
                                    log(chapters[itemIndex].chapterSummary);

                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (nextCtx) =>
                                            LinesSelectionScreen(
                                          lines: chapters[itemIndex]
                                              .chapterSummary
                                              .replaceAll(
                                                  RegExp(r'\d+\.\s'), '')
                                              .split(RegExp(r'\.\s')),
                                          chapterName: chapters[itemIndex]
                                              .nameTranslated,
                                          chapterID: chapters[itemIndex].id,
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
                                    chapters[itemIndex].id, completedChapters))
                                  CupertinoContextMenuAction(
                                    trailingIcon: Icons.check_circle_outline,
                                    onPressed: (() {
                                      Navigator.pop(context);
                                      _addCompleteStatus(
                                          chapters[itemIndex].id);
                                    }),
                                    child: const Text(
                                      "Complete",
                                      style: TextStyle(
                                        color: AppColors.blackLow,
                                      ),
                                    ),
                                  ),
                                if (isValueInList(
                                    chapters[itemIndex].id, completedChapters))
                                  CupertinoContextMenuAction(
                                    trailingIcon: Icons.cancel_outlined,
                                    onPressed: (() {
                                      Navigator.pop(context);
                                      _deleteCompleteStatus(
                                          chapters[itemIndex].id);
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
                              builder: (BuildContext ctx,
                                  Animation<double> animation) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 130,
                                  width: MediaQuery.of(ctx).size.width - 18,
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
                                    closedBuilder: ((closedCtx, openContainer) {
                                      return GestureDetector(
                                        onTap: openContainer,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FlipCard(
                                              onFlip: (() {
                                                if (!isValueInList(
                                                    chapters[itemIndex].id,
                                                    completedChapters)) {
                                                  _addCompleteStatus(
                                                      chapters[itemIndex].id);
                                                } else {
                                                  _deleteCompleteStatus(
                                                      chapters[itemIndex].id);
                                                }
                                              }),
                                              onFlipDone: ((flipped) {
                                                if (flipped) {
                                                  setState(() {});
                                                }
                                              }),
                                              front: AnimatedContainer(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    width:
                                                        AppColors.borderWidth,
                                                    color: !isValueInList(
                                                            chapters[itemIndex]
                                                                .id,
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
                                                  margin:
                                                      const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.green
                                                        .withOpacity(0.9),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      chapters[itemIndex]
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
                                                            chapters[itemIndex]
                                                                .id,
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
                                                  margin:
                                                      const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.green
                                                        .withOpacity(0.9),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      chapters[itemIndex]
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
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        chapters[itemIndex]
                                                            .nameTranslated,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 17,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 15,
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
                                                            chapters[itemIndex]
                                                                .versesCount
                                                                .toString(),
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .verseCountColor,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  // if (animation.value <= 0.5)
                                                  Text(
                                                    chapters[itemIndex]
                                                        .chapterSummary,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                    openBuilder: ((openCtx, _) {
                                      return VersesScreen(
                                        wordIdx: widget.wordIdx,
                                        flutterTts: widget.flutterTts,
                                        chapter: chapters[itemIndex],
                                        isCompleted: !isValueInList(
                                            chapters[itemIndex].id,
                                            completedChapters),
                                        langIndex: 0,
                                      );
                                    }),
                                  ),
                                );
                              }),
                        );
                      } else if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
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
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.green,
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
        );
      },
    );
  }

  AnimatedListItem buildAnimatedListItem(int itemIndex, BuildContext context) {
    return AnimatedListItem(
      key: UniqueKey(),
      index: itemIndex,
      length: chapters.length,
      aniController: _animationController,
      animationType: AnimationType.fade,
      child: CupertinoContextMenu.builder(
          actions: [
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.share,
              onPressed: (() {
                log(chapters[itemIndex].chapterSummary);

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (nextCtx) => LinesSelectionScreen(
                      lines: chapters[itemIndex]
                          .chapterSummary
                          .replaceAll(RegExp(r'\d+\.\s'), '')
                          .split(RegExp(r'\.\s')),
                      chapterName: chapters[itemIndex].nameTranslated,
                      chapterID: chapters[itemIndex].id,
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
            if (!isValueInList(chapters[itemIndex].id, completedChapters))
              CupertinoContextMenuAction(
                trailingIcon: Icons.check_circle_outline,
                onPressed: (() {
                  Navigator.pop(context);
                  _addCompleteStatus(chapters[itemIndex].id);
                }),
                child: const Text(
                  "Complete",
                  style: TextStyle(
                    color: AppColors.blackLow,
                  ),
                ),
              ),
            if (isValueInList(chapters[itemIndex].id, completedChapters))
              CupertinoContextMenuAction(
                trailingIcon: Icons.cancel_outlined,
                onPressed: (() {
                  Navigator.pop(context);
                  _deleteCompleteStatus(chapters[itemIndex].id);
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
              height: 130,
              width: MediaQuery.of(ctx).size.width - 18,
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
                closedBuilder: ((closedCtx, openContainer) {
                  return GestureDetector(
                    onTap: openContainer,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlipCard(
                          onFlip: (() {
                            if (!isValueInList(
                                chapters[itemIndex].id, completedChapters)) {
                              _addCompleteStatus(chapters[itemIndex].id);
                            } else {
                              _deleteCompleteStatus(chapters[itemIndex].id);
                            }
                          }),
                          onFlipDone: ((flipped) {
                            if (flipped) {
                              setState(() {});
                            }
                          }),
                          front: AnimatedContainer(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: AppColors.borderWidth,
                                color: !isValueInList(chapters[itemIndex].id,
                                        completedChapters)
                                    ? Colors.redAccent
                                    : AppColors.green,
                              ),
                            ),
                            duration: const Duration(milliseconds: 300),
                            transform:
                                Matrix4.rotationY(isFlipped ? 3.14159265 : 0),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  chapters[itemIndex].chapterNumber.toString(),
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
                                color: !isValueInList(chapters[itemIndex].id,
                                        completedChapters)
                                    ? Colors.redAccent
                                    : AppColors.green,
                              ),
                            ),
                            duration: const Duration(milliseconds: 300),
                            transform:
                                Matrix4.rotationY(isFlipped ? 3.14159265 : 0),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  chapters[itemIndex].chapterNumber.toString(),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    chapters[itemIndex].nameTranslated,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Number of Verses: ",
                                        style: TextStyle(
                                          color: AppColors.textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        chapters[itemIndex]
                                            .versesCount
                                            .toString(),
                                        style: TextStyle(
                                          color: AppColors.verseCountColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              // if (animation.value <= 0.5)
                              Text(
                                chapters[itemIndex].chapterSummary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                openBuilder: ((openCtx, _) {
                  return VersesScreen(
                    wordIdx: widget.wordIdx,
                    flutterTts: widget.flutterTts,
                    chapter: chapters[itemIndex],
                    isCompleted: !isValueInList(
                        chapters[itemIndex].id, completedChapters),
                    langIndex: 0,
                  );
                }),
              ),
            );
          }),
    );
  }
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? selectedOption;

  getDetails() async {
    selectedOption = await JsonStorage.getTheme() ?? "System";
    setState(() {});
  }

  @override
  void initState() {
    getDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width / 1.5,
      backgroundColor: AppColors.mainColor,
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                top: 15,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Consumer<ThemeProvider>(
                      builder: (ctx, provider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 15,
                              ),
                              child: Text(
                                "Theme:",
                                style: TextStyle(
                                  color: AppColors.verseCountColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            RadioListTile(
                              activeColor: AppColors.green,
                              value: "Light",
                              groupValue: selectedOption,
                              title: Text(
                                "Light",
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 16,
                                ),
                              ),
                              onChanged: ((val) async {
                                log(val!);
                                selectedOption = val;
                                provider.themeFunc(val);
                                AppColors.applyBrightness(Brightness.light);

                                setState(() {});
                                Navigator.pop(context);
                                // Restart.restartApp();
                              }),
                            ),
                            RadioListTile(
                              activeColor: AppColors.green,
                              value: "Dark",
                              groupValue: selectedOption,
                              title: Text(
                                "Dark",
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 16,
                                ),
                              ),
                              onChanged: ((val) async {
                                log(val!);
                                selectedOption = val;
                                provider.themeFunc(val);

                                setState(() {});
                                Navigator.pop(context);
                                // Restart.restartApp();
                              }),
                            ),
                            RadioListTile(
                              activeColor: AppColors.green,
                              value: "System",
                              groupValue: selectedOption,
                              title: Text(
                                "System",
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 15,
                                ),
                              ),
                              onChanged: ((val) async {
                                log(val!);
                                selectedOption = val;
                                provider.themeFunc(val);

                                setState(() {});
                                Navigator.pop(context);
                                // Restart.restartApp();
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: (() {
                        showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.mainColor,
                            // isDismissible: false,
                            isScrollControlled: false,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            builder: (logoutContext) {
                              return Container(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: 20,
                                  bottom: 20,
                                ),
                                height: 170,
                                child: Column(
                                  children: [
                                    const Text(
                                      "Warning",
                                      style: TextStyle(
                                        letterSpacing: 1.5,
                                        color: AppColors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      "If you logout your all gita progress will be deleted.",
                                      style: TextStyle(
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: (() {
                                            Navigator.pop(logoutContext);
                                          }),
                                          child: const Center(
                                            child: Text("Cancel"),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        TextButton(
                                          onPressed: (() async {
                                            await AwesomeNotifications()
                                                .cancelAll();
                                            await JsonStorage.reset()
                                                .then((cleared) {
                                              if (cleared) {
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (nextCtx) =>
                                                        const SplashScreen(),
                                                  ),
                                                );
                                              } else {
                                                Navigator.pop(logoutContext);
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message:
                                                        "Can't logout now, Try again later!",
                                                    context: context,
                                                  ),
                                                );
                                              }
                                            });
                                          }),
                                          child: const Center(
                                            child: Text("Logout"),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            });
                      }),
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                          top: 15,
                          bottom: 25,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.shadow,
                          gradient: AppColors.gradient,
                        ),
                        child: const Center(
                          child: Text(
                            "Logout",
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.containerColor,
                  gradient: AppColors.gradient,
                  boxShadow: AppColors.shadow,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  splashRadius: 24,
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textColor,
                  ),
                  onPressed: (() {
                    Navigator.pop(context);
                  }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
