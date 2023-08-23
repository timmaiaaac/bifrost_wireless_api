import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart' show GetIt;
import 'dart:convert';

import 'events.dart';

class BifrostApi {
  List wlanBodyKeys = [
    'ssid',
    'enabled',
    'key',
  ];

//Store the bearer token in an external variable by event call,
//this optimize the token uses after the generate
//To use the token call GetIt.I.get<SetToken>().token
  newSession(ip, user, password, context) async {
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
      _showMyDialog('Erro', response.body, context);
    }
  }

//Store the wlan info in an external variable by event call,
//this optimize the uses after the generate
//To use the wlan info call GetIt.I.get<WlanInfo>().wlanCompleteInfo
  getWireless(ip, token, context) async {
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
    } else {
      _showMyDialog('Erro', response.body, context);
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
  modifyWireless(ip, token, id, Map changes, List wlanList, context) async {
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
        actionApply(ip, token, context);
      } else {
        _showMyDialog('Erro', response.body, context);
      }
    }
  }

  Future actionApply(ip, token, context) async {
    try {
      var response =
          await http.put(Uri.parse('http://$ip/api/v1/action/update'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token'
              },
              body: jsonEncode(<String, dynamic>{'actionID': 5}));

      if (response.statusCode == 200) {
        _showMyDialog('Success!', 'configurações salvas', context);
      } else {
        _showMyDialog('Error',
            'Request failed with status: ${response.statusCode}.', context);
      }
    } catch (e) {
      _showMyDialog('Error', e.toString(), context);
    }
  }

  deleteWireless(ip, token, id, context) async {
    var response = await http.delete(
      Uri.parse('http://$ip/api/v1/wireless/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
    if (response.statusCode == 200) {
      actionApply(ip, token, context);
    } else if (response.statusCode != 200) {
      _showMyDialog('Falha', response.body, context);
    }
  }

  setNewWireless(ip, token, frequency, ssid, key, ieee, context) async {
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
      actionApply(ip, token, context);
    } else {
      _showMyDialog('Erro', response.body, context);
    }
  }

  _showMyDialog(String title, String msg, context) {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(msg),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK')),
            ],
          );
        });
  }
}
