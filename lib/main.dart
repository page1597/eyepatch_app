import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:eyepatch_app/database/devices.dart';
import 'package:eyepatch_app/page/patchList.dart';
import 'package:eyepatch_app/style/palette.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'database/dbHelper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eye Patch Scan App',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const MyHomePage(title: 'Eye Patch Scan App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // getPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'EyePatch',
            style: TextStyle(fontSize: 20.0),
          ),
          foregroundColor: Palette.primary1,
          backgroundColor: Colors.white,
          elevation: 0.0,
          toolbarHeight: 70.0,
        ),
        body: const PatchList());
  }
}
