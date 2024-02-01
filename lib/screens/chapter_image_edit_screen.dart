import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gita_app/models/colour_editor_model.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/shared_lines_model.dart';

class ChapterImageEditScreen extends StatefulWidget {
  const ChapterImageEditScreen({
    Key? key,
    required this.chapterNameEng,
    required this.chapterIDEng,
    required this.chapterIDHin,
    required this.chapterIDSan,
    required this.chapterNameSan,
    required this.chapterNameHin,
    required this.selectedLines,
  }) : super(key: key);

  final String chapterNameEng,
      chapterNameSan,
      chapterNameHin,
      chapterIDHin,
      chapterIDSan;
  final int chapterIDEng;

  final List<TranslationModel> selectedLines;

  @override
  State<ChapterImageEditScreen> createState() => _ChapterImageEditScreenState();
}

class _ChapterImageEditScreenState extends State<ChapterImageEditScreen> {
  List<String> langs = ["English", "Sanskrit", "Hindi"];
  int currentIdx = 0, currentColorIdx = 0, currentTextColorIdx = 0;
  bool isChanged = true,
      isLoadingTranslation = false,
      isEditorOpened = false,
      isBannerAdLoaded = false,
      isBannerAdLoaded2 = false;
  final gt = GoogleTranslator();
  String translated = "";
  late ScreenshotController _screenshotController;
  BannerAd? _bannerAd, _bannerAd2;

  // Future<String> translateLinesTo(
  //         List<ShareLinesModel> lines, String to) async =>
  //     await gt
  //         .translate(sharedLines(widget.selectedLines), to: to)
  //         .then((value) => value.text);

  String sharedLinesEng(List<TranslationModel> lines) =>
      widget.selectedLines.map((lineModel) => lineModel.eng).join('\n\n');

  String sharedLinesHin(List<TranslationModel> lines) =>
      widget.selectedLines.map((lineModel) => lineModel.hin).join('\n\n');

  String sharedLinesSan(List<TranslationModel> lines) =>
      widget.selectedLines.map((lineModel) => lineModel.san).join('\n\n');

  Future<String> translateTo(String text, String to) async =>
      await gt.translate(text, to: to).then((value) => value.text);

  void getDetails() async {
    String? theme = await JsonStorage.getTheme();
    currentColorIdx = (theme == "Light") ? 2 : 4;
    currentTextColorIdx = 5;
    setState(() {});
  }

  @override
  void initState() {
    getDetails();
    _screenshotController = ScreenshotController();
    _bannerAd = BannerAd(
      size: AdSize.banner,
      // adUnitId: "ca-app-pub-7050103229809241/1401307117",
      adUnitId: "ca-app-pub-7050103229809241/3760711290",
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
    );
    _bannerAd2 = BannerAd(
      size: AdSize.mediumRectangle,
      adUnitId: "ca-app-pub-7050103229809241/5690199626",
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

    _bannerAd?.load();
    _bannerAd2?.load();

    super.initState();
  }

  @override
  void dispose() {
    langs.clear();
    _bannerAd?.dispose();
    _bannerAd2?.dispose();

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
        leading: IconButton(
          onPressed: (() {
            Navigator.pop(context);
          }),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textColor,
          ),
        ),
        title: Column(
          children: [
            Text(
              "Share",
              style: TextStyle(
                color: AppColors.textColor,
              ),
            ),
            Text(
              "${langs[currentIdx]} selected",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (() async {
              isEditorOpened = true;
              setState(() {});
              ColorEditorModel editedColor = await colourModal(
                      context,
                      ColorEditorModel(
                          picColor: currentColorIdx,
                          textColor: currentTextColorIdx)) ??
                  ColorEditorModel(
                      picColor: currentColorIdx,
                      textColor: currentTextColorIdx);
              currentColorIdx = editedColor.picColor;
              currentTextColorIdx = editedColor.textColor;
              isEditorOpened = false;
              setState(() {});
            }),
            child: const Text(
              "Edit",
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(
            width: 15,
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: (!isEditorOpened)
            ? isBannerAdLoaded
                ? 140
                : 80
            : 0,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // if (isBannerAdLoaded)
            //   Container(
            //     height: isEditorOpened ? 0 : _bannerAd!.size.height.toDouble(),
            //     width: MediaQuery.of(context).size.width,
            //     margin: const EdgeInsets.only(
            //       top: 10,
            //       bottom: 5,
            //     ),
            //     decoration: BoxDecoration(
            //       color: AppColors.mainColor,
            //     ),
            //     child: Center(
            //       child: AdWidget(
            //         ad: _bannerAd!,
            //       ),
            //     ),
            //   ),
            AnimatedContainer(
              height: 50,
              width: MediaQuery.of(context).size.width,
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.only(
                left: 5,
                right: 5,
                top: 5,
                bottom: 5,
              ),
              margin: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: (() async {
                  final visitingCard = await _screenshotController.capture();
                  final directory = await getTemporaryDirectory();
                  final path = "${directory.path}/achivie_visiting_card.png";
                  File(path).writeAsBytesSync(visitingCard!);
                  const link = "https://achivie.com";
                  String text = "";
                  switch (currentIdx) {
                    case 0:
                      text =
                          "This is the Chapter number ${widget.chapterIDEng}: ${widget.chapterNameEng}\nInstall now: $link";
                      break;
                    case 1:
                      text =
                          "इति अध्यायसङ्ख्या ${widget.chapterIDSan}: ${widget.chapterNameSan}, Install now: $link";
                      break;
                    case 2:
                      text =
                          "यह अध्याय संख्या है ${widget.chapterIDHin}: ${widget.chapterNameHin}, Install now: $link";
                      break;
                  }

                  await Share.shareXFiles(
                    [XFile(path)],
                    text: text,
                  );
                }),
                child: const Text(
                  "Share",
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: AppColors.scrollPhysics,
        child: Column(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: GestureDetector(
                onTap: (() async {
                  if (currentIdx != 2) {
                    currentIdx++;
                  } else if (currentIdx == 2) {
                    currentIdx = 0;
                  }

                  if (currentIdx == 1) {
                    isLoadingTranslation = true;
                    setState(() {});
                    translated = sharedLinesSan(widget.selectedLines);
                    isLoadingTranslation = false;
                    setState(() {});
                  } else if (currentIdx == 2) {
                    isLoadingTranslation = true;
                    setState(() {});
                    translated = sharedLinesHin(widget.selectedLines);

                    isLoadingTranslation = false;
                    setState(() {});
                  }

                  isChanged = false;
                  setState(() {});
                }),
                child: StreamBuilder(
                  builder: ((ctx, snapshot) {
                    switch (currentIdx) {
                      case 0:
                        return SharableText(
                          chapterID: widget.chapterIDEng,
                          chapterName: widget.chapterNameEng,
                          text: sharedLinesEng(widget.selectedLines),
                          chapterHead: "Chapter number: ${widget.chapterIDEng}",
                          lang: langs[currentIdx],
                          isLoadingTranslation: isLoadingTranslation,
                          containerColor: AppColors.colorList[currentColorIdx],
                          textColor: AppColors.colorList[currentTextColorIdx],
                        );

                      case 1:
                        return SharableText(
                          chapterID: int.parse(widget.chapterIDHin),
                          chapterName: widget.chapterNameSan,
                          text: translated,
                          chapterHead:
                              "अध्याय संख्या : ${int.parse(widget.chapterIDHin)}",
                          lang: langs[currentIdx],
                          isLoadingTranslation: isLoadingTranslation,
                          containerColor: AppColors.colorList[currentColorIdx],
                          textColor: AppColors.colorList[currentTextColorIdx],
                        );

                      case 2:
                        return SharableText(
                          chapterID: int.parse(widget.chapterIDHin),
                          chapterName: widget.chapterNameHin,
                          text: translated,
                          chapterHead:
                              "अध्याय संख्या : ${int.parse(widget.chapterIDHin)}",
                          lang: langs[currentIdx],
                          isLoadingTranslation: isLoadingTranslation,
                          containerColor: AppColors.colorList[currentColorIdx],
                          textColor: AppColors.colorList[currentTextColorIdx],
                        );

                      default:
                        return Container();
                    }
                  }),
                ),
              ),
            ),
            Visibility(
              visible: isChanged,
              child: Text(
                "Tap to change language",
                style: TextStyle(
                  color: AppColors.textColor,
                ),
              ),
            ),
            // if (isBannerAdLoaded2)
            //   Padding(
            //     padding: const EdgeInsets.only(
            //       left: 25,
            //       right: 25,
            //       top: 10,
            //       bottom: 5,
            //     ),
            //     child: Align(
            //       alignment: Alignment.centerLeft,
            //       child: Text(
            //         "Advertisement",
            //         style: TextStyle(
            //           color: AppColors.textColor.withOpacity(0.8),
            //           fontWeight: FontWeight.bold,
            //           fontSize: 16,
            //         ),
            //       ),
            //     ),
            //   ),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 300),
            //   height:
            //       isBannerAdLoaded2 ? _bannerAd2!.size.height.toDouble() : 0,
            //   width: MediaQuery.of(context).size.width,
            //   margin: const EdgeInsets.only(
            //     top: 20,
            //     left: 10,
            //     right: 10,
            //   ),
            //   decoration: BoxDecoration(
            //     color: AppColors.mainColor,
            //   ),
            //   child: Center(
            //     child: AdWidget(
            //       ad: _bannerAd2!,
            //     ),
            //   ),
            // ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> colourModal(
      BuildContext context, ColorEditorModel defaultColor) {
    int picColor = defaultColor.picColor;
    int picTextColor = defaultColor.textColor;
    final ItemScrollController picTextColorController = ItemScrollController();
    final ItemScrollController picColorController = ItemScrollController();

    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      barrierColor: AppColors.transparent,
      backgroundColor: AppColors.mainColor,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(left: 5, right: 5),
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          height: 250,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (() {
                      Navigator.pop(
                        context,
                        ColorEditorModel(
                            textColor: picTextColor, picColor: picColor),
                      );
                    }),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                ),
                child: Text(
                  "Select Picture Colour",
                  style: TextStyle(
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: ScrollablePositionedList.separated(
                  itemScrollController: picColorController,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: ((listCtx, idx) => GestureDetector(
                        onTap: (() {
                          Navigator.pop(
                              context,
                              ColorEditorModel(
                                  textColor: picTextColor, picColor: idx));
                          setState(() {
                            picColor = idx;
                          });
                        }),
                        child: AnimatedContainer(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.colorList[idx],
                            border: Border.all(
                              color: AppColors.textColor,
                              width: (defaultColor.picColor == idx) ? 1.5 : 0.5,
                            ),
                          ),
                          duration: const Duration(
                            milliseconds: 300,
                          ),
                        ),
                      )),
                  separatorBuilder: ((listCtx, idx) => const SizedBox(
                        width: 15,
                      )),
                  itemCount: AppColors.colorList.length,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                ),
                child: Text(
                  "Select Picture Text Colour",
                  style: TextStyle(
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: ScrollablePositionedList.separated(
                  itemScrollController: picTextColorController,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: ((listCtx, idx) => GestureDetector(
                        onTap: (() {
                          Navigator.pop(
                              context,
                              ColorEditorModel(
                                  textColor: idx, picColor: picColor));
                          setState(() {
                            picTextColor = idx;
                          });
                        }),
                        child: AnimatedContainer(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.colorList[idx],
                            border: Border.all(
                              color: AppColors.textColor,
                              width:
                                  (defaultColor.textColor == idx) ? 1.5 : 0.5,
                            ),
                          ),
                          duration: const Duration(
                            milliseconds: 300,
                          ),
                        ),
                      )),
                  separatorBuilder: ((listCtx, idx) => const SizedBox(
                        width: 15,
                      )),
                  itemCount: AppColors.colorList.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SharableText extends StatelessWidget {
  const SharableText({
    super.key,
    required this.chapterID,
    required this.chapterName,
    required this.text,
    required this.chapterHead,
    required this.lang,
    required this.isLoadingTranslation,
    required this.containerColor,
    required this.textColor,
  });

  final int chapterID;
  final String chapterName, text, chapterHead, lang;
  final bool isLoadingTranslation;
  final Color containerColor, textColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 20,
        bottom: 20,
      ),
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 15,
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: isLoadingTranslation
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 1.5,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Translating to $lang",
                  style: TextStyle(
                    color: AppColors.textColor,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 120,
                      child: Text(
                        chapterName.trim(),
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      chapterHead,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  text,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Bhagavad Gita",
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          "Powered By Achivie",
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        "assets/logo-achivie-no-bg.png",
                      ),
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
