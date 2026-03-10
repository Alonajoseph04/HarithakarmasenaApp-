import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await globalTheme.loadFromStorage();
  runApp(const HKSApp());
}

class HKSApp extends StatefulWidget {
  const HKSApp({super.key});
  @override
  State<HKSApp> createState() => _HKSAppState();
}

class _HKSAppState extends State<HKSApp> {
  late final AuthProvider _auth;
  late final LanguageProvider _lang;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _lang = globalLang;
    _auth.loadFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _lang),
        ChangeNotifierProvider.value(value: globalTheme),
      ],
      child: ListenableBuilder(
        listenable: globalTheme,
        builder: (ctx, _) => MaterialApp.router(
          title: 'Haritha Karma Sena',
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: globalTheme.mode,
          routerConfig: buildRouter(_auth),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
