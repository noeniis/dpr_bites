import 'dart:io';

String getBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2/dpr_bites_api';
  } else {
    return 'http://192.168.1.5/dpr_bites_api';
  }
}
