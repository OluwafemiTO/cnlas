import 'dart:convert';
import 'package:cnlas/config/config.dart';
import 'package:cnlas/util/authService.util.dart';
import 'package:http/http.dart' as http;

class DetailsApi {
  final String baseUrl = "${Config.baseUrl}/details";
  final jwt = AuthService();

  Future<int> inputDetails(String email, String department, String officeBuilding, String officeNumber) async {
  final token = await jwt.getToken(); // Add token
  
  if (token == null) {
    throw Exception('No authentication token found');
  }
  
  final response = await http.post(
    Uri.parse("$baseUrl/user-details"),
    headers: {
      'Authorization': 'Bearer $token', // Add this
      'Content-Type': 'application/json'
    },
    body: jsonEncode({
      "email": email,
      "department": department,
      "officeBuilding": officeBuilding,
      "officeNumber": officeNumber
    })
  );
  
  if (response.statusCode == 201) {
    await jwt.saveDetailsInput(true); // Add await
    return response.statusCode;
  } else {
    throw Exception("Failed to register: ${response.body}");
  }
}

  // Update these methods to match the TypeScript response structure

Future<List<String>> getLocationNames() async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/locations"),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['success'] == true) {
        List<dynamic> data = jsonResponse['data'];
        // Extract the 'Name' field which corresponds to officeBuilding
        return data.map((item) => item['Name'] as String).toList();
      } else {
        throw Exception(jsonResponse['error']['message']);
      }
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['error']['message'] ?? 'Failed to load locations');
    }
  } catch (err) {
    throw Exception('Failed to load locations: $err');
  }
}

Future<List<String>> getDepartmentNames() async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/departments"),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['success'] == true) {
        List<dynamic> data = jsonResponse['data'];
        // TypeScript returns simple array of strings: ["Computer Science", "Mathematics", ...]
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception(jsonResponse['error']['message']);
      }
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['error']['message'] ?? 'Failed to load departments');
    }
  } catch (err) {
    throw Exception('Failed to load departments: $err');
  }
}

  Future<Map<String, dynamic>> getLecturerDetails(String name) async {
  try {
    final token = await jwt.getToken(); // Add token
    final response = await http.post(
      Uri.parse("$baseUrl/lecturer"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      } else {
        throw Exception(jsonResponse['error']['message']);
      }
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['error']['message'] ?? 'Failed to load lecturer details');
    }
  } catch (err) {
    throw Exception('Failed to load lecturer details: $err');
  }
}

  Future<List<Map<String, dynamic>>> getLecturersAndLocations() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/lecturers-and-locations"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          // Return the full list of objects
          print(data.map((item) => item as Map<String, dynamic>).toList());
          return data.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['error']['message'] ?? 'Failed to load data');
      }
    } catch (err) {
      throw Exception('Failed to load lecturers and locations: $err');
    }
  }
}