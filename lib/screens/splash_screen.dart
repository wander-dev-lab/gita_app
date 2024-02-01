import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gita_app/screens/main_screen.dart';
import 'package:gita_app/screens/sign_screen.dart';
import 'package:gita_app/styles.dart';

import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String selectedOption = '';
  late AnimationController animationController;
  late Animation<double> _animation;
  bool loggedIn = false;
  int completedChaptersLength = 0;

  void getDetails() async {
    selectedOption = await JsonStorage.getTheme() ?? "System";
    loggedIn = await JsonStorage.getLoginStatus();
    List<int> chapters = await JsonStorage.getCompletedChapters();
    completedChaptersLength = chapters.length;
    setState(() {});
  }

  @override
  void initState() {
    getDetails();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(animationController)
      ..addListener(() {
        setState(() {});
      });
    animationController.forward(); // Start the animation

    Timer(
      const Duration(seconds: 2),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => loggedIn
                ? MainScreen(
                    initialIndex: (completedChaptersLength > 0) ? 0 : 1,
                  )
                : const SignUpScreen(),
          ),
        );
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedOption == "Light") {
      AppColors.applyBrightness(Brightness.light);
    } else if (selectedOption == "Dark") {
      AppColors.applyBrightness(Brightness.dark);
    } else if (selectedOption == "System") {
      AppColors.applyBrightness(MediaQuery.platformBrightnessOf(context));
    }
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 20,
          ),
          Column(
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  "assets/logo_no_bg.png",
                  scale: 2,
                  opacity: _animation,
                ),
              ),
              Center(
                child: Text(
                  "Bhagavad Gita",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 45,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Image.asset(
                      "assets/logo-achivie-no-bg.png",
                      scale: 2,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Powered by",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Achivie",
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.5),
                        fontSize: 30,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
