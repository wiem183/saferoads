import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'driver_create_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_drawer.dart';
import '../styles/styles.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _current = 0; // Commence avec DriverCreateScreen

  final _pages = const [DriverCreateScreen(), ProfileScreen()];

  final _pageTitles = const ['Publier un trajet', 'Mon Profil'];

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
            color: isDark
                ? Styles.darkDefaultLightWhiteColor
                : Styles.defaultRedColor,
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
            icon: Icon(CupertinoIcons.plus_app),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
