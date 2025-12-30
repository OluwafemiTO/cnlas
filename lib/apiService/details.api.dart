import 'dart:convert';
import 'package:cnlas/util/authService.util.dart';
import 'package:http/http.dart' as http;

class DetailsApi {
  final String baseUrl = "http://localhost:3000/api/details";
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

  Future<List<String>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/locations"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          // Extract officeBuilding from each object
          return data.map((item) => item['officeBuilding'] as String).toList();
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

  Future<List<String>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/departments"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
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