import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gita_app/models/chapter_share_model.dart';
import 'package:gita_app/models/share_lines_model.dart';
import 'package:gita_app/screens/chapter_image_edit_screen.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/shared_lines_model.dart';
import '../utils/snackbar_utils.dart';

class LinesSelectionScreen extends StatefulWidget {
  const LinesSelectionScreen({
    Key? key,
    required this.lines,
    required this.chapterName,
    required this.chapterID,
  }) : super(key: key);

  final List<String> lines;
  final String chapterName;
  final int chapterID;

  @override
  State<LinesSelectionScreen> createState() => _LinesSelectionScreenState();
}

class _LinesSelectionScreenState extends State<LinesSelectionScreen> {
  List<ShareLinesModel> selectedLines = [];
  BannerAd? _bannerAd;
  bool isBannerAdLoaded = false, isLoadingTranslation = false;
  String loadingStatus = "Loading...";
  final gt = GoogleTranslator();
  AdSize adSize = AdSize.fullBanner;
  final ScrollController _scrollController = ScrollController();
  bool isAtTop = false;
  bool isAtBottom = false;

  bool isIdPresent(int id) {
    return selectedLines.any((line) => line.id == id);
  }

  void addId(int id, String lineText) {
    if (selectedLines.length == 4) {
      if (id == selectedLines.first.id - 1) {
        // If the given id is one less than the first id, remove the last element.
        deleteId(selectedLines.last.id);
      } else if (id == selectedLines.last.id + 1) {
        // If the given id is one more than the last id, remove the first element.
        deleteId(selectedLines.first.id);
      }
    }

    selectedLines.add(ShareLinesModel(id: id, line: lineText));
    selectedLines.sort((a, b) => a.id.compareTo(b.id));
    setState(() {});
  }

  void deleteId(int id) {
    selectedLines.removeWhere((line) => line.id == id);
  }

  bool isIdAddable(int id) {
    if (selectedLines.isEmpty) {
      return true; // If the list is empty, any ID can be added.
    }

    // Check if the last added ID is consecutive and the list size is less than 4.
    int lastAddedId = selectedLines.last.id;
    int firstAddedId = selectedLines.first.id;
    return ((id == lastAddedId + 1) || id == firstAddedId - 1) &&
        (selectedLines.length < 4);
  }

  Future<String> translateTo(String text, String to) async =>
      await gt.translate(text, to: to).then((value) => value.text);

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
    _bannerAd = BannerAd(
      size: adSize,
      adUnitId: "ca-app-pub-7050103229809241/7192997332",
      listener: AdManagerBannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, _) {
          _bannerAd?.dispose();
          isBannerAdLoaded = false;
          setState(() {});
        }),
      ),
      request: const AdRequest(),
    )..load();
    _scrollController.addListener(_checkScrollPosition);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    selectedLines.clear();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Select Lines",
              style: TextStyle(
                color: AppColors.textColor,
              ),
            ),
            if (selectedLines.isNotEmpty && selectedLines.length != 4)
              Text(
                "${selectedLines.length.toString()} selected",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 12,
                ),
              ),
            if (selectedLines.length == 4)
              Text(
                "Max lines selected",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          onPressed: (() {
            Navigator.pop(context);
          }),
          icon: Icon(
            Icons.keyboard_backspace,
            color: AppColors.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: (() async {
              if (selectedLines.isNotEmpty) {
                isLoadingTranslation = true;
                setState(() {});
                bool chapterShareDetailsFetched = false, linesFetched = false;
                String chapterIDHin = "",
                    chapterIDSan = "",
                    chapterNameHin = "",
                    chapterNameSan = "";
                List<TranslationModel> sharedLines = [];

                ChapterShareModel? chapterShareModel =
                    await JsonStorage.getChapterShareDetails(widget.chapterID);
                if (chapterShareModel != null) {
                  chapterIDHin = chapterShareModel.chapterIdHin;
                  chapterIDSan = chapterShareModel.chapterIdSan;
                  chapterNameHin = chapterShareModel.chapterNameHin;
                  chapterNameSan = chapterShareModel.chapterNameSan;
                  log("from storage chapterShareModel");
                  chapterShareDetailsFetched = true;
                } else {
                  chapterIDHin =
                      await translateTo(widget.chapterID.toString(), 'hi');
                  chapterIDSan =
                      await translateTo(widget.chapterID.toString(), 'sa');
                  chapterNameHin =
                      await translateTo(widget.chapterName.toString(), 'hi');
                  chapterNameSan =
                      await translateTo(widget.chapterName.toString(), 'sa');
                  await JsonStorage.setChapterShareDetails(
                    ChapterShareModel(
                      chapterIdHin: chapterIDHin,
                      chapterIdSan: chapterIDSan,
                      chapterNameHin: chapterNameHin,
                      chapterNameSan: chapterNameSan,
                    ),
                    widget.chapterID,
                  );
                  log("from network chapterShareModel");
                  chapterShareDetailsFetched = true;
                }

                TranslationModel? sharedLinesModel;
                for (ShareLinesModel line in selectedLines) {
                  sharedLinesModel = await JsonStorage.getSharedLines(line.id);
                  if (sharedLinesModel != null) {
                    sharedLines.add(sharedLinesModel);
                    log("from storage sharedLinesModel");
                  } else {
                    await JsonStorage.setSharedLines(
                      ShareLinesModel(line: line.line, id: line.id),
                    );
                    sharedLinesModel =
                        await JsonStorage.getSharedLines(line.id);
                    sharedLines.add(sharedLinesModel!);
                    log("from network sharedLinesModel");
                  }
                }

                if (selectedLines.length == sharedLines.length) {
                  linesFetched = true;
                }

                // String chapterNameSan =
                if (chapterShareDetailsFetched && linesFetched) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (editCtx) => ChapterImageEditScreen(
                        chapterNameEng: widget.chapterName,
                        chapterIDEng: widget.chapterID,
                        chapterIDHin: chapterIDHin,
                        chapterIDSan: chapterIDSan,
                        chapterNameSan: chapterNameSan,
                        chapterNameHin: chapterNameHin,
                        selectedLines: sharedLines,
                      ),
                    ),
                  ).whenComplete(() {
                    isLoadingTranslation = false;
                    setState(() {});
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppSnackbar().customizedAppSnackbar(
                      message: "Something went wrong",
                      context: context,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppSnackbar().customizedAppSnackbar(
                    message: "Please select lines you want to share",
                    context: context,
                  ),
                );
              }
            }),
            child: const Text(
              "Next",
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(
            width: 15,
          ),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.decelerate,
        width: _bannerAd!.size.width.toDouble(),
        height: isBannerAdLoaded ? adSize.height.toDouble() : 0,
        child: AdWidget(ad: _bannerAd!),
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: AppColors.mainColor,
            ),
            duration: const Duration(milliseconds: 400),
            child: ListView.separated(
              controller: _scrollController,
              physics: AppColors.scrollPhysics,
              itemCount: widget.lines.length,
              itemBuilder: (listCtx, listIdx) {
                return GestureDetector(
                  onTap: (() {
                    if (!isIdPresent(listIdx)) {
                      if (isIdAddable(listIdx)) {
                        addId(listIdx, widget.lines[listIdx]);
                        setState(() {});
                      } else {
                        selectedLines.clear();
                        addId(listIdx, widget.lines[listIdx]);
                        setState(() {});
                      }
                    } else {
                      deleteId(listIdx);
                      setState(() {});
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                    ),
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 20,
                      bottom: 20,
                    ),
                    decoration: BoxDecoration(
                      color: selectedLines.isNotEmpty
                          ? isIdPresent(listIdx)
                              ? AppColors.textColor.withOpacity(0.2)
                              : isIdAddable(listIdx)
                                  ? AppColors.textColor.withOpacity(0.05)
                                  : null
                          : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        widget.lines[listIdx].trim(),
                        style: TextStyle(
                          color: AppColors.textColor,
                          height: 1.7,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return AnimatedContainer(
                  height: selectedLines.isNotEmpty ? 20 : 0,
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                );
              },
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.green,
                      strokeWidth: 1.5,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      loadingStatus,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
