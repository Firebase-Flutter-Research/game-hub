import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/page/home.dart';
import 'package:flutter_fire_engine/page/in_game.dart';
import 'package:flutter_fire_engine/page/rooms.dart';
import 'package:flutter_fire_engine/page/tic_tac_toe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyAuPBkmxGQbpLoH2lhSBWQBLDgHahX-V-A",
          authDomain: "game-hub-2-283bb.firebaseapp.com",
          projectId: "game-hub-2-283bb",
          storageBucket: "game-hub-2-283bb.appspot.com",
          messagingSenderId: "304830683808",
          appId: "1:304830683808:web:ce7b8061ac46d9034587c5"));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => Home(),
        "/rooms": (context) => RoomsPage(),
        "/inGame": (context) => InGamePage(),
      },
    );
  }
}
