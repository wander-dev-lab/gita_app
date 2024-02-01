// To parse this JSON data, do
//
//     final voiceModel = voiceModelFromJson(jsonString);

import 'dart:convert';

VoiceModel voiceModelFromJson(String str) =>
    VoiceModel.fromJson(json.decode(str));

String voiceModelToJson(VoiceModel data) => json.encode(data.toJson());

class VoiceModel {
  String name;
  String locale;

  VoiceModel({
    required this.name,
    required this.locale,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) => VoiceModel(
        name: json["name"],
        locale: json["locale"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "locale": locale,
      };
}
