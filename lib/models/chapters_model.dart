// To parse this JSON data, do
//
//     final chaptersModel = chaptersModelFromJson(jsonString);

import 'dart:convert';

List<ChaptersModel> chaptersModelFromJson(String str) =>
    List<ChaptersModel>.from(
        json.decode(str).map((x) => ChaptersModel.fromJson(x)));

String chaptersModelToJson(List<ChaptersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ChaptersModel {
  int id;
  String name;
  String slug;
  String nameTransliterated;
  String nameTranslated;
  int versesCount;
  int chapterNumber;
  String nameMeaning;
  String chapterSummary;
  String chapterSummaryHindi;

  ChaptersModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.nameTransliterated,
    required this.nameTranslated,
    required this.versesCount,
    required this.chapterNumber,
    required this.nameMeaning,
    required this.chapterSummary,
    required this.chapterSummaryHindi,
  });

  factory ChaptersModel.fromJson(Map<String, dynamic> json) => ChaptersModel(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        nameTransliterated: json["name_transliterated"],
        nameTranslated: json["name_translated"],
        versesCount: json["verses_count"],
        chapterNumber: json["chapter_number"],
        nameMeaning: json["name_meaning"],
        chapterSummary: json["chapter_summary"],
        chapterSummaryHindi: json["chapter_summary_hindi"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "name_transliterated": nameTransliterated,
        "name_translated": nameTranslated,
        "verses_count": versesCount,
        "chapter_number": chapterNumber,
        "name_meaning": nameMeaning,
        "chapter_summary": chapterSummary,
        "chapter_summary_hindi": chapterSummaryHindi,
      };
}
