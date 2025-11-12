// ignore_for_file: use_super_parameters, unused_field

import 'package:covoiturage_app/screens/parking_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'history_screen.dart';
import 'search_screen.dart';
import 'driver_create_screen.dart';   
import 'my_rides_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _current = 0;
  int _selectedIndex = 0;


  final _pages = const [
    HistoryScreen(),     
    SearchScreen(),       
    DriverCreateScreen(),  
    MyRidesScreen(), 
    ParkingListScreen(),      
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _current = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.clock), label: 'Historique'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search), label: 'Rechercher'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.plus_app), label: 'Publier'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person), label: 'Mes trajets'),
              BottomNavigationBarItem(
  icon: Icon(Icons.local_parking),
  label: 'Parkings',
),

        ],
      ),
    );
  }
}