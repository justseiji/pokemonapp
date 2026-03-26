// dart format off
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or localhost for Windows/Web
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Generic GET
  Future<List<dynamic>> getList(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load data for $endpoint');
  }

  // Generic POST
  Future<Map<String, dynamic>> postData(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  // Generic PUT
  Future<Map<String, dynamic>> putData(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  // Generic DELETE
  Future<void> deleteData(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete data for $endpoint');
    }
  }

  static const String awsLambdaUrl = 'https://xbo2ekleu0.execute-api.eu-west-3.amazonaws.com/default/ManageHAUPokemonEC2';

  // EC2 Methods (Serverless)
  Future<Map<String, dynamic>> getEc2Status() async {
    final response = await http.post(
      Uri.parse(awsLambdaUrl),
      body: jsonEncode({"action": "status"}),
    );
    if (response.statusCode != 200) {
      throw Exception('EC2 status failure: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> startEc2Instance() async {
    final response = await http.post(
      Uri.parse(awsLambdaUrl),
      body: jsonEncode({"action": "start"}),
    );
    if (response.statusCode != 200) {
      throw Exception('EC2 start failure: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> stopEc2Instance() async {
    final response = await http.post(
      Uri.parse(awsLambdaUrl),
      body: jsonEncode({"action": "stop"}),
    );
    if (response.statusCode != 200) {
      throw Exception('EC2 stop failure: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  // Image Upload
  Future<Map<String, dynamic>> uploadImage(String endpoint, List<int> imageBytes, String filename) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload image for $endpoint: ${response.body}');
    }
  }
}

final apiService = ApiService();
