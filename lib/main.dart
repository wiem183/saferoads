import 'package:covoiturage_app/onboarding/onboarding_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/announcement_controller.dart';
import 'controllers/reservation_controller.dart';
import 'styles/styles.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementController()),
        ChangeNotifierProvider(create: (_) => ReservationController()),
      ],
      child: MaterialApp(
        title: 'Covoiturage App',
        debugShowCheckedModeBanner: false, 
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Styles.defaultBlueColor,
          scaffoldBackgroundColor: Styles.scaffoldBackgroundColor,
          cardColor: Styles.defaultLightGreyColor,
          textTheme: TextTheme(
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Styles.defaultRedColor,
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              color: Styles.defaultRedColor,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              color: Styles.defaultGreyColor,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.defaultBlueColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: Styles.defaultPadding, vertical: Styles.defaultPadding / 2),
              shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
            ),
          ),
          scrollbarTheme: Styles.scrollbarTheme,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Styles.darkDefaultBlueColor,
          scaffoldBackgroundColor: Styles.darkScaffoldBackgroundColor,
          cardColor: Styles.darkDefaultLightGreyColor,
          textTheme: TextTheme(
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Styles.darkDefaultLightWhiteColor,
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              color: Styles.darkDefaultLightWhiteColor,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              color: Styles.darkDefaultGreyColor,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.darkDefaultBlueColor,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: Styles.defaultPadding, vertical: Styles.defaultPadding / 2),
              shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
            ),
          ),
          scrollbarTheme: Styles.scrollbarTheme.copyWith(
            thumbColor: WidgetStateProperty.all(Styles.darkDefaultYellowColor),
            trackColor: WidgetStateProperty.all(Styles.darkDefaultGreyColor),
          ),
        ),
        themeMode: ThemeMode.system,
        home:  OnboardingWrapper(),
      ),
    );
  }
}