import 'package:flutter/cupertino.dart';
import 'package:gita_app/services/storage_service.dart';
import 'package:gita_app/styles.dart';

class ThemeProvider extends ChangeNotifier {
  String theme = "System";
  bool isChanged = false;

  void themeFunc(String inputTheme) async {
    await JsonStorage.saveTheme(inputTheme);
    theme = inputTheme;
    isChanged = true;
    if (theme == "Light") {
      AppColors.applyBrightness(Brightness.light);
    } else if (theme == "Dark") {
      AppColors.applyBrightness(Brightness.dark);
    }
    notifyListeners();
  }

  int pageIndex = 0;
  void pageIndexFunc(int index) {
    pageIndex = index;
    notifyListeners();
  }
}
