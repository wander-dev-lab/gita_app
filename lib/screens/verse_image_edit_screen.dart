import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gita_app/styles.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../models/colour_editor_model.dart';
import '../services/storage_service.dart';

class VerseImageEditScreen extends StatefulWidget {
  const VerseImageEditScreen({
    Key? key,
    required this.verse,
    required this.verseEng,
    required this.verseHin,
    required this.chapterNameEng,
    required this.chapterIDEng,
    required this.verseIDEng,
    required this.chapterIDHin,
    required this.chapterIDSan,
    required this.verseIDHin,
    required this.verseIDSan,
    required this.chapterNameSan,
    required this.chapterNameHin,
    required this.verseStringEng,
    required this.verseStringSan,
    required this.verseStringHin,
  }) : super(key: key);

  final String verse,
      verseEng,
      verseHin,
      chapterNameEng,
      chapterNameSan,
      chapterNameHin,
      chapterIDHin,
      chapterIDSan,
      verseIDHin,
      verseIDSan,
      verseStringEng,
      verseStringSan,
      verseStringHin;
  final int chapterIDEng, verseIDEng;

  @override
  State<VerseImageEditScreen> createState() => _VerseImageEditScreenState();
}

class _VerseImageEditScreenState extends State<VerseImageEditScreen> {
  List<String> langs = ["English", "Sanskrit", "Hindi"];
  int currentIdx = 0, currentColorIdx = 0, currentTextColorIdx = 0;
  bool isChanged = true,
      isLoadingTranslation = false,
      isEditorOpened = false,
      isBannerAdLoaded1 = false,
      isBannerAdLoaded2 = false;

  late ScreenshotController _screenshotController;
  BannerAd? _bannerAd, _bannerAd2;

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
      adUnitId: "ca-app-pub-7050103229809241/1401307117",
      listener: BannerAdListener(
        onAdLoaded: ((ad) {
          isBannerAdLoaded1 = true;
          setState(() {});
        }),
        onAdFailedToLoad: ((ad, err) {
          _bannerAd?.dispose();
          isBannerAdLoaded1 = false;
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

  Future<dynamic> colourModal(
      BuildContext context, ColorEditorModel defaultColor) {
    int picColor = defaultColor.picColor;
    int picTextColor = defaultColor.textColor;

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
                          textColor: picTextColor,
                          picColor: picColor,
                        ),
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
            ? isBannerAdLoaded1
                ? 100 + _bannerAd!.size.height.toDouble()
                : 80
            : 0,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            if (isBannerAdLoaded1)
              Container(
                height: isEditorOpened ? 0 : _bannerAd!.size.height.toDouble(),
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(
                  top: 10,
                  bottom: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                ),
                child: Center(
                  child: AdWidget(
                    ad: _bannerAd!,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
              ),
              margin: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
                bottom: 20,
              ),
              height: 50,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: AppColors.textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: (() async {
                  final visitingCard = await _screenshotController.capture();
                  final directory = await getTemporaryDirectory();
                  final path =
                      "${directory.path}/chapter-${widget.chapterIDEng}-verse-${widget.verseIDEng}.png";
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
                onTap: (() {
                  if (currentIdx != 2) {
                    currentIdx++;
                  } else if (currentIdx == 2) {
                    currentIdx = 0;
                  }
                  isChanged = false;
                  setState(() {});
                }),
                child: StreamBuilder(
                  builder: ((ctx, snapshot) {
                    switch (currentIdx) {
                      case 0:
                        return VerseShareWidget(
                          chapterID: widget.chapterIDEng,
                          chapterName: widget.chapterNameEng,
                          verseID: widget.verseIDEng,
                          verse: widget.verseEng,
                          containerColor: AppColors.colorList[currentColorIdx],
                          textColor: AppColors.colorList[currentTextColorIdx],
                        );

                      case 1:
                        return VerseShareWidget(
                          chapterID: int.parse(widget.chapterIDHin),
                          chapterName: widget.chapterNameSan,
                          verseID: int.parse(widget.verseIDHin),
                          verse: widget.verse,
                          containerColor: AppColors.colorList[currentColorIdx],
                          textColor: AppColors.colorList[currentTextColorIdx],
                        );

                      case 2:
                        return VerseShareWidget(
                          chapterID: int.parse(widget.chapterIDHin),
                          chapterName: widget.chapterNameHin,
                          verseID: int.parse(widget.verseIDHin),
                          verse: widget.verseHin,
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
            if (isBannerAdLoaded2)
              Padding(
                padding: const EdgeInsets.only(
                  left: 25,
                  right: 25,
                  top: 10,
                  bottom: 5,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height:
                  isBannerAdLoaded2 ? _bannerAd2!.size.height.toDouble() : 0,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(
                top: 20,
                left: 10,
                right: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.mainColor,
              ),
              child: Center(
                child: AdWidget(
                  ad: _bannerAd2!,
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class VerseShareWidget extends StatelessWidget {
  const VerseShareWidget({
    super.key,
    required this.chapterID,
    required this.chapterName,
    required this.verseID,
    required this.verse,
    required this.containerColor,
    required this.textColor,
  });

  final int chapterID, verseID;
  final String chapterName, verse;
  final Color containerColor, textColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 35,
                height: 35,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    chapterID.toString(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
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
                    "Verse number: $verseID",
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            verse.trim(),
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
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
