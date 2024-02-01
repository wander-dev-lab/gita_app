import 'package:flutter/material.dart';

import '../styles.dart';

class AppTaskSnackBar {
  SnackBar customizedSnackbarForTasks({
    required BuildContext streamContext,
    required int listIndex,
    required String firestoreEmail,
    required VoidCallback onPressed,
  }) {
    return SnackBar(
      margin: EdgeInsets.only(
        bottom: 30,
        left: MediaQuery.of(streamContext).size.width / 10,
        right: MediaQuery.of(streamContext).size.width / 10,
      ),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: AppColors.mainColor,
      content: const Text(
        "This event is already outdated, Please",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      action: SnackBarAction(
        textColor: AppColors.white,
        label: "Edit",
        onPressed: onPressed,
      ),
    );
  }
}

class AppSnackbar {
  SnackBar customizedAppSnackbar({
    required String message,
    required BuildContext context,
  }) {
    return SnackBar(
      margin: EdgeInsets.only(
        bottom: 30,
        left: MediaQuery.of(context).size.width / 10,
        right: MediaQuery.of(context).size.width / 10,
      ),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: AppColors.mainColor,
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
