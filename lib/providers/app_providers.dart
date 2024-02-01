import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class AllAppProviders extends ChangeNotifier {
  String selectedType = 'Personal';
  void selectedTypeFunc(String selected) async {
    selectedType = selected;
    notifyListeners();
  }

  bool taskNameTapped = false;
  void taskNameTappedFunc(bool tapped) async {
    taskNameTapped = tapped;
    notifyListeners();
  }

  String dateAndTimeText = '';
  void dateAndTimeTextFunc(String dateTime) async {
    dateAndTimeText = dateTime;
    notifyListeners();
  }

  String dateText = "";
  void dateTextFunc(String date) async {
    dateText = date;
    notifyListeners();
  }

  String timeText = "";
  void timeTextFunc(String time) async {
    timeText = time;
    notifyListeners();
  }

  bool newTaskUploadLoading = false;
  void newTaskUploadLoadingFunc(bool loading) async {
    newTaskUploadLoading = loading;
    notifyListeners();
  }

  int inboxCount = 0;
  void inboxCountFunc(int count) {
    inboxCount = count;
    notifyListeners();
  }

  int doneCount = 0;
  void doneCountFunc(int count) {
    doneCount = count;
    notifyListeners();
  }

  int pendingCount = 0;
  void pendingCountFunc(int count) {
    pendingCount = count;
    notifyListeners();
  }

  bool optionsVisible = false;
  void optionsVisibleFunc(bool options) async {
    optionsVisible = options;
    notifyListeners();
  }

  bool isLoading = false;
  void isLoadingFunc(bool load) async {
    isLoading = load;
    notifyListeners();
  }

  bool passVisibility = true;
  void passVisibilityFunc(bool visibility) {
    passVisibility = visibility;
    notifyListeners();
  }

  bool passConfirmVisibility = true;
  void passConfirmVisibilityFunc(bool visibility) {
    passConfirmVisibility = visibility;
    notifyListeners();
  }

  String phCode = "+91";
  void phCodeFunc(String code) {
    phCode = code;
    notifyListeners();
  }

  String phNumber = "";
  void phNumberFunc(String number) {
    phNumber = number;
    notifyListeners();
  }

  String des = "";
  void desFunc(String customDes) {
    des = customDes;
    notifyListeners();
  }

  String keySkill = "";
  void keySkillFunc(String customKeySkill) {
    keySkill = customKeySkill;
    notifyListeners();
  }

  int desPosition = 0;
  void desLengthFunc(position) {
    desPosition = position;
    notifyListeners();
  }

  int namePosition = 0;
  void nameLengthFunc(position) {
    namePosition = position;
    notifyListeners();
  }

  // int points = 0;
  // void pointsFunc() async {
  //   points = await StorageServices.getUsrPoints();
  //   notifyListeners();
  // }

  bool isImageSelected = false;
  void isImageSelectedFunc(bool selected) {
    isImageSelected = selected;
    notifyListeners();
  }

  int notificationCount = 0;
  void notificationCountFunc() async {
    await AwesomeNotifications().listScheduledNotifications().then((value) {
      notificationCount = value.length;
      notifyListeners();
    });
  }

  String category = "";
  void categoryFunc(String inputCategory) async {
    category = inputCategory;
    notifyListeners();
  }

  String hashtag = "";
  void hashtagFunc(String inputHashtag) async {
    hashtag = inputHashtag;
    notifyListeners();
  }

  int catCount = 0;
  void categoryCountFunc(int inputCatCount) async {
    catCount = inputCatCount;
    notifyListeners();
  }

  bool expanded = false;
  void isExpandedFunc(bool isExpanded) {
    expanded = isExpanded;
    notifyListeners();
  }
}
