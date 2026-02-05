import 'dart:io';

class Config {
  static String get baseUrl {
    // Replace with your actual computer's IP address
    const localIP = "10.177.67.213"; // CHANGE THIS TO YOUR IP
    
    if (Platform.isAndroid || Platform.isIOS) {
      // For physical devices, use your computer's local IP
      return "http://$localIP:3000/api";
    } else {
      // For web or desktop
      return "http://localhost:3000/api";
    }
  }
}