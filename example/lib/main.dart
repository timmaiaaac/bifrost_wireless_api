import 'dart:async';

import 'package:bifrost_wireless_api/bifrost_wireless_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show GetIt;

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
  updatePage() {
    myTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (GetIt.I.isRegistered<SetToken>()) {
        BifrostApi().getWireless(myIp, GetIt.I.get<SetToken>().token);
        if (GetIt.I.isRegistered<WlanInfo>()) {
          print(GetIt.I.get<WlanInfo>().wlanCompleteInfo.toString());
          setState(() {
            myTimer?.cancel();
            isLogged();
          });
        }
      }
    });
  }

  isLogged() {
    if (GetIt.I.isRegistered<SetToken>()) {
      return WlanView(myIp, GetIt.I.get<SetToken>().token);
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
