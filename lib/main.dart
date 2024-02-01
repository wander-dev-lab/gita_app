import 'dart:convert';
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:gita_app/firebase_options.dart';
import 'package:gita_app/providers/app_providers.dart';
import 'package:gita_app/providers/theme_provider.dart';
import 'package:gita_app/providers/tts_provider.dart';
import 'package:gita_app/screens/splash_screen.dart';
import 'package:gita_app/services/keys.dart';
import 'package:gita_app/services/notification_services.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase
      .initializeApp(); // options: DefaultFirebaseConfig.platformOptions
  log('Handling a background message ${message.messageId}');
}

Future<void> main() async {
  // SystemChrome.setSystemUIOverlayStyle(
  //   SystemUiOverlayStyle(
  //     statusBarColor: Colors.black.withOpacity(0.5),
  //   ),
  // );
  // WidgetsFlutterBinding.ensureInitialized();
  // final savedThemeMode = await AdaptiveTheme.getThemeMode();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // if (Platform.isAndroid) {
  //   FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  // }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  MobileAds.instance.initialize();
  // try {
  // } catch (e) {
  //   print('Firebase initialization error: $e');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // }

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: Keys.completedChapterChannelGroupKey,
        channelKey: Keys.completedChapterChannelKey,
        channelName: Keys.completedChapterChannelNameKey,
        channelDescription: Keys.completedChapterChannelDescriptionKey,
        defaultColor: AppColors.mainColor,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelGroupKey: Keys.lastCheckedChapterChannelGroupKey,
        channelKey: Keys.lastCheckedChapterChannelKey,
        channelName: Keys.lastCheckedChapterChannelNameKey,
        channelDescription: Keys.lastCheckedChapterChannelDescriptionKey,
        defaultColor: AppColors.mainColor,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelGroupKey: Keys.completedVerseChannelGroupKey,
        channelKey: Keys.completedVerseChannelKey,
        channelName: Keys.completedVerseChannelNameKey,
        channelDescription: Keys.completedVerseChannelDescriptionKey,
        defaultColor: AppColors.mainColor,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelGroupKey: Keys.lastCheckedVerseChannelGroupKey,
        channelKey: Keys.lastCheckedVerseChannelKey,
        channelName: Keys.lastCheckedVerseChannelNameKey,
        channelDescription: Keys.lastCheckedVerseChannelDescriptionKey,
        defaultColor: AppColors.mainColor,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelGroupKey: Keys.lastPlayedChapterChannelGroupKey,
        channelKey: Keys.lastPlayedChapterChannelKey,
        channelName: Keys.lastPlayedChapterChannelNameKey,
        channelDescription: Keys.lastPlayedChapterChannelDescriptionKey,
        defaultColor: AppColors.mainColor,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
      NotificationChannel(
        groupKey: Keys.mediaNotificationChapterChannelGroupKey,
        channelKey: Keys.mediaNotificationChapterChannelKey,
        channelName: Keys.mediaNotificationChapterChannelNameKey,
        channelDescription: Keys.mediaNotificationChapterChannelDescriptionKey,
        defaultPrivacy: NotificationPrivacy.Public,
        enableVibration: false,
        enableLights: false,
        playSound: false,
        locked: true,
      )
    ],
    // Channel groups are only visual and are not required
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: Keys.completedChapterChannelGroupKey,
        channelGroupName: Keys.completedChapterChannelNameKey,
      ),
      NotificationChannelGroup(
        channelGroupKey: Keys.lastCheckedChapterChannelGroupKey,
        channelGroupName: Keys.lastCheckedChapterChannelNameKey,
      ),
      NotificationChannelGroup(
        channelGroupKey: Keys.completedVerseChannelGroupKey,
        channelGroupName: Keys.completedVerseChannelNameKey,
      ),
      NotificationChannelGroup(
        channelGroupKey: Keys.lastCheckedVerseChannelGroupKey,
        channelGroupName: Keys.lastCheckedVerseChannelNameKey,
      ),
      NotificationChannelGroup(
        channelGroupKey: Keys.mediaNotificationChapterChannelGroupKey,
        channelGroupName: Keys.mediaNotificationChapterChannelNameKey,
      )
    ],
    debug: true,
  );

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission();
  // log(await firebaseMessaging.getToken() ?? "");
  firebaseMessaging.onTokenRefresh.listen((token) async {
    String usrToken = await JsonStorage.getUsrToken();
    http.Response response = await http.post(
      Uri.parse("${Keys.apiUsersBaseUrl}/updateNotificationToken/$token"),
      headers: {
        "content-type": "application/json",
        'Authorization': 'Bearer $usrToken',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      if (responseJson["success"] == true) {
        JsonStorage.setNotificationToken(
            (await FirebaseMessaging.instance.getToken())!);
      }
    }
  });
  await firebaseMessaging.subscribeToTopic("SPONSOR");
  //when foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationServices().onReceiveFCMNotification(message);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
        ChangeNotifierProvider(create: (_) => AllAppProviders()),
      ],
      child: const MyApp(),
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String selectedOption = '';

  getDetails() async {
    selectedOption = (await JsonStorage.getTheme()) ?? "Light";
    setState(() {});
  }

  @override
  void dispose() {
    // themeManager.removeListener(themeListener);
    super.dispose();
  }

  @override
  void initState() {
    getDetails();

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.merriweatherTextTheme(),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.green,
          secondary: AppColors.green.withOpacity(0.5),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
