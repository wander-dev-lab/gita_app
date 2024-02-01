// To parse this JSON data, do
//
//     final sharedLinesModel = sharedLinesModelFromJson(jsonString);

import 'dart:convert';

TranslationModel translationModelFromJson(String str) =>
    TranslationModel.fromJson(json.decode(str));

String translationModelToJson(TranslationModel data) =>
    json.encode(data.toJson());

class TranslationModel {
  String eng;
  String san;
  String hin;

  TranslationModel({
    required this.eng,
    required this.san,
    required this.hin,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) =>
      TranslationModel(
        eng: json["eng"],
        san: json["san"],
        hin: json["hin"],
      );

  Map<String, dynamic> toJson() => {
        "eng": eng,
        "san": san,
        "hin": hin,
      };
}
