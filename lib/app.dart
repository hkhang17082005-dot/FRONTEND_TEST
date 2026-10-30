import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/settings/app_settings_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

class ChildDevicesApp extends StatefulWidget {
  const ChildDevicesApp({super.key});

  @override
  State<ChildDevicesApp> createState() => _ChildDevicesAppState();
}

class _ChildDevicesAppState extends State<ChildDevicesApp> {
  final _authController = AuthController();
  final _settingsController = AppSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _settingsController.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _settingsController.getTheme(),
          builder: (context, child) {
            return Container(
              color: _settingsController.currentBackgroundColor,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_settingsController.fontScale),
                ),
                child: child!,
              ),
            );
          },
          home: SplashScreen(authController: _authController),
        );
      },
    );
  }
}
