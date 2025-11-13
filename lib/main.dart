// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covoiturage_app/onboarding/onboarding_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'controllers/announcement_controller.dart';
import 'controllers/reservation_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/blog_controller.dart';
import 'styles/styles.dart';
import 'services/storage_service.dart';
import 'screens/signalements_map_screen.dart';
import 'screens/blog_feed_screen.dart';
import 'screens/bookmarks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  await StorageService.init();

  // 💡 Passe le numéro du téléphone de l’utilisateur (ou autre identifiant)
  await initFCMAndSaveToken(phone: "93739324");

  runApp(const MyApp());
}

/// 🔹 Enregistre le token FCM du client dans Firestore
Future<void> initFCMAndSaveToken({required String phone}) async {
  final messaging = FirebaseMessaging.instance;

  // 🔔 Demande la permission d’envoyer des notifications
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 🧠 Récupération du token unique FCM
  final token = await messaging.getToken();

  if (token != null) {
    print("📲 Token FCM : $token");

    // ✅ Sauvegarde du token dans Firestore
    await FirebaseFirestore.instance.collection('fcm_tokens').doc(phone).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } else {
    print("⚠️ Aucun token FCM trouvé !");
  }

  // 🔁 Rafraîchissement automatique si le token change
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔁 Nouveau token FCM détecté : $newToken");
    await FirebaseFirestore.instance.collection('fcm_tokens').doc(phone).set({
      'token': newToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AnnouncementController()),
        ChangeNotifierProvider(create: (_) => ReservationController()),
        ChangeNotifierProvider(create: (_) => BlogController()),
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
            bodyMedium: TextStyle(fontSize: 16, color: Styles.defaultRedColor),
            bodySmall: TextStyle(fontSize: 12, color: Styles.defaultGreyColor),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.defaultBlueColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: Styles.defaultPadding,
                vertical: Styles.defaultPadding / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
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
              padding: EdgeInsets.symmetric(
                horizontal: Styles.defaultPadding,
                vertical: Styles.defaultPadding / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
            ),
          ),
          scrollbarTheme: Styles.scrollbarTheme.copyWith(
            thumbColor: WidgetStateProperty.all(Styles.darkDefaultYellowColor),
            trackColor: WidgetStateProperty.all(Styles.darkDefaultGreyColor),
          ),
        ),
        themeMode: ThemeMode.system,
        home: OnboardingWrapper(),
        routes: {
          '/signalements': (context) => SignalementsMapScreen(),
          '/blog': (context) => const BlogFeedScreen(),
          '/bookmarks': (context) => const BookmarksScreen(),
        },
      ),
    );
  }
}
