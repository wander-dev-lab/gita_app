import 'dart:developer';

import 'package:flutter/cupertino.dart';

class TTSProvider extends ChangeNotifier {
  int _wordIndex = -1;
  int get wordIndex => _wordIndex;
  void wordIndexIncrease() {
    ++_wordIndex;
    notifyListeners();
  }

  void wordIndexReset() {
    _wordIndex = -1;
    notifyListeners();
  }

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  void playingStatusUpdate(bool status) {
    _isPlaying = status;
    log(_isPlaying.toString());
    notifyListeners();
  }

  List<String> _lyricsWordsEnglish = [];
  List<String> get lyricsWordsEnglish => _lyricsWordsEnglish;
  void setLyricsWordsEnglish(List<String> words) {
    _lyricsWordsEnglish = words;
    notifyListeners();
  }

  void resetLyricsWordsEnglish() {
    _lyricsWordsEnglish.clear();
    notifyListeners();
  }

  int _chapterID = -1;
  int get chapterID => _chapterID;
  void setChapterID(int id) {
    _chapterID = id;
    log("set chapter id : $id");
    notifyListeners();
  }

  void resetChapterID() {
    _chapterID = -1;
    notifyListeners();
  }

  String _chapterName = "";
  String get chapterName => _chapterName;
  void setChapterName(String name) {
    _chapterName = name;
    log("set channel name");
    notifyListeners();
  }

  void resetChapterName() {
    _chapterName = "";
    notifyListeners();
  }

  bool _isCompleted = false;

  bool get isCompleted => _isCompleted;

  void setCompleteStatus(bool status) {
    _isCompleted = status;
    notifyListeners();
  }

  void resetCompleteStatus() {
    _isCompleted = false;
    notifyListeners();
  }

  bool _isLyricsCompleted = false;

  bool get isLyricsCompleted => _isLyricsCompleted;

  void setLyricsCompleteStatus(bool status) {
    _isLyricsCompleted = status;
    notifyListeners();
  }

  void resetLyricsCompleteStatus() {
    _isLyricsCompleted = false;
    notifyListeners();
  }

  String _chapterSummary = "";
  String get chapterSummary => _chapterSummary;
  void setChapterSummary(String summary) {
    _chapterSummary = summary;
    notifyListeners();
  }

  String _chapterSummaryLang = "english";
  String get chapterSummaryLang => _chapterSummaryLang;
  void setChapterSummaryLang(String lang) {
    _chapterSummaryLang = lang;
    notifyListeners();
  }
}
