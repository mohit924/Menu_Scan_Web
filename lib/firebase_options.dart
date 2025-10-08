import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBwvhBePuqMs1Ze1SN_w4ggz7f18oLJn1c",
    authDomain: "menu-scan-web.firebaseapp.com",
    projectId: "menu-scan-web",
    storageBucket: "menu-scan-web.appspot.com", // ✅ fixed here
    messagingSenderId: "8774055269",
    appId: "1:8774055269:web:29d073805a4653d0539d8c",
  );
}
