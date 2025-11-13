// ignore_for_file: use_super_parameters, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Screens from main branch
import 'driver_create_screen.dart';
import 'profile_screen.dart';
import 'signalements_map_screen.dart';

// Screens from Amendes branch
import 'history_screen.dart';
import 'search_screen.dart';
import 'my_rides_screen.dart';
import 'parking_list_screen.dart';
import 'amende_screens_example.dart';

import '../widgets/app_drawer.dart';
import '../styles/styles.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _current = 0;

  // Combined pages from both branches
  final _pages = [
    HistoryScreen(),                     // Amendes
    SearchScreen(),                      // Amendes
    DriverCreateScreen(),                // Main
    MyRidesScreen(),                     // Amendes
    ParkingListScreen(),                 // Amendes
    UserAmendesScreen(userId: 'current-user'), // Amendes
    ProfileScreen(),                      // Main
    SignalementsMapScreen(),             // Main
  ];

  final _pageTitles = const [
    'Historique',
    'Rechercher',
    'Publier un trajet',
    'Mes trajets',
    'Parkings',
    'Amendes',
    'Mon Profil',
    'Signalements'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_current],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Styles.darkDefaultLightWhiteColor : Styles.defaultRedColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Styles.darkDefaultBlueColor : Styles.defaultBlueColor,
        ),
      ),
      drawer: AppDrawer(
        onPageChanged: (index) {
          setState(() => _current = index);
        },
      ),
      body: _pages[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _current = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Rechercher',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.plus_app),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Mes trajets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_parking),
            label: 'Parkings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.traffic),
            label: 'Amendes',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Signalements',
          ),
        ],
      ),
    );
  }
}
