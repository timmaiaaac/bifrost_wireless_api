library bifrost_wireless_api;

export 'package:bifrost_wireless_api/bifrost_wireless_api.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart' show GetIt;
import 'dart:convert';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';

class SetToken {
  String token;
  SetToken(this.token);
}

class WlanInfo {
  List wlanCompleteInfo = [];
  WlanInfo(this.wlanCompleteInfo);
}

class BifrostApi {
  List wlanBodyKeys = [
    'ssid',
    'enabled',
    'key',
  ];

//Store the bearer token in an external variable by event call,
//this optimize the token uses after the generate
//To use the token call GetIt.I.get<SetToken>().token
  newSession(ip, user, password) async {
    var response = await http.post(Uri.parse('http://$ip/api/v1/session'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'username': user, 'password': password}));
    if (response.statusCode == 200) {
      final token = json.decode(response.body)['token'];

      if (!GetIt.I.isRegistered<SetToken>()) {
        GetIt.I.registerSingleton<SetToken>(SetToken(token));
        GetIt.I.allowReassignment;
      }
      if (token != GetIt.I.get<SetToken>().token) {
        GetIt.I.reset();
        GetIt.I.registerSingleton<SetToken>(SetToken(token));
      }
    } else {
      //print(response.body);
    }
  }

//Store the wlan info in an external variable by event call,
//this optimize the uses after the generate
//To use the wlan info call GetIt.I.get<WlanInfo>().wlanCompleteInfo
  getWireless(ip, token) async {
    var response = await http.get(
      Uri.parse('http://$ip/api/v1/wireless'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
    if (response.statusCode == 200) {
      final resp = json.decode(response.body);
      if (!GetIt.I.isRegistered<WlanInfo>()) {
        GetIt.I.registerSingleton<WlanInfo>(WlanInfo(resp));
        GetIt.I.allowReassignment;
      }
      if (resp != GetIt.I.get<WlanInfo>().wlanCompleteInfo) {
        GetIt.I.reset();
        GetIt.I.registerSingleton<WlanInfo>(WlanInfo(resp));
      }
    }
  }

  //Using the wlanCompleteInfo we can find the ID to modify an wireless setting
  //this ID is important to set the correct wlan. in Changes we can change the
  //SSID, the password (key), and the enable status. the other parameters are
  //not editable by this method to simplify the use, in the future we can add
  //another method to set advanced settings.
  //The enable change will turn off the wireless radio of this ssid, if you
  //turn off both 2.4G and 5G radios you will stay without wi-fi, then it is not
  //recommendable, but in some cases we need to turn off the 5G to set some IOT
  //equipament.
  modifyWireless(ip, token, id, Map changes, List wlanList) async {
    Map<String, dynamic> wlanToModify = {};
    bool keysOk = false;
    for (Map<String, dynamic> wlan in wlanList) {
      if (id == wlan['id']) {
        wlanToModify = wlan;
      }
    }

    changes.forEach((key, value) {
      if (wlanBodyKeys.contains(key)) {
        keysOk = true;
      }
    });

    if (changes.containsKey('key')) {
      wlanToModify['key'] = changes['key'];
      wlanToModify['cipher'] = 3;
      wlanToModify['crypto'] = 2;
    }
    wlanToModify['ssid'] = changes['ssid'];
    if (keysOk) {
      var response = await http.put(Uri.parse('http://$ip/api/v1/wireless/$id'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(wlanToModify));
      if (response.statusCode == 200) {
        actionApply(ip, token);
      } else {
        //print(response.body);
      }
    }
  }

  Future actionApply(ip, token) async {
    try {
      var response =
          await http.put(Uri.parse('http://$ip/api/v1/action/update'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token'
              },
              body: jsonEncode(<String, dynamic>{'actionID': 5}));

      if (response.statusCode == 200) {
        //print('Success!');
      } else {
        //print('Request failed with status: ${response.statusCode}.');
      }

      //print('Network error occurred: ${e.message}');
    } catch (e) {
      //print('Error: $e');
    }
  }

  setNewWireless(ip, token, frequency, ssid, key, ieee) async {
    String radio = 'radio0';
    if (frequency == 0) {
      radio = 'radio1';
    }
    var response = await http.post(Uri.parse('http://$ip/api/v1/wireless'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(<String, dynamic>{
          'id': "", //
          'ssid': ssid, //
          'sameSSID': false, //
          'ssid_5': "",
          'enabled': true, //
          'wps': false, //
          'broadcast': true,
          'cipher': 3,
          'crypto': 2,
          'frequency': frequency, //
          'interfaceID': "", //
          'isRoot': false, //
          'key': key, //
          'radioID': radio, //
          'ieee_std': ieee, //
        }));
    if (response.statusCode == 200) {
      actionApply(ip, token);
    } else {
      //print(response.body);
    }
  }
}

class AddWireless extends StatefulWidget {
  const AddWireless(this.ip, this.token, this.wlanList, {Key? key})
      : super(key: key);
  final String ip;
  final String token;
  final List wlanList;
  @override
  State<AddWireless> createState() => _AddWirelessState();
}

class _AddWirelessState extends State<AddWireless> {
  bool passwordVisible = false;
  bool validKey = false;
  Color buttonColor = Colors.grey;
  final GlobalKey<FlutterPwValidatorState> validatorKey =
      GlobalKey<FlutterPwValidatorState>();
  final passInput = TextEditingController();
  final netNameInput = TextEditingController();
  Color g5color = Colors.blue;
  Color g2color = Colors.grey;
  Icon frequencyToggle = const Icon(
    Icons.toggle_on,
    size: 40,
    color: Colors.blue,
  );
  bool is5g = true;
  int frequency = 1;
  int ieee = 8;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: LayoutBuilder(builder: (context, constraints) {
          return Container(
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              margin: const EdgeInsets.fromLTRB(8, 8, 2, 8),
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: Column(children: [
                Row(children: [
                  Text(
                    '2.4GHz',
                    style: TextStyle(color: g2color),
                  ),
                  IconButton(
                    icon: frequencyToggle,
                    onPressed: () {
                      if (is5g) {
                        setState(() {
                          g2color = Colors.blue;
                          frequencyToggle = const Icon(
                            Icons.toggle_off,
                            size: 40,
                            color: Colors.blue,
                          );
                          g5color = Colors.grey;
                          is5g = false;
                          frequency = 0;
                        });
                      } else {
                        setState(() {
                          g2color = Colors.grey;
                          frequencyToggle = const Icon(
                            Icons.toggle_on,
                            size: 40,
                            color: Colors.blue,
                          );
                          g5color = Colors.blue;
                          is5g = true;
                          frequency = 1;
                        });
                      }
                    },
                  ),
                  Text('  5GHz', style: TextStyle(color: g5color))
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'SSID',
                    ),
                    controller: netNameInput,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                    controller: passInput,
                  ),
                ),
                FlutterPwValidator(
                    key: validatorKey,
                    controller: passInput,
                    minLength: 8,
                    uppercaseCharCount: 1,
                    lowercaseCharCount: 1,
                    numericCharCount: 1,
                    specialCharCount: 1,
                    normalCharCount: 0,
                    width: 400,
                    height: 140,
                    onSuccess: () {
                      setState(() {
                        validKey = true;
                        buttonColor = Colors.blue;
                      });
                    },
                    onFail: () {
                      setState(() {
                        validKey = false;
                        buttonColor = Colors.grey;
                      });
                      //print("NOT MATCHED");
                    }),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                  onPressed: validKey
                      ? () => BifrostApi().setNewWireless(
                          widget.ip,
                          widget.token,
                          frequency,
                          netNameInput.text,
                          passInput.text,
                          ieee)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Aplicar",
                      )
                    ],
                  ),
                )
              ]));
        }));
  }
}

//this widget will show a container with box to edit the ssid and password
//of the wlan id passed in the id parameter
class WirelessModifier extends StatefulWidget {
  const WirelessModifier(this.ip, this.token, this.id, this.wlanList,
      {Key? key})
      : super(key: key);

  final String ip;
  final String token;
  final String id;
  final List wlanList;
  @override
  State<WirelessModifier> createState() => _WirelessModifierState();
}

class _WirelessModifierState extends State<WirelessModifier> {
  bool passwordVisible = false;
  bool validKey = false;
  Color buttonColor = Colors.grey;
  final GlobalKey<FlutterPwValidatorState> validatorKey =
      GlobalKey<FlutterPwValidatorState>();
  final passInput = TextEditingController();
  final netNameInput = TextEditingController();
  @override
  void initState() {
    selectWlan();
    super.initState();
  }

  selectWlan() {
    for (Map wlan in widget.wlanList) {
      if (wlan['id'] == widget.id) {
        setState(() {
          passInput.text = wlan['key'];
          netNameInput.text = wlan['ssid'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: LayoutBuilder(builder: (context, constraints) {
          return Container(
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              margin: const EdgeInsets.fromLTRB(8, 8, 2, 8),
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'SSID',
                    ),
                    controller: netNameInput,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                    controller: passInput,
                  ),
                ),
                FlutterPwValidator(
                    key: validatorKey,
                    controller: passInput,
                    minLength: 8,
                    uppercaseCharCount: 1,
                    lowercaseCharCount: 1,
                    numericCharCount: 1,
                    specialCharCount: 1,
                    normalCharCount: 0,
                    width: 400,
                    height: 140,
                    onSuccess: () {
                      setState(() {
                        validKey = true;
                        buttonColor = Colors.blue;
                      });
                    },
                    onFail: () {
                      setState(() {
                        validKey = false;
                        buttonColor = Colors.grey;
                      });
                      //print("NOT MATCHED");
                    }),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                  onPressed: validKey
                      ? () => BifrostApi().modifyWireless(
                          widget.ip,
                          widget.token,
                          widget.id,
                          {'ssid': netNameInput.text, 'key': passInput.text},
                          widget.wlanList)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Aplicar",
                      )
                    ],
                  ),
                )
              ]));
        }));
  }
}

//this widget will show a container with box to put user and password to
//login in CPE
class Login extends StatefulWidget {
  const Login(this.ip, {Key? key}) : super(key: key);
  final String ip;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool passwordVisible = false;
  final passInput = TextEditingController();
  final userInput = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.fromLTRB(8, 8, 2, 8),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Usuário',
              ),
              controller: userInput,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              obscureText: !passwordVisible,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    // Based on passwordVisible state choose the icon
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    // Update the state i.e. toogle the state of passwordVisible variable
                    setState(() {
                      passwordVisible = !passwordVisible;
                    });
                  },
                ),
              ),
              controller: passInput,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              BifrostApi()
                  .newSession(widget.ip, userInput.text, passInput.text);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Login",
                )
              ],
            ),
          )
        ]));
  }
}

//this widget will show a container with a list of buttons of the all wireless
//setted
class WlanView extends StatefulWidget {
  const WlanView(this.ip, this.token, {Key? key}) : super(key: key);
  final String ip;
  final String token;
  @override
  State<WlanView> createState() => _WlanViewState();
}

class _WlanViewState extends State<WlanView> {
  List wlanSettings = GetIt.I.get<WlanInfo>().wlanCompleteInfo;
  late GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
            children: List.generate(
                wlanSettings.length,
                (index) => ListTile(
                      dense: true,
                      title: TextButton(
                        child: Text(wlanSettings[index]["ssid"],
                            style: const TextStyle(
                              fontSize: 16.0,
                            )),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (BuildContext context) {
                            return WirelessModifier(widget.ip, widget.token,
                                wlanSettings[index]['id'], wlanSettings);
                          }));
                        },
                      ),
                    ))),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return AddWireless(widget.ip, widget.token, wlanSettings);
            }));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_circle_outline),
              Text(
                "Add Wifi",
              )
            ],
          ),
        )
      ],
    );
  }
}
