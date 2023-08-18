import 'dart:async';
import 'package:bifrost_wireless_api/bifrost_wireless_api.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String myIp = '192.168.1.1';
  Timer? myTimer;
  String? tryToken;
  BifrostApi bifrost = BifrostApi();
  updatePage() {
    myTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      tryToken = checkSessionActive;
      if (tryToken != null) {
        bifrost.getWireless(myIp, tryToken, context);
        if (checkWifiInfo) {
          setState(() {
            myTimer?.cancel();
            isLogged();
          });
        }
      }
    });
  }

  isLogged() {
    if (tryToken != null) {
      final token = tryToken ?? '0';
      return WlanView(myIp, token);
    } else {
      return Login(myIp);
    }
  }

  @override
  void initState() {
    updatePage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[isLogged()],
        ),
      ),
    );
  }
}
