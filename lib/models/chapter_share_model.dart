// To parse this JSON data, do
//
//     final chapterShareModel = chapterShareModelFromJson(jsonString);

import 'dart:convert';

ChapterShareModel chapterShareModelFromJson(String str) =>
    ChapterShareModel.fromJson(json.decode(str));

String chapterShareModelToJson(ChapterShareModel data) =>
    json.encode(data.toJson());

class ChapterShareModel {
  String chapterIdHin;
  String chapterIdSan;
  String chapterNameHin;
  String chapterNameSan;

  ChapterShareModel({
    required this.chapterIdHin,
    required this.chapterIdSan,
    required this.chapterNameHin,
    required this.chapterNameSan,
  });

  factory ChapterShareModel.fromJson(Map<String, dynamic> json) =>
      ChapterShareModel(
        chapterIdHin: json["chapterIDHin"],
        chapterIdSan: json["chapterIDSan"],
        chapterNameHin: json["chapterNameHin"],
        chapterNameSan: json["chapterNameSan"],
      );

  Map<String, dynamic> toJson() => {
        "chapterIDHin": chapterIdHin,
        "chapterIDSan": chapterIdSan,
        "chapterNameHin": chapterNameHin,
        "chapterNameSan": chapterNameSan,
      };
}
