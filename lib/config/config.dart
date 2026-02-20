import 'dart:io';

class Config {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.118.120.251:3000/api";
    } else if (Platform.isIOS) {
      return "http://localhost:3000/api";
    } else {
      // For physical devices, use your computer's IP address
      return "http://10.118.120.251:3000/api"; // Replace with your IP
    }
  }
}