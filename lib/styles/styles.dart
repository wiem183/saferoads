// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

class Styles {
  static Color scaffoldBackgroundColor = const Color(0xFFFAFBFC);   
  static Color defaultRedColor       = const Color(0xFF0A2540);     
  static Color defaultYellowColor    = const Color(0xFF0052FF);    
  static Color defaultBlueColor      = const Color(0xFF00C2FF);     
  static Color defaultGreyColor      = const Color(0xFF425466);     
  static Color defaultLightGreyColor = const Color(0xFFF1F4F9);     
  static Color defaultLightWhiteColor= const Color(0xFFFFFFFF);    



  static Color darkScaffoldBackgroundColor = const Color(0xFF0A0E1A); 
  static Color darkDefaultRedColor       = const Color(0xFF5E7CE2); 
  static Color darkDefaultYellowColor    = const Color(0xFF4DA6FF); 
  static Color darkDefaultBlueColor      = const Color(0xFF1ACFFF); 
  static Color darkDefaultGreyColor      = const Color(0xFF8C9BA5); 
  static Color darkDefaultLightGreyColor = const Color(0xFF1C2128); 
  static Color darkDefaultLightWhiteColor= const Color(0xFFE5E9F0); 

  static double defaultPadding = 18.0;

  static BorderRadius defaultBorderRadius = BorderRadius.circular(20);

  static ScrollbarThemeData scrollbarTheme = const ScrollbarThemeData().copyWith(
    thumbColor: WidgetStateProperty.all(defaultYellowColor),
    trackColor: WidgetStateProperty.all(const Color(0xFFBBBBBB)),
    trackVisibility: const WidgetStatePropertyAll(true),
    thumbVisibility: WidgetStateProperty.all(false),
    interactive: true,
    thickness: WidgetStateProperty.all(10.0),
    radius: const Radius.circular(20),
  );

  static var cardBackgroundColor;

  static var darkDefaultLightBlueColor;

  static var darkDefaultGreenColor;

  static var darkDefaultPinkColor; 
}