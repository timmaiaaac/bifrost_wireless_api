import 'package:bifrost_wireless_api/src/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'bifrost_api.dart';

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
                          g2color = Theme.of(context).primaryColorDark;
                          frequencyToggle = Icon(
                            Icons.toggle_off,
                            size: 40,
                            color: Theme.of(context).primaryColorDark,
                          );
                          g5color = Theme.of(context).primaryColorLight;
                          is5g = false;
                          frequency = 0;
                        });
                      } else {
                        setState(() {
                          g2color = Theme.of(context).primaryColorLight;
                          frequencyToggle = Icon(
                            Icons.toggle_on,
                            size: 40,
                            color: Theme.of(context).primaryColorDark,
                          );
                          g5color = Theme.of(context).primaryColorDark;
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
                    successColor: Theme.of(context).primaryColorDark,
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
                        buttonColor = Theme.of(context).primaryColorDark;
                      });
                    },
                    onFail: () {
                      setState(() {
                        validKey = false;
                        buttonColor = Theme.of(context).primaryColorLight;
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
                          ieee,
                          context)
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
  bool isRoot = true;
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
          isRoot = wlan['isRoot'];
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
                    successColor: Theme.of(context).primaryColorDark,
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
                        buttonColor = Theme.of(context).primaryColorDark;
                      });
                    },
                    onFail: () {
                      setState(() {
                        validKey = false;
                        buttonColor = Theme.of(context).primaryColorLight;
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
                          widget.wlanList,
                          context)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Aplicar",
                      )
                    ],
                  ),
                ),
                Visibility(
                    visible: !isRoot,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 100, 10, 100),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900),
                          onPressed: () {
                            BifrostApi().deleteWireless(
                                widget.ip, widget.token, widget.id, context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Excluir",
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                              )
                            ],
                          ),
                        )))
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
              BifrostApi().newSession(
                  widget.ip, userInput.text, passInput.text, context);
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
  List wlanSettings = wifiInfo;
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
        Container(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: ElevatedButton(
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
            ))
      ],
    );
  }
}
