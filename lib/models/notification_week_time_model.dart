import 'package:flutter/material.dart';

class NotificationWeekTimeModel {
  final int dayOfTheWeek;
  final TimeOfDay timeOfDay;

  NotificationWeekTimeModel({
    required this.timeOfDay,
    required this.dayOfTheWeek,
  });
}
