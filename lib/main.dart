// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
// import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
// import 'package:menu_scan_web/Customer/Screen_Ui/Menu_screen.dart';
// // import 'dart:html' as html;
// import 'package:menu_scan_web/firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

//   // Get the id from the URL query parameter
//   // final uri = Uri.parse(html.window.location.href);
//   // final idFromQR = uri.queryParameters['id'] ?? 'unknown';

//   // runApp(MyApp(idFromQR: idFromQR));
//   runApp(MyApp(idFromQR: '2'));
// }

// class MyApp extends StatelessWidget {
//   final String idFromQR;

//   MyApp({required this.idFromQR});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Name Collector',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       // home: NamePage(idFromQR: idFromQR),
//       // home: MenuScreen(),
//       home: LoginPage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/Dashboard.dart';
import 'package:menu_scan_web/Admin_Pannel/ui/login.dart';
import 'package:menu_scan_web/Admin_Pannel/widgets/ItemListPageLang.dart';
import 'package:menu_scan_web/Customer/Screen_Ui/Menu_screen.dart';
import 'package:menu_scan_web/firebase_options.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  html.window.history.pushState(null, '', html.window.location.href);
  html.window.onPopState.listen((event) {
    html.window.history.pushState(null, '', html.window.location.href);
  });

  runApp(const MyApp(idFromQR: '2'));
}

class MyApp extends StatelessWidget {
  final String idFromQR;

  const MyApp({required this.idFromQR, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name Collector',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
