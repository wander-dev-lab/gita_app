import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:gita_app/models/user_login_model.dart';
import 'package:gita_app/screens/main_screen.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/profession_model.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../services/keys.dart';
import '../styles.dart';
import '../utils/snackbar_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // int signStatus = 0;
  bool isLoading = false;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _desController;
  late TextEditingController _passController;
  late TextEditingController _forgotPassController;
  late TextEditingController _passConfirmController;
  late TextEditingController _otpController;
  late TextEditingController _othersProfessionController;
  late FlipCardController _flipCardController;
  bool visibility = true;
  bool visibility2 = true;
  bool selected = false;
  bool signUpPressed = false;
  int signPage = 0;
  // PackageInfo? packageInfo;
  String resetToken = "", uid = "";
  File? selectedImage;
  String _value = "0";
  String profession = "";
  String verificationToken = "";
  String selectedOption = '';
  int otp = 0, containerHeight = 400, currentStep = 0;
  static const List<ProfessionModel> professionList = <ProfessionModel>[
    ProfessionModel(
      id: "0",
      label: "Choose Your Profession",
    ),
    ProfessionModel(
      id: "1",
      label: "Graduate",
    ),
    ProfessionModel(
      id: "2",
      label: "Under-Graduate",
    ),
    ProfessionModel(
      id: "3",
      label: "Post-Graduate",
    ),
    ProfessionModel(
      id: "4",
      label: "IT-Employee",
    ),
    ProfessionModel(
      id: "5",
      label: "Entrepreneur",
    ),
    ProfessionModel(
      id: "6",
      label: "Youtuber",
    ),
    ProfessionModel(
      id: "7",
      label: "Freelancer",
    ),
    ProfessionModel(
      id: "8",
      label: "Trader",
    ),
    ProfessionModel(
      id: "9",
      label: "Developer",
    ),
    ProfessionModel(
      id: "10",
      label: "Content Creator",
    ),
    ProfessionModel(
      id: "11",
      label: "Teacher",
    ),
    ProfessionModel(
      id: "12",
      label: "Govt-Employee",
    ),
    ProfessionModel(
      id: "13",
      label: "Private-Employee",
    ),
    ProfessionModel(
      id: "14",
      label: "Professor",
    ),
    ProfessionModel(
      id: "15",
      label: "Doctor",
    ),
    ProfessionModel(
      id: "16",
      label: "Engineer",
    ),
    ProfessionModel(
      id: "17",
      label: "Others",
    ),
  ];

  @override
  void initState() {
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _passController = TextEditingController();
    _forgotPassController = TextEditingController();
    _passConfirmController = TextEditingController();
    _desController = TextEditingController();
    _otpController = TextEditingController();
    _othersProfessionController = TextEditingController();
    _flipCardController = FlipCardController();

    // getAppDetails();

    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passConfirmController.dispose();
    _forgotPassController.dispose();
    _passController.dispose();
    _desController.dispose();
    _otpController.dispose();
    _othersProfessionController.dispose();
    professionList.clear();
    super.dispose();
  }

  void getDetails() async {
    selectedOption = await JsonStorage.getTheme() ?? "System";
    setState(() {});
  }

  bool isStrongPassword(String input) {
    // Check if the input string is at least 8 characters long
    if (input.length < 8) {
      return false;
    }

    // Check if the input contains at least one special character, one number,
    // one uppercase letter, and one lowercase letter
    final specialChars = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    final hasSpecialChar = specialChars.hasMatch(input);

    final numbers = RegExp(r'[0-9]');
    final hasNumber = numbers.hasMatch(input);

    final lowercase = RegExp(r'[a-z]');
    final hasLowercase = lowercase.hasMatch(input);

    final uppercase = RegExp(r'[A-Z]');
    final hasUppercase = uppercase.hasMatch(input);

    return hasSpecialChar && hasNumber && hasLowercase && hasUppercase;
  }

  @override
  Widget build(BuildContext context) {
    // log(_flipCardController.state?.isFront.toString() ?? "False");
    // SystemChrome.setSystemUIOverlayStyle(
    //   const SystemUiOverlayStyle(
    //     statusBarBrightness: Brightness.light,
    //   ),
    // );
    if (selectedOption == "Light") {
      AppColors.applyBrightness(Brightness.light);
    } else if (selectedOption == "Dark") {
      AppColors.applyBrightness(Brightness.dark);
    } else if (selectedOption == "System") {
      AppColors.applyBrightness(MediaQuery.platformBrightnessOf(context));
    }
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Padding(
        padding: const EdgeInsets.only(
          top: 30,
        ),
        child: Consumer<AllAppProviders>(
          builder: (allAppProvidersContext, allAppProvidersProvider,
              allAppProvidersChild) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 30,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
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
                      ),
                      Text(
                        (_flipCardController.state == null)
                            ? "Login"
                            : (_flipCardController.state?.isFront ?? false)
                                ? "Login"
                                : "Register",
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: FlipCard(
                    direction: FlipDirection.HORIZONTAL,
                    controller: _flipCardController,
                    front: SizedBox(
                      width: size.width,
                      child: Column(
                        children: [
                          //SIGN IN
                          AuthTextField(
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            hintText: "Email",
                            keyboard: TextInputType.emailAddress,
                            isPassField: false,
                            isPassConfirmField: false,
                            isEmailField: true,
                            pageIndex: signPage,
                            // formKey: signInFormKey,
                          ),
                          AuthTextField(
                            icon: Icons.security_outlined,
                            controller: _passController,
                            hintText: "Password",
                            keyboard: TextInputType.visiblePassword,
                            isPassField: true,
                            isPassConfirmField: false,
                            isEmailField: false,
                            pageIndex: signPage,
                            // formKey: signInFormKey,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (() async {
                                  if (_emailController.text.isNotEmpty) {
                                    allAppProvidersProvider.isLoadingFunc(true);

                                    http.Response response = await http.post(
                                      Uri.parse(
                                        "${Keys.apiUsersBaseUrl}/forgotPass/${_emailController.text.trim()}",
                                      ),
                                      headers: {
                                        "content-type": "application/json",
                                      },
                                    );

                                    Map<String, dynamic> responseJson =
                                        jsonDecode(response.body);

                                    if (response.statusCode == 200) {
                                      Map<String, dynamic> responseJson =
                                          jsonDecode(response.body);
                                      log(responseJson.toString());

                                      if (responseJson["success"]) {
                                        JsonStorage.setUsrResetToken(
                                            responseJson["token"]);

                                        resetToken = responseJson["token"];
                                        uid = responseJson["uid"];

                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        setState(() {
                                          signPage = 2;
                                        });
                                        _forgotPassController.clear();

                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson[Keys.message],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      } else {
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson[Keys.message],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      }
                                    } else {
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);
                                      ScaffoldMessenger.of(
                                              allAppProvidersContext)
                                          .showSnackBar(
                                        AppSnackbar().customizedAppSnackbar(
                                          message: responseJson[Keys.message],
                                          context: allAppProvidersContext,
                                        ),
                                      );
                                    }
                                  } else {
                                    allAppProvidersProvider
                                        .isLoadingFunc(false);
                                    ScaffoldMessenger.of(allAppProvidersContext)
                                        .showSnackBar(
                                      AppSnackbar().customizedAppSnackbar(
                                        message:
                                            "Please give your registered email",
                                        context: allAppProvidersContext,
                                      ),
                                    );
                                  }
                                }),
                                child: Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              left: 15,
                              right: 15,
                              bottom: 10,
                            ),
                            child: (allAppProvidersProvider.isLoading)
                                ? Container(
                                    height: 50,
                                    width: size.width / 2,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: AppColors.shadow,
                                      gradient: AppColors.gradient,
                                    ),
                                    child: Center(
                                      child: Lottie.asset(
                                        "assets/loading-animation.json",
                                        width: 100,
                                        height: 50,
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: (() async {
                                      allAppProvidersProvider
                                          .isLoadingFunc(true);
                                      const CircularProgressIndicator(
                                        backgroundColor: AppColors.green,
                                      );
                                      if (_emailController.text.isNotEmpty &&
                                          _passController.text.isNotEmpty) {
                                        // EmailPassAuthServices()
                                        //     .emailPassSignIn(
                                        //   email: _emailController.text
                                        //       .trim(),
                                        //   pass:
                                        //       _passController.text.trim(),
                                        //   context: allAppProvidersContext,
                                        // );

                                        // String token =
                                        //     await StorageServices
                                        //         .getUsrToken();

                                        String? notificationToken =
                                            await FirebaseMessaging.instance
                                                .getToken();

                                        // log(notificationToken!);

                                        http.Response response =
                                            await http.post(
                                          Uri.parse(
                                              "${Keys.apiUsersBaseUrl}/login"),
                                          headers: {
                                            "content-type": "application/json",
                                            // 'Authorization':
                                            //     'Bearer $token',
                                          },
                                          body: jsonEncode({
                                            Keys.uid: _emailController.text
                                                .trim()
                                                .split('@')[0],
                                            Keys.usrPassword:
                                                _passController.text.trim(),
                                            Keys.usrEmail:
                                                _emailController.text.trim(),
                                            Keys.notificationToken:
                                                notificationToken,
                                          }),
                                        );

                                        // log(response.body);

                                        if (response.statusCode == 200) {
                                          Map<String, dynamic> responseJson =
                                              jsonDecode(response.body);

                                          if (responseJson["success"]) {
                                            // UserModel userModel =
                                            //     userModelFromJson(
                                            //   jsonEncode(response.body),
                                            // );
                                            UserLoginModel userModel =
                                                userLoginModelFromJson(
                                                    response.body);
                                            await JsonStorage.setUsrToken(
                                                userModel.token);

                                            await JsonStorage.setLoginStatus(
                                                true);

                                            await JsonStorage.saveUsrData(
                                                    userModel)
                                                .then(
                                              (value) {
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                return Navigator
                                                    .pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (nextCtx) =>
                                                        const MainScreen(
                                                      initialIndex: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                          // log(responseJson.toString());

                                          // if (responseJson["success"]) {
                                          //   UserModel userModel =
                                          //       userModelFromJson(
                                          //           response.body);
                                          //   await JsonStorage.saveUsrData(
                                          //       userModel);
                                          //   await JsonStorage.setUsrToken(
                                          //       userModel.token);
                                          //
                                          //   Navigator.pushReplacement(
                                          //     context,
                                          //     MaterialPageRoute(
                                          //       builder: (nextCtx) =>
                                          //           MainScreen(),
                                          //     ),
                                          //   );
                                          // }
                                        }

                                        if (response.statusCode == 403) {
                                          Map<String, dynamic> responseJson =
                                              jsonDecode(response.body);
                                          signPage = 4;
                                          verificationToken =
                                              responseJson["verificationToken"];
                                          otp = responseJson["otp"];
                                          setState(() {});

                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message:
                                                  responseJson[Keys.message],
                                              context: allAppProvidersContext,
                                            ),
                                          );

                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                        }

                                        if (response.statusCode == 404) {
                                          Map<String, dynamic> responseJson =
                                              jsonDecode(response.body);
                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message:
                                                  responseJson[Keys.message],
                                              context: allAppProvidersContext,
                                            ),
                                          );

                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                        }
                                      } else {
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message:
                                                "Please fill the fields correctly",
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      }
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);
                                    }),
                                    child: Container(
                                      height: 50,
                                      width: size.width / 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: AppColors.shadow,
                                        gradient: AppColors.gradient,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Login",
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have any account?",
                                style: TextStyle(
                                  color: AppColors.textColor.withOpacity(0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: (() {
                                  _flipCardController.state?.toggleCard();
                                  allAppProvidersProvider.isLoadingFunc(false);
                                  _emailController.clear();
                                  _passController.clear();
                                }),
                                child: const Text(
                                  "SignUp",
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (signPage == 2)
                            AuthTextField(
                              controller: _forgotPassController,
                              hintText: "New Password",
                              keyboard: TextInputType.visiblePassword,
                              isPassField: true,
                              isEmailField: false,
                              isPassConfirmField: false,
                              icon: Icons.password,
                              pageIndex: 2,
                            ),
                          if (signPage == 2)
                            AuthTextField(
                              controller: _passConfirmController,
                              hintText: "Confirm Password",
                              keyboard: TextInputType.visiblePassword,
                              isPassField: false,
                              isEmailField: false,
                              isPassConfirmField: true,
                              icon: Icons.password,
                              pageIndex: 2,
                            ),

                          if (signPage == 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: (allAppProvidersProvider.isLoading)
                                  ? Container(
                                      height: 50,
                                      width: size.width / 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.blackLow
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Lottie.asset(
                                          "assets/loading-animation.json",
                                          width: 100,
                                          height: 50,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          onPressed: (() async {
                                            allAppProvidersProvider
                                                .isLoadingFunc(true);

                                            http.Response response =
                                                await http.post(
                                              Uri.parse(
                                                "${Keys.apiUsersBaseUrl}/cancelResetPass/$resetToken/$uid",
                                              ),
                                              headers: {
                                                "content-type":
                                                    "application/json",
                                              },
                                            );

                                            if (response.statusCode == 200) {
                                              Map<String, dynamic>
                                                  responseJson =
                                                  jsonDecode(response.body);

                                              log(responseJson.toString());
                                              if (responseJson["success"]) {
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message: responseJson[
                                                        Keys.message],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );

                                                setState(() {
                                                  signPage = 1;
                                                });
                                                _passController.clear();
                                                _passConfirmController.clear();
                                              } else {
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message: responseJson[
                                                        Keys.message],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              }
                                            } else {
                                              ScaffoldMessenger.of(
                                                      allAppProvidersContext)
                                                  .showSnackBar(
                                                AppSnackbar()
                                                    .customizedAppSnackbar(
                                                  message:
                                                      "Something went wrong, please try after sometime",
                                                  context:
                                                      allAppProvidersContext,
                                                ),
                                              );
                                            }

                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                          }),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: (() async {
                                            allAppProvidersProvider
                                                .isLoadingFunc(true);
                                            if (_forgotPassController
                                                    .text.isNotEmpty &&
                                                _passConfirmController
                                                    .text.isNotEmpty &&
                                                _forgotPassController.text ==
                                                    _passConfirmController
                                                        .text) {
                                              // log(uid);
                                              // log(resetToken);
                                              http.Response response =
                                                  await http.post(
                                                Uri.parse(
                                                  "${Keys.apiUsersBaseUrl}/updateUserPassword",
                                                ),
                                                headers: {
                                                  "content-type":
                                                      "application/json",
                                                },
                                                body: jsonEncode({
                                                  "usrPassword":
                                                      _forgotPassController.text
                                                          .trim(),
                                                  "resetToken": resetToken,
                                                  Keys.usrEmail:
                                                      _emailController.text
                                                          .trim(),
                                                  Keys.uid: uid,
                                                }),
                                              );

                                              if (response.statusCode == 200) {
                                                Map<String, dynamic>
                                                    responseJson =
                                                    jsonDecode(response.body);

                                                log(responseJson.toString());
                                                if (responseJson["success"]) {
                                                  setState(() {
                                                    signPage = 1;
                                                  });
                                                  ScaffoldMessenger.of(
                                                          allAppProvidersContext)
                                                      .showSnackBar(
                                                    AppSnackbar()
                                                        .customizedAppSnackbar(
                                                      message:
                                                          "${responseJson[Keys.message]}\nTry to login",
                                                      context:
                                                          allAppProvidersContext,
                                                    ),
                                                  );
                                                  _passController.clear();
                                                  _passConfirmController
                                                      .clear();
                                                  allAppProvidersProvider
                                                      .isLoadingFunc(false);
                                                } else {
                                                  allAppProvidersProvider
                                                      .isLoadingFunc(false);
                                                  ScaffoldMessenger.of(
                                                          allAppProvidersContext)
                                                      .showSnackBar(
                                                    AppSnackbar()
                                                        .customizedAppSnackbar(
                                                      message: responseJson[
                                                          Keys.message],
                                                      context:
                                                          allAppProvidersContext,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message: response.statusCode
                                                        .toString(),
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              }

                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);
                                            } else {
                                              ScaffoldMessenger.of(
                                                      allAppProvidersContext)
                                                  .showSnackBar(
                                                AppSnackbar()
                                                    .customizedAppSnackbar(
                                                  message:
                                                      "Please fill the fields correctly",
                                                  context:
                                                      allAppProvidersContext,
                                                ),
                                              );
                                            }

                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                          }),
                                          child: Text(
                                            "Submit",
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                          if (signPage == 4)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 25,
                                  top: 30,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "OTP Verification",
                                      style: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Please enter the OTP send to ${_emailController.text.trim()}",
                                      style: TextStyle(
                                        color: AppColors.textColor
                                            .withOpacity(0.8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w300,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (signPage == 4)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              child: AuthTextField(
                                controller: _otpController,
                                hintText: "OTP",
                                keyboard: TextInputType.number,
                                isPassField: false,
                                isEmailField: false,
                                isPassConfirmField: false,
                                icon: Icons.password,
                                pageIndex: 4,
                                maxLen: 8,
                              ),
                            ),
                          if (signPage == 4)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 15,
                                right: 15,
                                bottom: 10,
                              ),
                              child: (allAppProvidersProvider.isLoading)
                                  ? Container(
                                      height: 50,
                                      width: size.width / 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.blackLow
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Lottie.asset(
                                          "assets/loading-animation.json",
                                          width: 100,
                                          height: 50,
                                        ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: (() async {
                                        allAppProvidersProvider
                                            .isLoadingFunc(true);
                                        const CircularProgressIndicator(
                                          backgroundColor: AppColors.green,
                                        );
                                        if (_otpController.text.isNotEmpty) {
                                          // EmailPassAuthServices()
                                          //     .emailPassSignIn(
                                          //   email: _emailController.text
                                          //       .trim(),
                                          //   pass:
                                          //       _passController.text.trim(),
                                          //   context: allAppProvidersContext,
                                          // );

                                          // String token =
                                          //     await StorageServices
                                          //         .getUsrToken();

                                          log(otp.toString());
                                          if (_otpController.text.trim() ==
                                              otp.toString()) {
                                            http.Response response =
                                                await http.post(
                                              Uri.parse(
                                                  "${Keys.apiUsersBaseUrl}/verification/${_emailController.text.trim().split('@')[0]}/$verificationToken/$otp"),
                                              headers: {
                                                "content-type":
                                                    "application/json",
                                                // 'Authorization':
                                                //     'Bearer $token',
                                              },
                                            );

                                            log(response.body);

                                            if (response.statusCode == 200) {
                                              Map<String, dynamic>
                                                  responseJson =
                                                  jsonDecode(response.body);
                                              log(responseJson.toString());
                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);

                                              if (responseJson["success"]) {
                                                setState(() {
                                                  signPage = 1;
                                                });
                                                _otpController.clear();
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message:
                                                        responseJson["message"],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              } else {
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message:
                                                        responseJson["message"],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              }
                                            } else {
                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);
                                              ScaffoldMessenger.of(
                                                      allAppProvidersContext)
                                                  .showSnackBar(
                                                AppSnackbar()
                                                    .customizedAppSnackbar(
                                                  message: response.statusCode
                                                      .toString(),
                                                  context:
                                                      allAppProvidersContext,
                                                ),
                                              );
                                            }
                                          } else {
                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                            ScaffoldMessenger.of(
                                                    allAppProvidersContext)
                                                .showSnackBar(
                                              AppSnackbar()
                                                  .customizedAppSnackbar(
                                                message:
                                                    "Please check your OTP",
                                                context: allAppProvidersContext,
                                              ),
                                            );
                                          }
                                        } else {
                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message: "Please enter the OTP",
                                              context: allAppProvidersContext,
                                            ),
                                          );
                                        }
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                      }),
                                      child: Container(
                                        height: 50,
                                        width: size.width / 2,
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: AppColors.shadow,
                                          gradient: AppColors.gradient,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Submit",
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
                          if (signPage == 4)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Any problem with OTP?",
                                  style: TextStyle(
                                    color: AppColors.textColor.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: (() async {
                                    allAppProvidersProvider.isLoadingFunc(true);
                                    _otpController.clear();
                                    http.Response response = await http.post(
                                      Uri.parse(
                                          "${Keys.apiUsersBaseUrl}/resendOTP/${_emailController.text.trim()}/${_emailController.text.trim().split('@')[0]}/$verificationToken"),
                                      headers: {
                                        "content-type": "application/json",
                                        // 'Authorization':
                                        //     'Bearer $token',
                                      },
                                    );

                                    log(response.body);

                                    if (response.statusCode == 200) {
                                      Map<String, dynamic> responseJson =
                                          jsonDecode(response.body);
                                      log(responseJson.toString());
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);

                                      if (responseJson["success"]) {
                                        verificationToken =
                                            responseJson["verificationToken"];
                                        otp = responseJson["otp"];
                                        setState(() {});
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        _otpController.clear();
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson["message"],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      } else {
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson["message"],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      }
                                    } else {
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);
                                      ScaffoldMessenger.of(
                                              allAppProvidersContext)
                                          .showSnackBar(
                                        AppSnackbar().customizedAppSnackbar(
                                          message:
                                              response.statusCode.toString(),
                                          context: allAppProvidersContext,
                                        ),
                                      );
                                    }
                                  }),
                                  child: const Text(
                                    "Resend it",
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    back: SizedBox(
                      width: size.width,
                      child: Column(
                        children: [
                          //SIGN UP
                          if (selected == false && selectedImage == null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 15,
                                right: 15,
                              ),
                              child: Consumer<AllAppProviders>(
                                builder: (allAppContext, allAppProvider,
                                    allAppChild) {
                                  return TextFormField(
                                    onTap: (() async {
                                      try {
                                        final image = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (image == null) return;

                                        final imageTemp = File(image.path);
                                        selectedImage = imageTemp;
                                        selected = true;
                                        signUpPressed = false;

                                        setState(() {});
                                      } on PlatformException catch (e) {
                                        log(e.toString());
                                      }
                                    }),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: InputDecoration(
                                      counterText: "",
                                      prefixIcon: Icon(
                                        Icons.image,
                                        color: AppColors.textColor,
                                      ),
                                      prefixStyle: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 16,
                                      ),
                                      hintText: "Choose Profile Picture",
                                      hintStyle: TextStyle(
                                        color: AppColors.textColor
                                            .withOpacity(0.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.textColor,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: AppColors.textColor,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: AppColors.textColor,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                        left: 15,
                                        right: 15,
                                      ),
                                    ),
                                    readOnly: true,
                                    cursorColor: AppColors.green,
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (signUpPressed == true)
                            SizedBox(
                              width: size.width,
                              child: const Center(
                                child: Text(
                                  "Please select your profile picture.",
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ),
                            ),
                          if (signPage != 4)
                            Stepper(
                              currentStep: currentStep,
                              steps: [
                                Step(
                                  title: Text(
                                    "Account Details",
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  content: Column(
                                    children: [
                                      AuthTextField(
                                          icon: Icons.email_outlined,
                                          controller: _emailController,
                                          hintText: "Email",
                                          keyboard: TextInputType.emailAddress,
                                          isPassField: false,
                                          isPassConfirmField: false,
                                          isEmailField: true,
                                          pageIndex: signPage),
                                      AuthTextField(
                                        icon: Icons.security_outlined,
                                        controller: _passController,
                                        hintText: "Password",
                                        keyboard: TextInputType.visiblePassword,
                                        isPassField: true,
                                        isPassConfirmField: false,
                                        isEmailField: false,
                                        pageIndex: signPage,
                                      ),
                                      AuthTextField(
                                        icon: Icons.shield_outlined,
                                        controller: _passConfirmController,
                                        hintText: "Confirm Password",
                                        keyboard: TextInputType.visiblePassword,
                                        isPassField: false,
                                        isPassConfirmField: true,
                                        isEmailField: false,
                                        pageIndex: signPage,
                                      ),
                                    ],
                                  ),
                                ),
                                Step(
                                  title: Text(
                                    "Your Details",
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  content: Column(
                                    children: [
                                      AuthNameTextField(
                                        icon: Icons.person,
                                        controller: _firstNameController,
                                        hintText: "First Name",
                                      ),
                                      AuthNameTextField(
                                        icon: Icons.badge_outlined,
                                        controller: _lastNameController,
                                        hintText: "Last Name",
                                      ),
                                      AuthNameTextField(
                                        icon: Icons.description,
                                        controller: _desController,
                                        hintText: "Short Description",
                                        maxWords: 50,
                                        desField: true,
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 20,
                                          left: 15,
                                          right: 15,
                                          bottom: 10,
                                        ),
                                        width: size.width,
                                        child: Center(
                                          child: DropdownButtonFormField(
                                            decoration: InputDecoration(
                                              counterText: "",
                                              prefixIcon: Icon(
                                                Icons.work,
                                                color: AppColors.textColor,
                                              ),
                                              prefixStyle: TextStyle(
                                                color: AppColors.textColor,
                                                fontSize: 16,
                                              ),
                                              hintText: "Study",
                                              hintStyle: TextStyle(
                                                color: AppColors.textColor
                                                    .withOpacity(0.5),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppColors.textColor,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  width: 1,
                                                  color: AppColors.textColor,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  width: 1,
                                                  color: AppColors.textColor,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                left: 15,
                                                right: 15,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              fontSize: 16,
                                            ),
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: AppColors.textColor,
                                            ),
                                            enableFeedback: true,
                                            elevation: 5,
                                            dropdownColor:
                                                AppColors.mainColorLight,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            value: _value,
                                            items: professionList.map(
                                              (e) {
                                                return DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(
                                                    e.label,
                                                    style: GoogleFonts
                                                        .merriweather(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.textColor,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                            onChanged: (String? value) {
                                              setState(() {
                                                _value = value!;
                                                profession = professionList[
                                                        int.parse(value)]
                                                    .label;
                                                log(profession);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      if (profession == "Others")
                                        AuthNameTextField(
                                          controller:
                                              _othersProfessionController,
                                          hintText: "Enter your Profession",
                                          icon: Icons.work_outline,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              controlsBuilder: (context, _) {
                                return Row(
                                  children: <Widget>[
                                    if (currentStep != 1)
                                      TextButton(
                                        onPressed: (() async {
                                          if (_emailController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              _passController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              _passConfirmController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              isStrongPassword(_passController
                                                  .text
                                                  .trim()) &&
                                              _passController.text.trim() ==
                                                  _passConfirmController.text
                                                      .trim()) {
                                            currentStep++;
                                          } else {
                                            ScaffoldMessenger.of(
                                                    allAppProvidersContext)
                                                .showSnackBar(
                                              AppSnackbar()
                                                  .customizedAppSnackbar(
                                                message:
                                                    "Please fill the fields properly",
                                                context: context,
                                              ),
                                            );
                                          }
                                          // if (currentStep != 1) {
                                          //
                                          // } else {
                                          //   // print(packageInfo!.version);
                                          //   allAppProvidersProvider
                                          //       .isLoadingFunc(true);
                                          //
                                          //   if (_firstNameController.text
                                          //           .trim()
                                          //           .isNotEmpty &&
                                          //       _lastNameController.text
                                          //           .trim()
                                          //           .isNotEmpty &&
                                          //       _firstNameController.text
                                          //               .trim() !=
                                          //           _lastNameController.text
                                          //               .trim() &&
                                          //       EmailValidator.validate(
                                          //           _emailController.text
                                          //               .trim()) &&
                                          //       _desController.text.isNotEmpty &&
                                          //       profession.isNotEmpty &&
                                          //       _value.isNotEmpty &&
                                          //       _value != "0") {
                                          //     if (_passController.text ==
                                          //         _passConfirmController.text) {
                                          //       if (selected == true) {
                                          //         if (profession == "Others") {
                                          //           if (_othersProfessionController
                                          //               .text.isNotEmpty) {
                                          //             profession =
                                          //                 _othersProfessionController
                                          //                     .text
                                          //                     .replaceAll(
                                          //                         " ", "\n");
                                          //           } else {
                                          //             allAppProvidersProvider
                                          //                 .isLoadingFunc(false);
                                          //             ScaffoldMessenger.of(
                                          //                     allAppProvidersContext)
                                          //                 .showSnackBar(
                                          //               AppSnackbar()
                                          //                   .customizedAppSnackbar(
                                          //                 message:
                                          //                     "Please enter your profession",
                                          //                 context:
                                          //                     allAppProvidersContext,
                                          //               ),
                                          //             );
                                          //             return;
                                          //           }
                                          //         }
                                          //
                                          //         var request =
                                          //             http.MultipartRequest(
                                          //           'POST',
                                          //           Uri.parse(
                                          //               "${Keys.apiUsersBaseUrl}/create"),
                                          //         );
                                          //
                                          //         var fileStream =
                                          //             http.ByteStream(
                                          //           selectedImage!.openRead(),
                                          //         );
                                          //         var length =
                                          //             await selectedImage!
                                          //                 .length();
                                          //         var multipartFile =
                                          //             http.MultipartFile(
                                          //           Keys.usrProfilePic,
                                          //           fileStream,
                                          //           length,
                                          //           filename: selectedImage!.path
                                          //               .split('/')
                                          //               .last,
                                          //         );
                                          //
                                          //         request.files
                                          //             .add(multipartFile);
                                          //
                                          //         request.headers[
                                          //                 "content-type"] =
                                          //             "multipart/form-data";
                                          //
                                          //         request.fields[
                                          //                 Keys.usrFirstName] =
                                          //             _firstNameController.text
                                          //                 .trim();
                                          //         request.fields[
                                          //                 Keys.usrLastName] =
                                          //             _lastNameController.text
                                          //                 .trim();
                                          //         request.fields[
                                          //                 Keys.usrPassword] =
                                          //             _passController.text.trim();
                                          //         request.fields[Keys.usrEmail] =
                                          //             _emailController.text
                                          //                 .trim();
                                          //         request.fields[Keys.uid] =
                                          //             _emailController.text
                                          //                 .trim()
                                          //                 .split('@')[0];
                                          //         request.fields[
                                          //                 Keys.usrDescription] =
                                          //             _desController.text.trim();
                                          //         request.fields[
                                          //                 Keys.usrProfession] =
                                          //             profession;
                                          //         request.fields[Keys
                                          //                 .notificationToken] =
                                          //             (await FirebaseMessaging
                                          //                 .instance
                                          //                 .getToken())!;
                                          //
                                          //         http.Response response =
                                          //             await http.Response
                                          //                 .fromStream(
                                          //                     await request
                                          //                         .send());
                                          //
                                          //         Map<String, dynamic>
                                          //             responseJson = await json
                                          //                 .decode(response.body);
                                          //
                                          //         log(responseJson.toString());
                                          //
                                          //         if (response.statusCode ==
                                          //             200) {
                                          //         } else if (response
                                          //                 .statusCode ==
                                          //             501) {
                                          //           selected = false;
                                          //           selectedImage = null;
                                          //           _firstNameController.clear();
                                          //           _lastNameController.clear();
                                          //           _desController.clear();
                                          //           profession = "";
                                          //           _value = "0";
                                          //           _emailController.clear();
                                          //           _passController.clear();
                                          //           _passConfirmController
                                          //               .clear();
                                          //           setState(() {
                                          //             // signPage = 1;
                                          //           });
                                          //
                                          //           ScaffoldMessenger.of(
                                          //                   allAppProvidersContext)
                                          //               .showSnackBar(
                                          //             AppSnackbar()
                                          //                 .customizedAppSnackbar(
                                          //               message: responseJson[
                                          //                   Keys.message],
                                          //               context:
                                          //                   allAppProvidersContext,
                                          //             ),
                                          //           );
                                          //           allAppProvidersProvider
                                          //               .isLoadingFunc(false);
                                          //         } else {
                                          //           ScaffoldMessenger.of(
                                          //                   allAppProvidersContext)
                                          //               .showSnackBar(
                                          //             AppSnackbar()
                                          //                 .customizedAppSnackbar(
                                          //               message: responseJson[
                                          //                   Keys.message],
                                          //               context:
                                          //                   allAppProvidersContext,
                                          //             ),
                                          //           );
                                          //           allAppProvidersProvider
                                          //               .isLoadingFunc(false);
                                          //         }
                                          //       } else {
                                          //         signUpPressed = true;
                                          //         allAppProvidersProvider
                                          //             .isLoadingFunc(false);
                                          //         ScaffoldMessenger.of(
                                          //                 allAppProvidersContext)
                                          //             .showSnackBar(
                                          //           AppSnackbar()
                                          //               .customizedAppSnackbar(
                                          //             message:
                                          //                 "Please choose your profile picture",
                                          //             context: context,
                                          //           ),
                                          //         );
                                          //       }
                                          //     } else {
                                          //       allAppProvidersProvider
                                          //           .isLoadingFunc(false);
                                          //       ScaffoldMessenger.of(
                                          //               allAppProvidersContext)
                                          //           .showSnackBar(
                                          //         AppSnackbar()
                                          //             .customizedAppSnackbar(
                                          //           message:
                                          //               "Please check the password fields",
                                          //           context: context,
                                          //         ),
                                          //       );
                                          //     }
                                          //   } else {
                                          //     allAppProvidersProvider
                                          //         .isLoadingFunc(false);
                                          //     ScaffoldMessenger.of(
                                          //             allAppProvidersContext)
                                          //         .showSnackBar(
                                          //       AppSnackbar()
                                          //           .customizedAppSnackbar(
                                          //         message:
                                          //             "Please fill the fields properly",
                                          //         context: context,
                                          //       ),
                                          //     );
                                          //   }
                                          // }
                                          setState(() {});
                                        }),
                                        child: const Text(
                                          'NEXT',
                                          style: TextStyle(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (currentStep == 1)
                                      TextButton(
                                        onPressed: (() async {
                                          // print(packageInfo!.version);
                                          allAppProvidersProvider
                                              .isLoadingFunc(true);

                                          if (_firstNameController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              _lastNameController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              _firstNameController.text
                                                      .trim() !=
                                                  _lastNameController.text
                                                      .trim() &&
                                              _desController.text.isNotEmpty &&
                                              profession.isNotEmpty &&
                                              _value.isNotEmpty &&
                                              _value != "0") {
                                            if (selected == true) {
                                              if (profession == "Others") {
                                                if (_othersProfessionController
                                                    .text.isNotEmpty) {
                                                  profession =
                                                      _othersProfessionController
                                                          .text
                                                          .replaceAll(
                                                              " ", "\n");
                                                } else {
                                                  allAppProvidersProvider
                                                      .isLoadingFunc(false);
                                                  ScaffoldMessenger.of(
                                                          allAppProvidersContext)
                                                      .showSnackBar(
                                                    AppSnackbar()
                                                        .customizedAppSnackbar(
                                                      message:
                                                          "Please enter your profession",
                                                      context:
                                                          allAppProvidersContext,
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }

                                              var request =
                                                  http.MultipartRequest(
                                                'POST',
                                                Uri.parse(
                                                    "${Keys.apiUsersBaseUrl}/create"),
                                              );

                                              var fileStream = http.ByteStream(
                                                selectedImage!.openRead(),
                                              );
                                              var length =
                                                  await selectedImage!.length();
                                              var multipartFile =
                                                  http.MultipartFile(
                                                Keys.usrProfilePic,
                                                fileStream,
                                                length,
                                                filename: selectedImage!.path
                                                    .split('/')
                                                    .last,
                                              );

                                              request.files.add(multipartFile);

                                              request.headers["content-type"] =
                                                  "multipart/form-data";

                                              request.fields[
                                                      Keys.usrFirstName] =
                                                  _firstNameController.text
                                                      .trim();
                                              request.fields[Keys.usrLastName] =
                                                  _lastNameController.text
                                                      .trim();
                                              request.fields[Keys.usrPassword] =
                                                  _passController.text.trim();
                                              request.fields[Keys.usrEmail] =
                                                  _emailController.text.trim();
                                              request.fields[Keys.uid] =
                                                  _emailController.text
                                                      .trim()
                                                      .split('@')[0];
                                              request.fields[
                                                      Keys.usrDescription] =
                                                  _desController.text.trim();
                                              request.fields[Keys
                                                  .usrProfession] = profession;
                                              request.fields[
                                                      Keys.notificationToken] =
                                                  (await FirebaseMessaging
                                                      .instance
                                                      .getToken())!;

                                              http.Response response =
                                                  await http.Response
                                                      .fromStream(
                                                          await request.send());

                                              Map<String, dynamic>
                                                  responseJson = await json
                                                      .decode(response.body);

                                              log(jsonEncode(responseJson));

                                              if (response.statusCode == 200) {
                                                UserModel userModel =
                                                    userModelFromJson(
                                                        response.body);

                                                await JsonStorage.setUsrToken(
                                                    userModel.token);

                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);

                                                signPage = 4;
                                                otp = userModel.otp;
                                                verificationToken =
                                                    userModel.token;
                                                setState(() {});
                                                //     .then((value) {
                                                //   allAppProvidersProvider
                                                //       .isLoadingFunc(false);
                                                //   return Navigator
                                                //       .pushReplacement(
                                                //     context,
                                                //     MaterialPageRoute(
                                                //       builder: (nextCtx) =>
                                                //           const MainScreen(),
                                                //     ),
                                                //   );
                                                // });
                                              } else if (response.statusCode ==
                                                  501) {
                                                selected = false;
                                                selectedImage = null;
                                                _firstNameController.clear();
                                                _lastNameController.clear();
                                                _desController.clear();
                                                profession = "";
                                                _value = "0";
                                                _emailController.clear();
                                                _passController.clear();
                                                _passConfirmController.clear();
                                                currentStep = 0;
                                                setState(() {});
                                                _flipCardController.state!
                                                    .toggleCard()
                                                    .whenComplete(() {
                                                  ScaffoldMessenger.of(
                                                          allAppProvidersContext)
                                                      .showSnackBar(
                                                    AppSnackbar()
                                                        .customizedAppSnackbar(
                                                      message: responseJson[
                                                          Keys.message],
                                                      context:
                                                          allAppProvidersContext,
                                                    ),
                                                  );
                                                });

                                                //ScaffoldMessenger.of(
                                                //                                                           allAppProvidersContext)
                                                //                                                       .showSnackBar(
                                                //                                                     AppSnackbar()
                                                //                                                         .customizedAppSnackbar(
                                                //                                                       message: responseJson[
                                                //                                                           Keys.message],
                                                //                                                       context:
                                                //                                                           allAppProvidersContext,
                                                //                                                     ),
                                                //                                                   );

                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                              } else {
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message: responseJson[
                                                        Keys.message],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                              }
                                            } else {
                                              signUpPressed = true;
                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);
                                              ScaffoldMessenger.of(
                                                      allAppProvidersContext)
                                                  .showSnackBar(
                                                AppSnackbar()
                                                    .customizedAppSnackbar(
                                                  message:
                                                      "Please choose your profile picture",
                                                  context: context,
                                                ),
                                              );
                                            }
                                          } else {
                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                            ScaffoldMessenger.of(
                                                    allAppProvidersContext)
                                                .showSnackBar(
                                              AppSnackbar()
                                                  .customizedAppSnackbar(
                                                message:
                                                    "Please fill the fields properly",
                                                context: context,
                                              ),
                                            );
                                          }
                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                        }),
                                        child: (allAppProvidersProvider
                                                .isLoading)
                                            ? const CircularProgressIndicator(
                                                color: AppColors.green,
                                                strokeWidth: 2,
                                              )
                                            : Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: AppColors.shadow,
                                                  gradient: AppColors.gradient,
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'SIGN UP',
                                                    style: TextStyle(
                                                      color: AppColors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    if (currentStep == 1)
                                      TextButton(
                                        onPressed: (() {
                                          currentStep--;
                                          setState(() {});
                                        }),
                                        child: const Text(
                                          'EXIT',
                                          style: TextStyle(
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },

                              // onStepTapped: ((step) {
                              //   currentStep = step;
                              //   setState(() {});
                              // }),
                              onStepContinue: (() async {
                                if (currentStep != 1) {
                                  if (_emailController.text.trim().isNotEmpty &&
                                      _passController.text.trim().isNotEmpty &&
                                      _passConfirmController.text
                                          .trim()
                                          .isNotEmpty) {
                                    currentStep++;
                                  } else {
                                    ScaffoldMessenger.of(allAppProvidersContext)
                                        .showSnackBar(
                                      AppSnackbar().customizedAppSnackbar(
                                        message:
                                            "Please fill the fields properly",
                                        context: context,
                                      ),
                                    );
                                  }
                                } else {
                                  // print(packageInfo!.version);
                                  allAppProvidersProvider.isLoadingFunc(true);

                                  if (_firstNameController.text
                                          .trim()
                                          .isNotEmpty &&
                                      _lastNameController.text
                                          .trim()
                                          .isNotEmpty &&
                                      _firstNameController.text.trim() !=
                                          _lastNameController.text.trim() &&
                                      EmailValidator.validate(
                                          _emailController.text.trim()) &&
                                      _desController.text.isNotEmpty &&
                                      profession.isNotEmpty &&
                                      _value.isNotEmpty &&
                                      _value != "0") {
                                    if (_passController.text ==
                                        _passConfirmController.text) {
                                      if (selected == true) {
                                        if (profession == "Others") {
                                          if (_othersProfessionController
                                              .text.isNotEmpty) {
                                            profession =
                                                _othersProfessionController.text
                                                    .replaceAll(" ", "\n");
                                          } else {
                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                            ScaffoldMessenger.of(
                                                    allAppProvidersContext)
                                                .showSnackBar(
                                              AppSnackbar()
                                                  .customizedAppSnackbar(
                                                message:
                                                    "Please enter your profession",
                                                context: allAppProvidersContext,
                                              ),
                                            );
                                            return;
                                          }
                                        }

                                        var request = http.MultipartRequest(
                                          'POST',
                                          Uri.parse(
                                              "${Keys.apiUsersBaseUrl}/create"),
                                        );

                                        var fileStream = http.ByteStream(
                                          selectedImage!.openRead(),
                                        );
                                        var length =
                                            await selectedImage!.length();
                                        var multipartFile = http.MultipartFile(
                                          Keys.usrProfilePic,
                                          fileStream,
                                          length,
                                          filename: selectedImage!.path
                                              .split('/')
                                              .last,
                                        );

                                        request.files.add(multipartFile);

                                        request.headers["content-type"] =
                                            "multipart/form-data";

                                        request.fields[Keys.usrFirstName] =
                                            _firstNameController.text.trim();
                                        request.fields[Keys.usrLastName] =
                                            _lastNameController.text.trim();
                                        request.fields[Keys.usrPassword] =
                                            _passController.text.trim();
                                        request.fields[Keys.usrEmail] =
                                            _emailController.text.trim();
                                        request.fields[Keys.uid] =
                                            _emailController.text
                                                .trim()
                                                .split('@')[0];
                                        request.fields[Keys.usrDescription] =
                                            _desController.text.trim();
                                        request.fields[Keys.usrProfession] =
                                            profession;
                                        request.fields[Keys.notificationToken] =
                                            (await FirebaseMessaging.instance
                                                .getToken())!;

                                        http.Response response =
                                            await http.Response.fromStream(
                                                await request.send());

                                        Map<String, dynamic> responseJson =
                                            await json.decode(response.body);

                                        log(responseJson.toString());

                                        if (response.statusCode == 200) {
                                        } else if (response.statusCode == 501) {
                                          selected = false;
                                          selectedImage = null;
                                          _firstNameController.clear();
                                          _lastNameController.clear();
                                          _desController.clear();
                                          profession = "";
                                          _value = "0";
                                          _emailController.clear();
                                          _passController.clear();
                                          _passConfirmController.clear();
                                          setState(() {
                                            // signPage = 1;
                                          });

                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message:
                                                  responseJson[Keys.message],
                                              context: allAppProvidersContext,
                                            ),
                                          );
                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                        } else {
                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message:
                                                  responseJson[Keys.message],
                                              context: allAppProvidersContext,
                                            ),
                                          );
                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                        }
                                      } else {
                                        signUpPressed = true;
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message:
                                                "Please choose your profile picture",
                                            context: context,
                                          ),
                                        );
                                      }
                                    } else {
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);
                                      ScaffoldMessenger.of(
                                              allAppProvidersContext)
                                          .showSnackBar(
                                        AppSnackbar().customizedAppSnackbar(
                                          message:
                                              "Please check the password fields",
                                          context: context,
                                        ),
                                      );
                                    }
                                  } else {
                                    allAppProvidersProvider
                                        .isLoadingFunc(false);
                                    ScaffoldMessenger.of(allAppProvidersContext)
                                        .showSnackBar(
                                      AppSnackbar().customizedAppSnackbar(
                                        message:
                                            "Please fill the fields properly",
                                        context: context,
                                      ),
                                    );
                                  }
                                }
                                setState(() {});
                              }),
                              onStepCancel: (currentStep == 1)
                                  ? (() {
                                      currentStep--;
                                      setState(() {});
                                    })
                                  : null,
                              stepIconBuilder: ((step, ctx) {
                                if (step == currentStep &&
                                    selectedImage != null) {
                                  return GestureDetector(
                                    onTap: (() async {
                                      try {
                                        final image = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (image == null) return;

                                        final imageTemp = File(image.path);
                                        selectedImage = imageTemp;
                                        setState(() {});
                                      } on PlatformException catch (e) {
                                        log(e.toString());
                                      }
                                    }),
                                    child: CircleAvatar(
                                      backgroundImage: FileImage(
                                        selectedImage!,
                                      ),
                                      radius: 30,
                                    ),
                                  );
                                }

                                return Center(
                                  child: Text(
                                    (step + 1).toString(),
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                );
                              }),
                            ),

                          // Padding(
                          //   padding: const EdgeInsets.only(
                          //     top: 20,
                          //     left: 15,
                          //     right: 15,
                          //     bottom: 10,
                          //   ),
                          //   child: (allAppProvidersProvider.isLoading)
                          //       ? Container(
                          //           height: 50,
                          //           width: size.width / 2,
                          //           decoration: BoxDecoration(
                          //             color: AppColors.white,
                          //             borderRadius: BorderRadius.circular(20),
                          //             boxShadow: [
                          //               BoxShadow(
                          //                 color: AppColors.blackLow
                          //                     .withOpacity(0.5),
                          //                 blurRadius: 10,
                          //               ),
                          //             ],
                          //           ),
                          //           child: Center(
                          //             child: Lottie.asset(
                          //               "assets/loading-animation.json",
                          //               width: 100,
                          //               height: 50,
                          //             ),
                          //           ),
                          //         )
                          //       : InkWell(
                          //           onTap: (() async {
                          //             // print(packageInfo!.version);
                          //             allAppProvidersProvider
                          //                 .isLoadingFunc(true);
                          //
                          //             if (_emailController.text
                          //                     .trim()
                          //                     .isNotEmpty &&
                          //                 _passController.text
                          //                     .trim()
                          //                     .isNotEmpty &&
                          //                 _passConfirmController.text
                          //                     .trim()
                          //                     .isNotEmpty &&
                          //                 _firstNameController.text
                          //                     .trim()
                          //                     .isNotEmpty &&
                          //                 _lastNameController.text
                          //                     .trim()
                          //                     .isNotEmpty &&
                          //                 _firstNameController.text.trim() !=
                          //                     _lastNameController.text.trim() &&
                          //                 EmailValidator.validate(
                          //                     _emailController.text.trim()) &&
                          //                 _desController.text.isNotEmpty &&
                          //                 profession.isNotEmpty &&
                          //                 _value.isNotEmpty &&
                          //                 _value != "0") {
                          //               if (_passController.text ==
                          //                   _passConfirmController.text) {
                          //                 if (selected == true) {
                          //                   if (profession == "Others") {
                          //                     if (_othersProfessionController
                          //                         .text.isNotEmpty) {
                          //                       profession =
                          //                           _othersProfessionController
                          //                               .text
                          //                               .replaceAll(" ", "\n");
                          //                     } else {
                          //                       allAppProvidersProvider
                          //                           .isLoadingFunc(false);
                          //                       ScaffoldMessenger.of(
                          //                               allAppProvidersContext)
                          //                           .showSnackBar(
                          //                         AppSnackbar()
                          //                             .customizedAppSnackbar(
                          //                           message:
                          //                               "Please enter your profession",
                          //                           context:
                          //                               allAppProvidersContext,
                          //                         ),
                          //                       );
                          //                       return;
                          //                     }
                          //                   }
                          //
                          //                   var request = http.MultipartRequest(
                          //                     'POST',
                          //                     Uri.parse(
                          //                         "${Keys.apiUsersBaseUrl}/create"),
                          //                   );
                          //
                          //                   var fileStream = http.ByteStream(
                          //                     selectedImage!.openRead(),
                          //                   );
                          //                   var length =
                          //                       await selectedImage!.length();
                          //                   var multipartFile =
                          //                       http.MultipartFile(
                          //                     Keys.usrProfilePic,
                          //                     fileStream,
                          //                     length,
                          //                     filename: selectedImage!.path
                          //                         .split('/')
                          //                         .last,
                          //                   );
                          //
                          //                   request.files.add(multipartFile);
                          //
                          //                   request.headers["content-type"] =
                          //                       "multipart/form-data";
                          //
                          //                   request.fields[Keys.usrFirstName] =
                          //                       _firstNameController.text
                          //                           .trim();
                          //                   request.fields[Keys.usrLastName] =
                          //                       _lastNameController.text.trim();
                          //                   request.fields[Keys.usrPassword] =
                          //                       _passController.text.trim();
                          //                   request.fields[Keys.usrEmail] =
                          //                       _emailController.text.trim();
                          //                   request.fields[Keys.uid] =
                          //                       _emailController.text
                          //                           .trim()
                          //                           .split('@')[0];
                          //                   request.fields[
                          //                           Keys.usrDescription] =
                          //                       _desController.text.trim();
                          //                   request.fields[Keys.usrProfession] =
                          //                       profession;
                          //                   request.fields[
                          //                           Keys.notificationToken] =
                          //                       (await FirebaseMessaging
                          //                           .instance
                          //                           .getToken())!;
                          //
                          //                   http.Response response =
                          //                       await http.Response.fromStream(
                          //                           await request.send());
                          //
                          //                   Map<String, dynamic> responseJson =
                          //                       await json
                          //                           .decode(response.body);
                          //
                          //                   log(responseJson.toString());
                          //
                          //                   if (response.statusCode == 200) {
                          //                   } else if (response.statusCode ==
                          //                       501) {
                          //                     selected = false;
                          //                     selectedImage = null;
                          //                     _firstNameController.clear();
                          //                     _lastNameController.clear();
                          //                     _desController.clear();
                          //                     profession = "";
                          //                     _value = "0";
                          //                     _emailController.clear();
                          //                     _passController.clear();
                          //                     _passConfirmController.clear();
                          //                     setState(() {
                          //                       // signPage = 1;
                          //                     });
                          //
                          //                     ScaffoldMessenger.of(
                          //                             allAppProvidersContext)
                          //                         .showSnackBar(
                          //                       AppSnackbar()
                          //                           .customizedAppSnackbar(
                          //                         message: responseJson[
                          //                             Keys.message],
                          //                         context:
                          //                             allAppProvidersContext,
                          //                       ),
                          //                     );
                          //                     allAppProvidersProvider
                          //                         .isLoadingFunc(false);
                          //                   } else {
                          //                     ScaffoldMessenger.of(
                          //                             allAppProvidersContext)
                          //                         .showSnackBar(
                          //                       AppSnackbar()
                          //                           .customizedAppSnackbar(
                          //                         message: responseJson[
                          //                             Keys.message],
                          //                         context:
                          //                             allAppProvidersContext,
                          //                       ),
                          //                     );
                          //                     allAppProvidersProvider
                          //                         .isLoadingFunc(false);
                          //                   }
                          //                 } else {
                          //                   signUpPressed = true;
                          //                   allAppProvidersProvider
                          //                       .isLoadingFunc(false);
                          //                   ScaffoldMessenger.of(
                          //                           allAppProvidersContext)
                          //                       .showSnackBar(
                          //                     AppSnackbar()
                          //                         .customizedAppSnackbar(
                          //                       message:
                          //                           "Please choose your profile picture",
                          //                       context: context,
                          //                     ),
                          //                   );
                          //                 }
                          //               } else {
                          //                 allAppProvidersProvider
                          //                     .isLoadingFunc(false);
                          //                 ScaffoldMessenger.of(
                          //                         allAppProvidersContext)
                          //                     .showSnackBar(
                          //                   AppSnackbar().customizedAppSnackbar(
                          //                     message:
                          //                         "Please check the password fields",
                          //                     context: context,
                          //                   ),
                          //                 );
                          //               }
                          //             } else {
                          //               allAppProvidersProvider
                          //                   .isLoadingFunc(false);
                          //               ScaffoldMessenger.of(
                          //                       allAppProvidersContext)
                          //                   .showSnackBar(
                          //                 AppSnackbar().customizedAppSnackbar(
                          //                   message:
                          //                       "Please fill the fields properly",
                          //                   context: context,
                          //                 ),
                          //               );
                          //             }
                          //           }),
                          //           child: Container(
                          //             height: 50,
                          //             width: size.width / 2,
                          //             decoration: BoxDecoration(
                          //               color: AppColors.white,
                          //               borderRadius: BorderRadius.circular(20),
                          //               boxShadow: [
                          //                 BoxShadow(
                          //                   color: AppColors.blackLow
                          //                       .withOpacity(0.5),
                          //                   blurRadius: 10,
                          //                 ),
                          //               ],
                          //             ),
                          //             child: Center(
                          //               child: Text(
                          //                 "Sign Up",
                          //                 style: TextStyle(
                          //                   color: AppColors.green,
                          //                   fontWeight: FontWeight.bold,
                          //                   fontSize: 17,
                          //                 ),
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          // ),
                          if (signPage != 4)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: AppColors.textColor.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: (() {
                                    allAppProvidersProvider
                                        .isLoadingFunc(false);
                                    _emailController.clear();
                                    _passController.clear();
                                    _firstNameController.clear();
                                    _lastNameController.clear();
                                    _passConfirmController.clear();
                                    _desController.clear();
                                    _value = "0";
                                    selectedImage = null;
                                    selected = false;
                                    _flipCardController.state?.toggleCard();
                                    setState(() {});
                                  }),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          if (signPage == 4)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 25,
                                  top: 30,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "OTP Verification",
                                      style: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Please enter the OTP send to ${_emailController.text.trim()}",
                                      style: TextStyle(
                                        color: AppColors.textColor
                                            .withOpacity(0.8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w300,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (signPage == 4)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              child: AuthTextField(
                                controller: _otpController,
                                hintText: "OTP",
                                keyboard: TextInputType.number,
                                isPassField: false,
                                isEmailField: false,
                                isPassConfirmField: false,
                                icon: Icons.password,
                                pageIndex: 4,
                                maxLen: 8,
                              ),
                            ),
                          if (signPage == 4)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 15,
                                right: 15,
                                bottom: 10,
                              ),
                              child: (allAppProvidersProvider.isLoading)
                                  ? Container(
                                      height: 50,
                                      width: size.width / 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.blackLow
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Lottie.asset(
                                          "assets/loading-animation.json",
                                          width: 100,
                                          height: 50,
                                        ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: (() async {
                                        allAppProvidersProvider
                                            .isLoadingFunc(true);
                                        const CircularProgressIndicator(
                                          backgroundColor: AppColors.green,
                                        );
                                        if (_otpController.text.isNotEmpty) {
                                          // EmailPassAuthServices()
                                          //     .emailPassSignIn(
                                          //   email: _emailController.text
                                          //       .trim(),
                                          //   pass:
                                          //       _passController.text.trim(),
                                          //   context: allAppProvidersContext,
                                          // );

                                          // String token =
                                          //     await StorageServices
                                          //         .getUsrToken();

                                          log(otp.toString());
                                          if (_otpController.text.trim() ==
                                              otp.toString().trim()) {
                                            http.Response response =
                                                await http.post(
                                              Uri.parse(
                                                  "${Keys.apiUsersBaseUrl}/verification/${_emailController.text.trim().split('@')[0]}/$verificationToken/$otp"),
                                              headers: {
                                                "content-type":
                                                    "application/json",
                                                // 'Authorization':
                                                //     'Bearer $token',
                                              },
                                            );

                                            log(response.body);

                                            if (response.statusCode == 200) {
                                              Map<String, dynamic>
                                                  responseJson =
                                                  jsonDecode(response.body);
                                              log(responseJson.toString());
                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);

                                              if (responseJson["success"]) {
                                                setState(() {
                                                  signPage = 1;
                                                });
                                                _otpController.clear();
                                                _passController.clear();
                                                _passConfirmController.clear();
                                                _flipCardController.state
                                                    ?.toggleCard();
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message:
                                                        responseJson["message"],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              } else {
                                                allAppProvidersProvider
                                                    .isLoadingFunc(false);
                                                ScaffoldMessenger.of(
                                                        allAppProvidersContext)
                                                    .showSnackBar(
                                                  AppSnackbar()
                                                      .customizedAppSnackbar(
                                                    message:
                                                        responseJson["message"],
                                                    context:
                                                        allAppProvidersContext,
                                                  ),
                                                );
                                              }
                                            } else {
                                              allAppProvidersProvider
                                                  .isLoadingFunc(false);
                                              ScaffoldMessenger.of(
                                                      allAppProvidersContext)
                                                  .showSnackBar(
                                                AppSnackbar()
                                                    .customizedAppSnackbar(
                                                  message: response.statusCode
                                                      .toString(),
                                                  context:
                                                      allAppProvidersContext,
                                                ),
                                              );
                                            }
                                          } else {
                                            allAppProvidersProvider
                                                .isLoadingFunc(false);
                                            ScaffoldMessenger.of(
                                                    allAppProvidersContext)
                                                .showSnackBar(
                                              AppSnackbar()
                                                  .customizedAppSnackbar(
                                                message:
                                                    "Please check your OTP",
                                                context: allAppProvidersContext,
                                              ),
                                            );
                                          }
                                        } else {
                                          allAppProvidersProvider
                                              .isLoadingFunc(false);
                                          ScaffoldMessenger.of(
                                                  allAppProvidersContext)
                                              .showSnackBar(
                                            AppSnackbar().customizedAppSnackbar(
                                              message: "Please enter the OTP",
                                              context: allAppProvidersContext,
                                            ),
                                          );
                                        }
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                      }),
                                      child: Container(
                                        height: 50,
                                        width: size.width / 2,
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: AppColors.shadow,
                                          gradient: AppColors.gradient,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Submit",
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
                          if (signPage == 4)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Any problem with OTP?",
                                  style: TextStyle(
                                    color: AppColors.textColor.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: (() async {
                                    allAppProvidersProvider.isLoadingFunc(true);
                                    _otpController.clear();
                                    http.Response response = await http.post(
                                      Uri.parse(
                                          "${Keys.apiUsersBaseUrl}/resendOTP/${_emailController.text.trim()}/${_emailController.text.trim().split('@')[0]}/$verificationToken"),
                                      headers: {
                                        "content-type": "application/json",
                                        // 'Authorization':
                                        //     'Bearer $token',
                                      },
                                    );

                                    log(response.body);

                                    if (response.statusCode == 200) {
                                      Map<String, dynamic> responseJson =
                                          jsonDecode(response.body);
                                      log(responseJson.toString());
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);

                                      if (responseJson["success"]) {
                                        verificationToken =
                                            responseJson["verificationToken"];
                                        otp = responseJson["otp"];
                                        setState(() {});
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        _otpController.clear();
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson["message"],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      } else {
                                        allAppProvidersProvider
                                            .isLoadingFunc(false);
                                        ScaffoldMessenger.of(
                                                allAppProvidersContext)
                                            .showSnackBar(
                                          AppSnackbar().customizedAppSnackbar(
                                            message: responseJson["message"],
                                            context: allAppProvidersContext,
                                          ),
                                        );
                                      }
                                    } else {
                                      allAppProvidersProvider
                                          .isLoadingFunc(false);
                                      ScaffoldMessenger.of(
                                              allAppProvidersContext)
                                          .showSnackBar(
                                        AppSnackbar().customizedAppSnackbar(
                                          message:
                                              response.statusCode.toString(),
                                          context: allAppProvidersContext,
                                        ),
                                      );
                                    }
                                  }),
                                  child: const Text(
                                    "Resend it",
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    onFlipDone: ((val) {
                      if (_flipCardController.state?.isFront ?? false) {
                        containerHeight = 800;
                      } else {
                        containerHeight = 400;
                      }
                      setState(() {});
                    }),
                    onFlip: (() {}),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboard,
    required this.isPassField,
    required this.isEmailField,
    required this.isPassConfirmField,
    required this.icon,
    required this.pageIndex,
    this.maxLen,
    // required this.formKey,
  });
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboard;
  final bool isPassField, isPassConfirmField, isEmailField;
  final IconData icon;
  final int pageIndex;
  final int? maxLen;

  // GlobalKey<FormState> formKey;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool passVisibility = true;
  bool passConfirmVisibility = true;

  String? _validate(String? input) {
    if (input != null && input.isNotEmpty) {
      if (widget.isEmailField) {
        if (!EmailValidator.validate(input)) {
          return "Enter a valid email";
        } else {
          return null;
        }
      }
      if (widget.isPassField) {
        if (input.length < 8) {
          return "Minimum 8 characters";
        }
        if (!RegExp(r'^(?=.*[A-Z])[\w#]+').hasMatch(input)) {
          return "Minimum 1 Uppercase character";
        }
        if (!RegExp(r'^(?=.*[a-z])[\w#]+').hasMatch(input)) {
          return "Minimum 1 Lowercase character";
        }
        if (!RegExp(r'^(?=.*[0-9])[\w#]+').hasMatch(input)) {
          return "Minimum 1 numeric";
        }
        if (!RegExp(r'^(?=.*[@#₹_&-+()/*:;!?~`|$^=.,])[\w#]+')
            .hasMatch(input)) {
          return "Minimum 1 special character";
        }
      }
      return null;
    }
    return "This is a required field";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        left: 15,
        right: 15,
        bottom: 10,
      ),
      child: TextFormField(
        maxLength: widget.maxLen,
        enableInteractiveSelection:
            (widget.isPassField || widget.isPassConfirmField) ? false : true,
        decoration: InputDecoration(
          errorStyle: const TextStyle(
            overflow: TextOverflow.clip,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: AppColors.textColor,
          ),
          prefixStyle: TextStyle(
            color: AppColors.textColor,
            fontSize: 16,
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.textColor.withOpacity(0.5),
          ),
          suffixIcon: (widget.isPassField || widget.isPassConfirmField)
              ? IconButton(
                  icon: (widget.isPassField)
                      ? passVisibility
                          ? Icon(
                              Icons.visibility,
                              color: AppColors.textColor,
                            )
                          : Icon(
                              Icons.visibility_off,
                              color: AppColors.textColor,
                            )
                      : passConfirmVisibility
                          ? Icon(
                              Icons.visibility,
                              color: AppColors.textColor,
                            )
                          : Icon(
                              Icons.visibility_off,
                              color: AppColors.textColor,
                            ),
                  onPressed: (() {
                    if (widget.isPassField) {
                      setState(() {
                        passVisibility = !passVisibility;
                      });
                    }
                    if (widget.isPassConfirmField) {
                      setState(() {
                        passConfirmVisibility = !passConfirmVisibility;
                      });
                    }
                  }),
                )
              : null,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.textColor,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: AppColors.textColor,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: AppColors.textColor,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          contentPadding: const EdgeInsets.only(
            left: 15,
            right: 15,
          ),
        ),
        validator: _validate,
        // (widget.isEmailField && widget.controller.text.isNotEmpty)
        //     ? (email) => (email != null && !EmailValidator.validate(email))
        //         ? "Enter a valid email"
        //         : null
        //     : (widget.isPassField && widget.controller.text.isNotEmpty)
        //         ? ((password) {
        //             if (password != null) {
        //               if (password.length < 8) {
        //                 return "Password should contain minimum 8 characters";
        //               }
        //               if (!RegExp(r'^(?=.*[A-Z])\w+').hasMatch(password)) {
        //                 return "Password should contain minimum 1 Uppercase character";
        //               }
        //               if (!RegExp(r'^(?=.*[a-z])\w+').hasMatch(password)) {
        //                 return "Password should contain minimum 1 Lowercase character";
        //               }
        //               if (!RegExp(r'^(?=.*[0-9])\w+').hasMatch(password)) {
        //                 return "Password should contain minimum 1 numeric";
        //               }
        //               if (!RegExp(r'^(?=.*[@#₹_&-+()/*:;!?~`|$^=.,])\w+')
        //                   .hasMatch(password)) {
        //                 return "Password should contain minimum 1 special character";
        //               }
        //             }
        //             return null;
        //           })
        //         : null

        autovalidateMode: (widget.isEmailField || widget.isPassField)
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        controller: widget.controller,
        keyboardType: widget.keyboard,
        cursorColor: AppColors.green,
        style: TextStyle(
          color: AppColors.textColor,
        ),
        obscureText: (widget.isPassField)
            ? passVisibility
            : (widget.isPassConfirmField)
                ? passConfirmVisibility
                : false,
      ),
    );
  }
}

class AuthNameTextField extends StatefulWidget {
  const AuthNameTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxWords,
    this.desField,
    this.maxLines,
    this.onTap,
    this.onSubmit,
    this.onTappedOutSide,
    this.readOnly,
    this.nameField,
    this.onChange,
    this.inputFormatter,
    // required this.formKey,
  });
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int? maxWords, maxLines;
  final bool? nameField, desField, readOnly;
  final VoidCallback? onTap;
  final Function(String)? onSubmit;
  final Function(String)? onChange;
  final Function(PointerDownEvent)? onTappedOutSide;
  final List<TextInputFormatter>? inputFormatter;

  @override
  State<AuthNameTextField> createState() => _AuthNameTextFieldState();
}

class _AuthNameTextFieldState extends State<AuthNameTextField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        left: 15,
        right: 15,
        bottom: 10,
      ),
      child: Consumer<AllAppProviders>(
        builder: (allAppContext, allAppProvider, allAppChild) {
          return TextFormField(
            textCapitalization: TextCapitalization.sentences,
            onTap: widget.onTap,
            readOnly: (widget.readOnly != null) ? true : false,
            decoration: InputDecoration(
              counterText: "",
              suffixText: (widget.desField != null && widget.desField == true)
                  ? "${allAppProvider.desPosition.toString()}/${widget.maxWords}"
                  : (widget.nameField != null && widget.nameField == true)
                      ? "${allAppProvider.namePosition.toString()}/${widget.maxWords}"
                      : "",
              prefixIcon: Icon(
                widget.icon,
                color: AppColors.textColor,
              ),
              prefixStyle: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.textColor.withOpacity(0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.textColor,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: AppColors.textColor,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: AppColors.textColor,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              contentPadding: const EdgeInsets.only(
                left: 15,
                right: 15,
              ),
            ),
            onChanged: ((text) {
              if (widget.desField != null && widget.desField == true) {
                allAppProvider.desLengthFunc(text.trim().length);
              }
              if (widget.nameField != null && widget.nameField == true) {
                allAppProvider.nameLengthFunc(text.trim().length);
              }
            }),
            maxLength: widget.maxWords,
            maxLines: (widget.desField != null && widget.desField == true)
                ? (widget.maxLines == null)
                    ? 2
                    : widget.maxLines
                : null,
            minLines: 1,
            controller: widget.controller,
            keyboardType: (widget.desField != null && widget.desField == true)
                ? TextInputType.multiline
                : TextInputType.name,
            cursorColor: AppColors.green,
            style: TextStyle(
              color: AppColors.textColor,
            ),
            onFieldSubmitted: widget.onSubmit,
            onTapOutside: widget.onTappedOutSide,
            inputFormatters: widget.inputFormatter,
          );
        },
      ),
    );
  }
}

class CompanyAuth extends StatelessWidget {
  const CompanyAuth({
    super.key,
    required this.logo,
    required this.onTap,
  });

  final String logo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          image: DecorationImage(
            scale: 1.5,
            image: AssetImage(
              logo,
            ),
          ),
        ),
      ),
    );
  }
}
