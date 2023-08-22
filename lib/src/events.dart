import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:get_it/get_it.dart' show GetIt;

IEventBus eventBus = EventBus();

get checkSessionActive {
  if (GetIt.I.isRegistered<SetToken>()) {
    //ToDO add session activity, if session is closed return to login with session expired msg
    return GetIt.I.get<SetToken>().token;
  } else {
    return null;
  }
}

get checkWifiInfo {
  return GetIt.I.isRegistered<WlanInfo>();
}

get wifiInfo {
  return GetIt.I.get<WlanInfo>().wlanCompleteInfo;
}

class SetToken {
  String token;
  SetToken(this.token);
}

class WlanInfo {
  List wlanCompleteInfo = [];
  WlanInfo(this.wlanCompleteInfo);
}
