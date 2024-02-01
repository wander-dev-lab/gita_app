import 'dart:developer';

import 'package:flutter/material.dart';

class AppColors {
  static const orange = Colors.orange;
  static const gold = Color(0xFFF2CD5C);
  static const goldDark = Color(0xFFF2921D);
  static const diamond = Colors.lightBlue;
  static const diamondDark = Colors.blueAccent;
  static const grey = Colors.grey;
  static ScrollPhysics scrollPhysics = const BouncingScrollPhysics();
  static Color mainColor = const Color(0xFF272A35);
  static Color mainColorLight = const Color(0xFF292F3F);
  static Color secondaryColor = const Color(0xFF373E4E);
  static Color textColor = Colors.white;
  static double borderWidth = 1;
  static Color verseCountColor = Colors.yellow;
  static Color containerColor = mainColorLight;
  static Color borderColor = white;
  static const white = Colors.white;
  static const transparent = Colors.transparent;
  static const green = Colors.greenAccent;
  static const yellow = Colors.yellow;
  static const red = Colors.red;
  static List<Color> colorList = [
    const Color(0xFF272A35),
    const Color(0xFFF2CD5C),
    const Color(0xFFF2921D),
    const Color(0xFF292F3F),
    const Color(0xFF373E4E),
    Colors.white,
    Colors.black,
    Colors.blue,
    Colors.blueAccent,
    Colors.blueGrey,
    Colors.brown,
    Colors.cyan,
    Colors.cyanAccent,
    Colors.deepOrange,
    Colors.deepOrangeAccent,
    Colors.deepPurple,
    Colors.deepPurpleAccent,
    Colors.green,
    Colors.greenAccent,
    Colors.grey,
    Colors.indigo,
    Colors.indigoAccent,
    Colors.lightBlue,
    Colors.lightBlueAccent,
    Colors.lightGreen,
    Colors.lightGreenAccent,
    Colors.lime,
    Colors.limeAccent,
    Colors.orange,
    Colors.orangeAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.purple,
    Colors.purpleAccent,
    Colors.red,
    Colors.redAccent,
    Colors.teal,
    Colors.tealAccent,
    Colors.yellow,
    Colors.yellowAccent,
  ];
  static Gradient? gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.mainColor.withOpacity(0.3),
      AppColors.mainColor.withOpacity(0.5),
      AppColors.mainColor.withOpacity(0.7),
      AppColors.mainColor,
    ],
  );
  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      spreadRadius: 1,
      blurRadius: 15,
      offset: const Offset(1, 5),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      offset: const Offset(-1, 0),
    ),
  ];
  static final LinearGradient customGlassIconButtonGradient = LinearGradient(
    colors: [
      AppColors.white.withOpacity(0.1),
      AppColors.white.withOpacity(0.3),
    ],
  );
  static final LinearGradient customGlassButtonGradient = LinearGradient(
    colors: [
      AppColors.mainColor.withOpacity(0.3),
      AppColors.mainColor.withOpacity(0.5),
    ],
  );
  static const LinearGradient customGlassButtonTransparentGradient =
      LinearGradient(
    colors: [
      AppColors.transparent,
      AppColors.transparent,
    ],
  );
  static final LinearGradient customGlassIconButtonBorderGradient =
      LinearGradient(
    colors: [
      AppColors.white.withOpacity(0.3),
      AppColors.white.withOpacity(0.5),
    ],
  );
  static const blackLow = Colors.black;
  static TextStyle headingTextStyle = TextStyle(
    color: AppColors.textColor,
    overflow: TextOverflow.fade,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 3,
  );
  static final TextStyle subHeadingTextStyle = TextStyle(
    color: AppColors.textColor.withOpacity(0.7),
    fontSize: 13,
  );

  static void applyBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      log("appying light mode");
      mainColor = Colors.white;
      mainColorLight = Colors.lightBlueAccent;
      secondaryColor = Colors.lightBlue;
      textColor = Colors.black;
      verseCountColor = Colors.greenAccent;
      borderWidth = 2;
      shadow = [
        BoxShadow(
          color: mainColorLight.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 15,
          offset: const Offset(1, 5),
        ),
        BoxShadow(
          color: mainColorLight.withOpacity(0.5),
          offset: const Offset(-1, 0),
        ),
      ];
      gradient = null;
      containerColor = white;
      borderColor = mainColorLight;
    } else {
      log("appying dark mode");
      mainColor = const Color(0xFF272A35);
      mainColorLight = const Color(0xFF292F3F);
      secondaryColor = const Color(0xFF373E4E);
      textColor = Colors.white;
      verseCountColor = Colors.yellow;
      borderWidth = 1;
      shadow = [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 15,
          offset: const Offset(1, 5),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(-1, 0),
        ),
      ];
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.mainColor.withOpacity(0.3),
          AppColors.mainColor.withOpacity(0.5),
          AppColors.mainColor.withOpacity(0.7),
          AppColors.mainColor,
        ],
      );
      containerColor = mainColorLight;
      borderColor = white;
    }
  }
}
