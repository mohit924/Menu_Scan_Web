import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
import 'package:menu_scan_web/Customer/Screen_Ui/Menu_screen.dart';
import 'package:menu_scan_web/firebase_options.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  final uri = Uri.parse(html.window.location.href);

  // Query parameters for customer QR
  final hotelID = uri.queryParameters['hotelID'];
  final tableID = uri.queryParameters['tableID'];

  // Get saved hotelID from local storage (SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  final savedHotelID = prefs.getString('hotelID');

  runApp(MyApp(hotelID: hotelID, tableID: tableID, savedHotelID: savedHotelID));
}

class MyApp extends StatelessWidget {
  final String? hotelID;
  final String? tableID;
  final String? savedHotelID;

  const MyApp({this.hotelID, this.tableID, this.savedHotelID, super.key});

  @override
  Widget build(BuildContext context) {
    Widget home;

    if (savedHotelID != null && savedHotelID!.isNotEmpty) {
      home = AdminDashboardPage();
    } else if (hotelID != null && tableID != null) {
      home = MenuScreen(hotelID: hotelID!, tableID: tableID!);
    } else {
      // home = MenuScreen(hotelID: "UFKH", tableID: "2");

      home = const LoginPage();
    }

    return MaterialApp(
      title: 'Menu Scan',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
