import 'dart:convert';
import 'dart:developer';

import 'package:gita_app/models/chapters_model.dart';
import 'package:gita_app/models/notification_store_model.dart';
import 'package:gita_app/models/share_lines_model.dart';
import 'package:gita_app/models/shared_lines_model.dart';
import 'package:gita_app/models/user_login_model.dart';
import 'package:gita_app/models/verse_translation_model.dart';
import 'package:gita_app/models/verses_model.dart';
import 'package:gita_app/services/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator_plus/translator_plus.dart';

import '../models/chapter_share_model.dart';

class JsonStorage {
  static Future<bool> reset() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Keys.themeKey, theme);
  }

  static Future<void> saveVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Keys.voiceKey, voice);
  }

  static Future<String?> getVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Keys.voiceKey);
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Keys.languageKey, lang);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Keys.languageKey);
  }

  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Keys.themeKey);
  }

  static Future<void> saveChapters(List<ChaptersModel> jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(jsonData);
    prefs.setString(Keys.chapterStoreKey, jsonString);
  }

  static Future<void> saveVersesOfChapter(
      List<VersesModel> jsonData, String chapterSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(jsonData);
    prefs.setString(chapterSlug, jsonString);
  }

  static Future<void> saveVerseTranslation(
      String verseSlug, VerseTranslationModel verseTranslation) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(verseTranslation);
    prefs.setString(verseSlug, jsonString);
  }

  static Future<VerseTranslationModel> getVerseTranslation(
      String verseSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(verseSlug);
    if (jsonString != null) {
      final jsonData = json.decode(jsonString);
      return VerseTranslationModel.fromJson(jsonData);
    } else {
      return VerseTranslationModel(
        verseHindi: "Error",
        verseEnglish: "Error",
      );
    }
  }

  static Future<List<ChaptersModel>> getChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(Keys.chapterStoreKey);
    if (jsonString != null) {
      final jsonData = json.decode(jsonString) as List<dynamic>;
      return jsonData.map((json) => ChaptersModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<VersesModel>> getVersesOfChapter(
      String chapterSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(chapterSlug);
    if (jsonString != null) {
      final jsonData = json.decode(jsonString) as List<dynamic>;
      return jsonData.map((json) => VersesModel.fromJson(json)).toList();
    }
    return [];
  }

  // static Future<VersesModel?> getVerseOfChapter(
  //     String chapterSlug, int verseID) async {
  //   final List<VersesModel> verses = await getVersesOfChapter(chapterSlug);
  //   for (var verse in verses) {
  //     if (verse.id == verseID) {
  //       return verse;
  //     }
  //   }
  //   return null; // Verse with the given ID not found in the chapter
  // }

  static Future<VersesModel?> getVerseOfChapter(
      String chapterSlug, int verseID) async {
    final List<VersesModel> verses = await getVersesOfChapter(chapterSlug);

    int left = 0;
    int right = verses.length - 1;

    while (left <= right) {
      int mid = left + ((right - left) ~/ 2);
      VersesModel midVerse = verses[mid];

      if (midVerse.id == verseID) {
        return midVerse; // Found the verse
      } else if (midVerse.id < verseID) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    return null; // Verse with the given ID not found in the chapter
  }

  // Future<void> saveCompletedChapters() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setStringList(Keys.completedChapterStoreKey,
  //       integerList.map((e) => e.toString()).toList());
  // }

  static Future<List<int>> getCompletedChapters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.completedChapterStoreKey);
    if (stringList != null) {
      return stringList.map((e) => int.parse(e)).toList();
    } else {
      return [-1];
    }
  }

  static Future<void> addCompletedChapter(int newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.completedChapterStoreKey);

    if (stringList != null) {
      List<int> updatedList = stringList.map((e) => int.parse(e)).toList();
      updatedList.add(newValue);
      await prefs.setStringList(Keys.completedChapterStoreKey,
          updatedList.map((e) => e.toString()).toList());
      log("Updated");
    } else {
      await prefs.setStringList(
        Keys.completedChapterStoreKey,
        [newValue.toString()],
      );
      log("Added new value");
    }
  }

  static Future<void> deleteCompletedChapter(int valueToDelete) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.completedChapterStoreKey);

    if (stringList != null) {
      List<int> updatedList = stringList.map((e) => int.parse(e)).toList();

      if (updatedList.contains(valueToDelete)) {
        updatedList.remove(valueToDelete);
        await prefs.setStringList(Keys.completedChapterStoreKey,
            updatedList.map((e) => e.toString()).toList());
        log("Deleted value $valueToDelete");
      } else {
        log("Value $valueToDelete not found in the list.");
      }
    } else {
      log("No stored list found.");
    }
  }

  static Future<List<int>> getCompletedVerses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList(Keys.completedVerseStoreKey);
    if (stringList != null) {
      return stringList.map((e) => int.parse(e)).toList();
    } else {
      return [-1];
    }
  }

  static Future<void> addCompletedVerse(int newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList(Keys.completedVerseStoreKey);

    if (stringList != null) {
      List<int> updatedList = stringList.map((e) => int.parse(e)).toList();
      updatedList.add(newValue);
      await prefs.setStringList(Keys.completedVerseStoreKey,
          updatedList.map((e) => e.toString()).toList());
      log("Updated");
    } else {
      await prefs.setStringList(
        Keys.completedVerseStoreKey,
        [newValue.toString()],
      );
      log("Added new value");
    }
  }

  static Future<void> deleteCompletedVerse(int valueToDelete) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList(Keys.completedVerseStoreKey);

    if (stringList != null) {
      List<int> updatedList = stringList.map((e) => int.parse(e)).toList();

      if (updatedList.contains(valueToDelete)) {
        updatedList.remove(valueToDelete);
        await prefs.setStringList(Keys.completedVerseStoreKey,
            updatedList.map((e) => e.toString()).toList());
        log("Deleted value $valueToDelete");
      } else {
        log("Value $valueToDelete not found in the list.");
      }
    } else {
      log("No stored list found.");
    }
  }

  static Future<Map<int, ChaptersModel>> getChapterMap() async {
    final chapters = await getChapters();
    final Map<int, ChaptersModel> chapterMap = {};
    for (final chapter in chapters) {
      chapterMap[chapter.id] = chapter;
    }
    return chapterMap;
  }

  static Future<Map<String, dynamic>> getNextChapter(
      int currentChapterID) async {
    final chapterMap = await getChapterMap();
    final nextChapter = chapterMap[currentChapterID + 1];

    final hasNext = nextChapter != null;
    final nextChapterJson = nextChapter?.toJson() ?? {};

    nextChapterJson['hasNext'] = hasNext;

    return nextChapterJson;
  }

  static Future<Map<String, dynamic>> getCurrentChapter(
      int currentChapterID) async {
    final chapterMap = await getChapterMap();
    final currentChapter = chapterMap[currentChapterID];

    final currentChapterJson = currentChapter?.toJson() ?? {};

    // currentChapterJson['hasNext'] = hasNext;

    return currentChapterJson;
  }

  static Future<Map<String, dynamic>> getPrevChapter(
      int currentChapterID) async {
    final chapterMap = await getChapterMap();
    final prevChapter = chapterMap[currentChapterID - 1];

    final hasNext = prevChapter != null;
    final nextChapterJson = prevChapter?.toJson() ?? {};

    nextChapterJson['hasNext'] = hasNext;

    return nextChapterJson;
  }

  static Future<bool> isChapterCompleted(int chapterID) async {
    List<int> completedChapters = await getCompletedChapters();
    return completedChapters.contains(chapterID);
  }

  static Future<bool> isVerseCompleted(int verseID) async {
    List<int> completedVerses = await getCompletedVerses();
    return completedVerses.contains(verseID);
  }

  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Keys.loginStatus) ?? false;
  }

  static Future setLoginStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Keys.loginStatus, status);
  }

  static Future<String> getUsrToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Keys.usrToken) ?? "";
  }

  static Future setUsrToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Keys.usrToken, token);
  }

  static Future<String> getUsrResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Keys.resetToken) ?? "";
  }

  static Future setUsrResetToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Keys.resetToken, token);
  }

  static Future setNotificationToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Keys.notificationToken, token);
  }

  static Future saveUsrData(UserLoginModel usrData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Keys.usrData, userLoginModelToJson(usrData));
  }

  static Future<UserLoginModel> getUsrData() async {
    final prefs = await SharedPreferences.getInstance();
    return userLoginModelFromJson(prefs.getString(Keys.usrData)!);
  }

  static Future setTodayVerseID(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.todayVerseID, id);
  }

  static Future<int> getTodayVerseID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.todayVerseID) ?? 1;
  }

  static Future setTodayChapterID(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.todayChapterID, id);
  }

  static Future<int> getTodayChapterID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.todayChapterID) ?? 1;
  }

  static Future setLastUpdatedTimestamp(int time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.lastUpdatedTimestamp, time);
  }

  static Future<int?> getLastUpdatedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.lastUpdatedTimestamp);
  }

  static Future<ChapterShareModel?> getChapterShareDetails(
      int chapterID) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("${Keys.chapterShareTranslation}$chapterID");

    if (data != null) {
      return chapterShareModelFromJson(data);
    } else {
      return null;
    }
  }

  static Future setChapterShareDetails(
      ChapterShareModel data, int chapterID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("${Keys.chapterShareTranslation}$chapterID",
        chapterShareModelToJson(data));
  }

  static Future setSharedLines(ShareLinesModel lines) async {
    final prefs = await SharedPreferences.getInstance();
    final gt = GoogleTranslator();
    String san =
        await gt.translate(lines.line, to: "sa").then((value) => value.text);
    String hin =
        await gt.translate(lines.line, to: "hi").then((value) => value.text);

    await prefs.setString(
      "${Keys.sharedLineTranslation}${lines.id}",
      translationModelToJson(
        TranslationModel(
          eng: lines.line,
          san: san,
          hin: hin,
        ),
      ),
    );
  }

  static Future<TranslationModel?> getSharedLines(int lineID) async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString("${Keys.sharedLineTranslation}$lineID");
    if (data != null) {
      return translationModelFromJson(data);
    } else {
      return null;
    }
  }

  static Future<TranslationModel?> getSharedVerseTranslation(
      int verseID) async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString("${Keys.sharedVerseTranslation}$verseID");
    if (data != null) {
      return translationModelFromJson(data);
    } else {
      return null;
    }
  }

  static Future setSharedVerseTranslation(String verse, int verseID) async {
    final prefs = await SharedPreferences.getInstance();
    final gt = GoogleTranslator();
    String san =
        await gt.translate(verse, to: "sa").then((value) => value.text);
    String hin =
        await gt.translate(verse, to: "hi").then((value) => value.text);
    String eng =
        await gt.translate(verse, to: "en").then((value) => value.text);

    await prefs.setString(
      "${Keys.sharedVerseTranslation}$verseID",
      translationModelToJson(
        TranslationModel(
          eng: eng,
          san: san,
          hin: hin,
        ),
      ),
    );
  }

  static Future<TranslationModel?> getVerseIDTranslation(int verseID) async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString("${Keys.sharedVerseIDTranslation}$verseID");
    if (data != null) {
      return translationModelFromJson(data);
    } else {
      return null;
    }
  }

  static Future setVerseIDTranslation(
      TranslationModel data, int verseID) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "${Keys.sharedVerseIDTranslation}$verseID",
      translationModelToJson(data),
    );
  }

  static Future setLastCheckedChapter(int chapterID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.lastCheckedChapter, chapterID);
  }

  static Future<int?> getLastCheckedChapter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.lastCheckedChapter);
  }

  static Future setLastCompletedChapter(int chapterID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.lastCompletedChapter, chapterID);
  }

  static Future<int?> getLastCompletedChapter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.lastCompletedChapter);
  }

  static Future setLastCheckedVerse(int verseID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.lastCheckedVerse, verseID);
  }

  static Future<int?> getLastCheckedVerse() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.lastCheckedVerse);
  }

  static Future setLastCompletedVerse(int verseID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Keys.lastCompletedVerse, verseID);
  }

  static Future<int?> getLastCompletedVerse() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(Keys.lastCompletedVerse);
  }

  static Future<int?> getNotificationID() async {
    final prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt(Keys.lastNotificationID) ?? 0;
    await prefs.setInt(Keys.lastNotificationID, id + 1);
    return id;
  }

  static Future setLastCompletedVerseNotification(
      NotificationStoreModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Keys.lastCompletedVerseNotification, notificationModelToJson(data));
  }

  static Future<NotificationStoreModel?>
      getLastCompletedVerseNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(Keys.lastCompletedVerseNotification);
    return data == null ? null : notificationModelFromJson(data);
  }

  static Future setLastCheckedVerseNotification(
      NotificationStoreModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Keys.lastCheckedVerseNotification, notificationModelToJson(data));
  }

  static Future<NotificationStoreModel?>
      getLastCheckedVerseNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(Keys.lastCheckedVerseNotification);
    return data == null ? null : notificationModelFromJson(data);
  }

  static Future setLastCheckedChapterNotification(
      NotificationStoreModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Keys.lastCheckedChapterNotification, notificationModelToJson(data));
  }

  static Future<NotificationStoreModel?>
      getLastCheckedChapterNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(Keys.lastCheckedChapterNotification);
    return data == null ? null : notificationModelFromJson(data);
  }

  static Future setLastCompletedChapterNotification(
      NotificationStoreModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Keys.lastCompletedChapterNotification, notificationModelToJson(data));
  }

  static Future<NotificationStoreModel?>
      getLastCompletedChapterNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(Keys.lastCompletedChapterNotification);
    return data == null ? null : notificationModelFromJson(data);
  }

  static Future setLastPlayedChapterNotification(
      NotificationStoreModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Keys.lastPlayedChapterNotification, notificationModelToJson(data));
  }

  static Future<NotificationStoreModel?>
      getLastPlayedChapterNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(Keys.lastPlayedChapterNotification);
    return data == null ? null : notificationModelFromJson(data);
  }

  static Future<DateTime> addAndGetNotificationTimeLastCheckedChapter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.storeNotificationTimesLastCheckedChapters);

    // Convert the stored strings to DateTime objects
    List<DateTime> dateTimes =
        stringList?.map((e) => DateTime.parse(e)).toList() ?? [];

    DateTime newValue = DateTime.now();

    // Add the new DateTime
    dateTimes.add(newValue);

    // Convert DateTime objects to ISO 8601 strings
    List<String> isoStrings = dateTimes
        .map((dateTime) => dateTime.toUtc().toIso8601String())
        .toList();

    // Store the updated list in SharedPreferences
    await prefs.setStringList(
        Keys.storeNotificationTimesLastCheckedChapters, isoStrings);

    // Calculate the average DateTime
    DateTime averageDateTime;
    if (dateTimes.isNotEmpty) {
      int timestampSum = dateTimes
          .map((dateTime) => dateTime.millisecondsSinceEpoch)
          .reduce((a, b) => a + b);
      int averageTimestamp = (timestampSum / dateTimes.length).round();
      averageDateTime = DateTime.fromMillisecondsSinceEpoch(averageTimestamp);

      if (averageDateTime.isAfter(newValue) == false) {
        // Calculate the day difference
        int dayDifference = newValue.difference(averageDateTime).inDays + 1;

        // Add the day difference + 1 day to the calculated date while keeping the same time
        DateTime futureTime =
            averageDateTime.add(Duration(days: dayDifference));

        log(averageDateTime.toString());

        averageDateTime = futureTime;
      }
    } else {
      averageDateTime = newValue;
    }

    return averageDateTime;
  }

  static Future<DateTime>
      addAndGetNotificationTimeLastCompletedChapter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.storeNotificationTimesLastCompletedChapters);

    // Convert the stored strings to DateTime objects
    List<DateTime> dateTimes =
        stringList?.map((e) => DateTime.parse(e)).toList() ?? [];

    DateTime newValue = DateTime.now();

    // Add the new DateTime
    dateTimes.add(newValue);

    // Convert DateTime objects to ISO 8601 strings
    List<String> isoStrings = dateTimes
        .map((dateTime) => dateTime.toUtc().toIso8601String())
        .toList();

    // Store the updated list in SharedPreferences
    await prefs.setStringList(
        Keys.storeNotificationTimesLastCompletedChapters, isoStrings);

    // Calculate the average DateTime
    DateTime averageDateTime;
    if (dateTimes.isNotEmpty) {
      int timestampSum = dateTimes
          .map((dateTime) => dateTime.millisecondsSinceEpoch)
          .reduce((a, b) => a + b);
      int averageTimestamp = (timestampSum / dateTimes.length).round();
      averageDateTime = DateTime.fromMillisecondsSinceEpoch(averageTimestamp);

      if (averageDateTime.isAfter(newValue) == false) {
        // Calculate the day difference
        int dayDifference = newValue.difference(averageDateTime).inDays + 1;

        // Add the day difference + 1 day to the calculated date while keeping the same time
        DateTime futureTime =
            averageDateTime.add(Duration(days: dayDifference));

        log(averageDateTime.toString());

        averageDateTime = futureTime;
      }
    } else {
      averageDateTime = newValue; // Default if the list is empty
    }

    return averageDateTime;
  }

  static Future<DateTime> addAndGetNotificationTimeLastCheckedVerses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.storeNotificationTimesLastCheckedChapters);

    DateTime newValue = DateTime.now();

    // Convert the stored strings to DateTime objects
    List<DateTime> dateTimes =
        stringList?.map((e) => DateTime.parse(e)).toList() ?? [];

    // Add the new DateTime
    dateTimes.add(newValue);

    // Convert DateTime objects to ISO 8601 strings
    List<String> isoStrings = dateTimes
        .map((dateTime) => dateTime.toUtc().toIso8601String())
        .toList();

    // Store the updated list in SharedPreferences
    await prefs.setStringList(
        Keys.storeNotificationTimesLastCheckedChapters, isoStrings);

    // Calculate the average DateTime
    DateTime averageDateTime;
    if (dateTimes.isNotEmpty) {
      int timestampSum = dateTimes
          .map((dateTime) => dateTime.millisecondsSinceEpoch)
          .reduce((a, b) => a + b);
      int averageTimestamp = (timestampSum / dateTimes.length).round();
      averageDateTime = DateTime.fromMillisecondsSinceEpoch(averageTimestamp);
      if (averageDateTime.isAfter(newValue) == false) {
        // Calculate the day difference
        int dayDifference = newValue.difference(averageDateTime).inDays + 1;

        // Add the day difference + 1 day to the calculated date while keeping the same time
        DateTime futureTime =
            averageDateTime.add(Duration(days: dayDifference));

        log(averageDateTime.toString());

        averageDateTime = futureTime;
      }
    } else {
      averageDateTime = newValue; // Default if the list is empty
    }

    return averageDateTime;
  }

  static Future<DateTime> addAndGetNotificationTimeLastPlayedChapter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime newValue = DateTime.now();
    List<String>? stringList =
        prefs.getStringList(Keys.storeNotificationTimesLastPlayedChapters);

    // Convert the stored strings to DateTime objects
    List<DateTime> dateTimes =
        stringList?.map((e) => DateTime.parse(e)).toList() ?? [];

    // Add the new DateTime
    dateTimes.add(newValue);

    // Convert DateTime objects to ISO 8601 strings
    List<String> isoStrings = dateTimes
        .map((dateTime) => dateTime.toUtc().toIso8601String())
        .toList();

    log(stringList.toString());

    // Store the updated list in SharedPreferences
    await prefs.setStringList(
        Keys.storeNotificationTimesLastPlayedChapters, isoStrings);

    // Calculate the average DateTime
    DateTime averageDateTime;
    if (dateTimes.isNotEmpty) {
      int timestampSum = dateTimes
          .map((dateTime) => dateTime.millisecondsSinceEpoch)
          .reduce((a, b) => a + b);
      int averageTimestamp = (timestampSum / dateTimes.length).round();
      averageDateTime = DateTime.fromMillisecondsSinceEpoch(averageTimestamp);

      if (averageDateTime.isAfter(newValue) == false) {
        // Calculate the day difference
        int dayDifference = newValue.difference(averageDateTime).inDays + 1;

        // Add the day difference + 1 day to the calculated date while keeping the same time
        DateTime futureTime =
            averageDateTime.add(Duration(days: dayDifference));

        log(averageDateTime.toString());

        averageDateTime = futureTime;
      }
    } else {
      averageDateTime = newValue.add(
        const Duration(days: 1),
      );
    }

    return averageDateTime;
  }

  static Future<DateTime> addAndGetNotificationTimeLastCompletedVerses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList =
        prefs.getStringList(Keys.storeNotificationTimesLastCompletedVerses);

    // Convert the stored strings to DateTime objects
    List<DateTime> dateTimes =
        stringList?.map((e) => DateTime.parse(e)).toList() ?? [];

    DateTime newValue = DateTime.now();

    // Add the new DateTime
    dateTimes.add(newValue);

    // Convert DateTime objects to ISO 8601 strings
    List<String> isoStrings = dateTimes
        .map((dateTime) => dateTime.toUtc().toIso8601String())
        .toList();

    // Store the updated list in SharedPreferences
    await prefs.setStringList(
        Keys.storeNotificationTimesLastCompletedVerses, isoStrings);

    // Calculate the average DateTime
    DateTime averageDateTime;
    if (dateTimes.isNotEmpty) {
      int timestampSum = dateTimes
          .map((dateTime) => dateTime.millisecondsSinceEpoch)
          .reduce((a, b) => a + b);
      int averageTimestamp = (timestampSum / dateTimes.length).round();
      averageDateTime = DateTime.fromMillisecondsSinceEpoch(averageTimestamp);

      if (averageDateTime.isAfter(newValue) == false) {
        // Calculate the day difference
        int dayDifference = newValue.difference(averageDateTime).inDays + 1;

        // Add the day difference + 1 day to the calculated date while keeping the same time
        DateTime futureTime =
            averageDateTime.add(Duration(days: dayDifference));

        log(averageDateTime.toString());

        averageDateTime = futureTime;
      }
    } else {
      averageDateTime = newValue; // Default if the list is empty
    }

    return averageDateTime;
  }
}
