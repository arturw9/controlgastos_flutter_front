import 'package:flutter/material.dart';

class TemaProvider with ChangeNotifier {
  // O valor de _themeMode já é do tipo ThemeMode, o que está correto
  ThemeMode _themeMode = ThemeMode.light;

  // Getter para acessar o tema
  ThemeMode get themeMode => _themeMode;

  // Método para alternar o tema
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
