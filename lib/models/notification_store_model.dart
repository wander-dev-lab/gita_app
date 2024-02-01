// To parse this JSON data, do
//
//     final notificationModel = notificationModelFromJson(jsonString);

import 'dart:convert';

NotificationStoreModel notificationModelFromJson(String str) =>
    NotificationStoreModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationStoreModel data) =>
    json.encode(data.toJson());

class NotificationStoreModel {
  int id;
  int notificationId;

  NotificationStoreModel({
    required this.id,
    required this.notificationId,
  });

  factory NotificationStoreModel.fromJson(Map<String, dynamic> json) =>
      NotificationStoreModel(
        id: json["id"],
        notificationId: json["notificationID"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "notificationID": notificationId,
      };
}
