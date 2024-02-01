// To parse this JSON data, do
//
//     final verseTranslationModel = verseTranslationModelFromJson(jsonString);

import 'dart:convert';

VerseTranslationModel verseTranslationModelFromJson(String str) =>
    VerseTranslationModel.fromJson(json.decode(str));

String verseTranslationModelToJson(VerseTranslationModel data) =>
    json.encode(data.toJson());

class VerseTranslationModel {
  String verseHindi;
  String verseEnglish;

  VerseTranslationModel({
    required this.verseHindi,
    required this.verseEnglish,
  });

  factory VerseTranslationModel.fromJson(Map<String, dynamic> json) =>
      VerseTranslationModel(
        verseHindi: json["verseHindi"],
        verseEnglish: json["verseEnglish"],
      );

  Map<String, dynamic> toJson() => {
        "verseHindi": verseHindi,
        "verseEnglish": verseEnglish,
      };
}
