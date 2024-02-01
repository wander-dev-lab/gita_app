// To parse this JSON data, do
//
//     final voicesModel = voicesModelFromJson(jsonString);

import 'dart:convert';

List<VoicesModel> voicesModelFromJson(String str) => List<VoicesModel>.from(
    json.decode(str).map((x) => VoicesModel.fromJson(x)));

String voicesModelToJson(List<VoicesModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VoicesModel {
  String name;
  String locale;

  VoicesModel({
    required this.name,
    required this.locale,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoicesModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          locale == other.locale;

  @override
  int get hashCode => name.hashCode ^ locale.hashCode;

  factory VoicesModel.fromJson(Map<String, dynamic> json) => VoicesModel(
        name: json["name"],
        locale: json["locale"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "locale": locale,
      };
}
