// services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:freelancer_platform/models/favorite_model.dart';
import 'package:freelancer_platform/models/financial_model.dart';
import 'package:freelancer_platform/models/interview_model.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/search_response.dart';
import 'package:freelancer_platform/models/work_submission_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan_model.dart';
import '../models/coupon_model.dart';
import '../models/subscription_stats_model.dart';
import 'package:dio/dio.dart';

class ApiService {
  static String get baseUrl {
  if (kIsWeb) {
    return 'https://https://freelancer-app-h6os.onrender.com/api';
  }

  if (Platform.isAndroid) {
    return 'https://freelancer-app-h6os.onrender.com/api';
  }

  return 'https://https://freelancer-app-h6os.onrender.com/api';
}

  static String? _token;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://https://freelancer-app-h6os.onrender.com/api';
    }
    if (Platform.isAndroid) {
      return 'https://freelancer-app-h6os.onrender.com';
    }
    return 'https://https://freelancer-app-h6os.onrender.com/api';
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static set token(String? newToken) {
    _token = newToken;
    if (newToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $newToken';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static String? get token => _token;

  static void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('📡 Request: ${options.method} ${options.path}');
          print('📡 Headers: ${options.headers}');
          if (options.data != null) {
            print('📡 Body: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Error: ${error.message}');
          if (error.response != null) {
            print('❌ Status: ${error.response!.statusCode}');
            print('❌ Data: ${error.response!.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  static void init() {
    _addInterceptors();
    print('✅ ApiService initialized with baseUrl: $baseUrl');
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? nationalId,
    String? phone,
    String? clientType,
    String? companyName,
    String? commercialRegisterNumber,
    String? taxNumber,
    double? hourlyRate,
    List<String>? skills,
    File? cvFile,
    File? verificationDocument,
    File? commercialRegisterImage,
    bool agreedToTerms = true,
    String? referralSource,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/signup');
      final request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['role'] = role;
      request.fields['agreed_to_terms'] = agreedToTerms.toString();
      request.fields['terms_version'] = '1.0';

      if (nationalId != null && nationalId.isNotEmpty) {
        request.fields['national_id'] = nationalId;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (referralSource != null && referralSource.isNotEmpty) {
        request.fields['referral_source'] = referralSource;
      }

      Future<void> addFile(
        String fieldName,
        File? file,
        String defaultFileName,
      ) async {
        if (file == null) return;

        if (kIsWeb) {
          try {
            final bytes = await file.readAsBytes();
            final fileName = file.path.split('/').last;
            final extension = fileName.split('.').last;
            MediaType contentType;

            if (extension.toLowerCase() == 'pdf') {
              contentType = MediaType('application', 'pdf');
            } else if (['jpg', 'jpeg'].contains(extension.toLowerCase())) {
              contentType = MediaType('image', 'jpeg');
            } else if (extension.toLowerCase() == 'png') {
              contentType = MediaType('image', 'png');
            } else {
              contentType = MediaType('application', 'octet-stream');
            }

            request.files.add(
              http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: fileName,
                contentType: contentType,
              ),
            );
          } catch (e) {
            print('Error adding file $fieldName: $e');
          }
        } else {
          final filePath = file.path;
          final extension = filePath.split('.').last;
          MediaType contentType;

          if (extension.toLowerCase() == 'pdf') {
            contentType = MediaType('application', 'pdf');
          } else if (['jpg', 'jpeg'].contains(extension.toLowerCase())) {
            contentType = MediaType('image', 'jpeg');
          } else if (extension.toLowerCase() == 'png') {
            contentType = MediaType('image', 'png');
          } else {
            contentType = MediaType('application', 'octet-stream');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              fieldName,
              filePath,
              contentType: contentType,
            ),
          );
        }
      }

      if (role == 'freelancer') {
        if (hourlyRate != null) {
          request.fields['hourly_rate'] = hourlyRate.toString();
        }
        if (skills != null && skills.isNotEmpty) {
          request.fields['skills'] = jsonEncode(skills);
        }
        await addFile('cv', cvFile, 'cv.pdf');
      } else if (role == 'client') {
        if (clientType != null && clientType.isNotEmpty) {
          request.fields['client_type'] = clientType;
        }
        if (companyName != null && companyName.isNotEmpty) {
          request.fields['company_name'] = companyName;
        }
        if (commercialRegisterNumber != null &&
            commercialRegisterNumber.isNotEmpty) {
          request.fields['commercial_register_number'] =
              commercialRegisterNumber;
        }
        if (taxNumber != null && taxNumber.isNotEmpty) {
          request.fields['tax_number'] = taxNumber;
        }
        await addFile(
          'verification_document',
          verificationDocument,
          'verification.pdf',
        );
        await addFile(
          'commercial_register',
          commercialRegisterImage,
          'commercial_register.pdf',
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['message'] ?? 'Signup failed'};
      }
    } catch (e) {
      print('Signup error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyPhone({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resendPhoneCode({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-phone-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyNationalId({
    required String nationalId,
    required String name,
    String? userId,
    String? countryCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-national-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'national_id': nationalId,
          'name': name,
          'userId': userId,
          'country_code': countryCode,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<void> logout() async {
    token = null;
    await TokenStorage.clearToken();
    await TokenStorage.clearUserRole();
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error', 'error': true};
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error', 'error': true};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error', 'error': true};
    }
  }

  static Future<Map<String, dynamic>> getClientDashboardOverview() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/dashboard/overview'),
        headers: headers,
      );

      print('📊 Dashboard Overview Response Status: ${response.statusCode}');
      print('📊 Dashboard Overview Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print(
        '❌ Dashboard overview error: ${response.statusCode} ${response.body}',
      );

      return {
        'stats': {
          'totalProjects': 0,
          'openProjects': 0,
          'inProgressProjects': 0,
          'completedProjects': 0,
          'totalProposals': 0,
          'pendingProposals': 0,
          'acceptedProposals': 0,
          'totalSpent': 0,
          'escrowHeld': 0,
          'totalReleased': 0,
          'proposalAcceptRate': 0,
        },
        'monthlySpending': [],
        'statusBreakdown': [],
        'recentProposals': [],
        'activeContracts': [],
        'recentActivity': [],
        'topFreelancers': [],
      };
    } catch (e) {
      print('❌ Error in getClientDashboardOverview: $e');
      return {
        'stats': {},
        'monthlySpending': [],
        'statusBreakdown': [],
        'recentProposals': [],
        'activeContracts': [],
        'recentActivity': [],
        'topFreelancers': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getClientDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/dashboard/stats'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required double budget,
    required int duration,
    String? category,
    List<String>? skills,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/projects'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'budget': budget,
          'duration': duration,
          'category': category ?? 'other',
          'skills': skills ?? [],
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating project: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProject({
    required int projectId,
    String? title,
    String? description,
    double? budget,
    int? duration,
    String? category,
    List<String>? skills,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/projects/$projectId'),
        headers: headers,
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (budget != null) 'budget': budget,
          if (duration != null) 'duration': duration,
          if (category != null) 'category': category,
          if (skills != null) 'skills': skills,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating project: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/client/projects/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error deleting project: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> completeProject(int projectId) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/projects/$projectId/complete'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error completing project: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<List<dynamic>> getProjectProposals(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects/$projectId/proposals'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 getProjectProposals response: ${data.length} proposals');
        return data;
      }
      return [];
    } catch (e) {
      print('Error getting proposals: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateProposalStatus({
    required int proposalId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/proposals/$proposalId'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating proposal: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getProjectContract(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects/$projectId/contract'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting contract: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerProjectContract(
    int projectId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/projects/$projectId/contract'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer project contract: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getSuggestedFreelancers(
    int projectId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/client/suggestions/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer suggestions: $e');
      return {'success': false, 'suggestions': []};
    }
  }

  static Future<List<dynamic>> getMyProjects2() async {
    try {
      print('📥 Fetching my projects...');
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching my projects: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getPortfolio(int? userId) async {
    if (userId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/portfolio/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting portfolio: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createPortfolio({
    required String title,
    required String description,
    required List<String> imagePaths,
    String? projectUrl,
    String? githubUrl,
    List<String>? technologies,
    DateTime? completionDate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/portfolio'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = title;
      request.fields['description'] = description;
      if (projectUrl != null) request.fields['project_url'] = projectUrl;
      if (githubUrl != null) request.fields['github_url'] = githubUrl;
      if (technologies != null)
        request.fields['technologies'] = jsonEncode(technologies);
      if (completionDate != null)
        request.fields['completion_date'] = completionDate.toIso8601String();

      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        return {
          'message': 'Error creating portfolio: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      print('Error creating portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createPortfolioFromSubmission(
    int submissionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/portfolio/from-submission'),
        headers: headers,
        body: jsonEncode({'submissionId': submissionId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating portfolio from submission: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createPortfolioFromContractMilestone({
    required int contractId,
    int? milestoneIndex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/portfolio/from-contract-milestone'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          if (milestoneIndex != null) 'milestoneIndex': milestoneIndex,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating portfolio from milestone: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updatePortfolio({
    required int portfolioId,
    String? title,
    String? description,
    String? projectUrl,
    String? githubUrl,
    List<String>? technologies,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/freelancer/portfolio/$portfolioId'),
        headers: headers,
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (projectUrl != null) 'project_url': projectUrl,
          if (githubUrl != null) 'github_url': githubUrl,
          if (technologies != null) 'technologies': technologies,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deletePortfolio(int portfolioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/freelancer/portfolio/$portfolioId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error deleting portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadCV(
    Uint8List cvBytes,
    String fileName,
  ) async {
    try {
      print('Starting CV upload to: $BASE_URL/freelancer/profile/cv-upload');
      print('Token exists: ${token != null}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/profile/cv-upload'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('Authorization header added');
      } else {
        print('Warning: Token is null');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'cv',
          cvBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      print('Sending request...');
      var response = await request.send();
      print('Response status code: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseData);
        } catch (e) {
          print('Error parsing JSON: $e');
          return {
            'message': 'Server returned invalid JSON',
            'raw': responseData.substring(0, min(200, responseData.length)),
          };
        }
      } else {
        return {
          'message': 'Server error: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      print('Error uploading CV: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  static Future<Map<String, dynamic>> uploadAvatar(
    Uint8List avatarBytes,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/profile/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          avatarBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      print('Error uploading avatar: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/profile/location'),
        headers: headers,
        body: jsonEncode({'lat': lat, 'lng': lng, 'address': address}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating location: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSuggestedProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/suggested-projects'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting suggested projects: $e');
      return {'projects': [], 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/stats'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer stats: $e');
      return {'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      print(
        '🔑 Current token: ${token?.substring(0, min(20, token?.length ?? 0))}...',
      );
      print('🌐 URL: $BASE_URL/freelancer/profile');

      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/profile'),
        headers: headers,
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Success: ${data.keys}');
        return data;
      } else {
        print('❌ Failed: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/freelancer/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating profile: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getAllProjects() async {
    try {
      print('🔍 Fetching all projects...');
      final response = await http.get(
        Uri.parse('$BASE_URL/projects'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Projects fetched: ${data.length}');
        return data;
      } else {
        print('❌ Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitProposal({
    required int projectId,
    required double price,
    required int deliveryTime,
    required String proposalText,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/proposals'),
        headers: headers,
        body: jsonEncode({
          'projectId': projectId,
          'price': price,
          'delivery_time': deliveryTime,
          'proposal_text': proposalText,
          'milestones': milestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error submitting proposal: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> analyzeProposalDraft({
    required int projectId,
    required double price,
    required int deliveryTime,
    required String proposalText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/proposals/analyze-draft'),
        headers: headers,
        body: jsonEncode({
          'projectId': projectId,
          'price': price,
          'delivery_time': deliveryTime,
          'proposal_text': proposalText,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error analyzing proposal draft: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/messages'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getProjectById(int projectId) async {
    try {
      print('📡 getProjectById called with ID: $projectId');
      final response = await http.get(
        Uri.parse('$BASE_URL/projects/$projectId'),
        headers: headers,
      );
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('project')) {
          return data;
        } else {
          return {'project': data};
        }
      }
      return {'project': null};
    } catch (e) {
      print('❌ Error getting project: $e');
      return {'project': null};
    }
  }

  static Future<List<dynamic>> getMyProposals() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/proposals'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting my proposals: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMyProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/projects'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting my projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAISuggestedProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/freelancer/suggestions?limit=10'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting AI suggestions: $e');
      return {'success': false, 'suggestions': []};
    }
  }

  static Future<Map<String, dynamic>> getContract(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/contracts/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting contract: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getContractProgress(
    int contractId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/contracts/$contractId/progress'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting contract progress: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> applyContractCoupon({
    required int contractId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/coupon'),
        headers: headers,
        body: jsonEncode({'code': code.trim()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error applying contract coupon: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeContractCoupon(
    int contractId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/contracts/$contractId/coupon'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error removing contract coupon: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signContract(int contractId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/sign'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error signing contract: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addContractReview({
    required int contractId,
    required int rating,
    required String review,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/review'),
        headers: headers,
        body: jsonEncode({'rating': rating, 'review': review}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding review: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getClientContracts() async {
    try {
      print('📥 Fetching client contracts...');
      final response = await http.get(
        Uri.parse('$BASE_URL/client/contracts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Client contracts fetched: ${data.length}');
        return data;
      }
      print('❌ Failed to fetch contracts: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting client contracts: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getFreelancerContracts() async {
    try {
      print('📥 Fetching freelancer contracts...');
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/contracts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Freelancer contracts fetched: ${data.length}');
        return data;
      }
      print('❌ Failed to fetch contracts: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting freelancer contracts: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMyContracts(String userRole) async {
    if (userRole == 'client') {
      return getClientContracts();
    } else {
      return getFreelancerContracts();
    }
  }

  static Future<Map<String, dynamic>> requestSignCode(int contractId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/request-code'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> verifyAndSign(
    int contractId,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/verify-and-sign'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> addRating({
    required int contractId,
    required int rating,
    String? comment,
  }) async {
    try {
      print('📝 Adding rating for contract $contractId');
      final response = await http.post(
        Uri.parse('$BASE_URL/ratings'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);
      print('✅ Rating added: $data');
      return data;
    } catch (e) {
      print('❌ Error adding rating: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkCanRate(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/can-rate/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error checking can rate: $e');
      return {'canRate': false, 'reason': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getContractRatings(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/contract/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting contract ratings: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserRatings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/user/$userId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting user ratings: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addReminder({
    required int contractId,
    required String title,
    required DateTime dueDate,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/milestones/reminder'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'title': title,
          'dueDate': dueDate.toIso8601String(),
          'description': description,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error adding reminder: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> completeReminder(
    int contractId,
    String reminderId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/milestones/reminder/$contractId/$reminderId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error completing reminder: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> connectGithubRepo({
    required int contractId,
    required String repoUrl,
    String? branch,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/github/connect'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'repoUrl': repoUrl,
          'branch': branch,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error connecting GitHub: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<List<dynamic>> getGithubCommits(
    int contractId, {
    String? githubToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/github/commits/$contractId'),
        headers: {
          ...headers,
          if (githubToken != null) 'github_token': githubToken,
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting commits: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getCalendarEvents(int year, int month) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/milestones/calendar?year=$year&month=$month'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Error getting calendar: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getUpcomingEvents(int days) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/milestones/upcoming?days=$days'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Error getting upcoming events: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications?limit=$limit&offset=$offset'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting notifications: $e');
      return {'notifications': [], 'total': 0, 'unreadCount': 0};
    }
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications/unread-count'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting unread count: $e');
      return {'unreadCount': 0};
    }
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await http.put(
        Uri.parse('$BASE_URL/notifications/$notificationId/read'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    try {
      await http.put(
        Uri.parse('$BASE_URL/notifications/read-all'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    try {
      await http.delete(
        Uri.parse('$BASE_URL/notifications/$notificationId'),
        headers: headers,
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  static Future<Map<String, dynamic>> startNegotiation(int proposalId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/negotiate'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error starting negotiation: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateNegotiation({
    required int proposalId,
    double? price,
    int? deliveryTime,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/negotiate'),
        headers: headers,
        body: jsonEncode({
          if (price != null) 'price': price,
          if (deliveryTime != null) 'delivery_time': deliveryTime,
          if (milestones != null) 'milestones': milestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating negotiation: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> acceptProposal({
    required int proposalId,
    double? agreedPrice,
    List<Map<String, dynamic>>? agreedMilestones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/accept'),
        headers: headers,
        body: jsonEncode({
          if (agreedPrice != null) 'agreedPrice': agreedPrice,
          if (agreedMilestones != null) 'agreedMilestones': agreedMilestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error accepting proposal: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/contracts/$contractId/confirm-payment'),
        headers: headers,
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error confirming payment: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> releaseMilestone({
    required int contractId,
    required int milestoneIndex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/client/contracts/$contractId/milestones/$milestoneIndex/release',
        ),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error releasing milestone: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client/wallet'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          'wallet': decoded['wallet'],
          'transactions': decoded['transactions'] ?? [],
        };
      }

      try {
        final result = jsonDecode(response.body);
        return {
          'success': false,
          'wallet': null,
          'transactions': [],
          'message': result['message'] ?? 'Error getting wallet',
        };
      } catch (_) {
        return {
          'success': false,
          'wallet': null,
          'transactions': [],
          'message': 'Error getting wallet',
        };
      }
    } catch (error) {
      print('Error in getWallet: $error');
      return {
        'success': false,
        'wallet': null,
        'transactions': [],
        'message': 'Network error: Unable to get wallet',
      };
    }
  }

  static Future<Map<String, dynamic>> createWallet() async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/wallet/create'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating wallet: $e');
      return {'wallet': null, 'transactions': []};
    }
  }

  static Future<String?> uploadWorkFile(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/work-submissions/upload'),
      );

      headers:
      headers;

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final result = jsonDecode(responseBody);

      if (response.statusCode == 200 && result['url'] != null) {
        return result['url'];
      }

      print('Error uploading file: ${result['message']}');
      return null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  static Future<String?> uploadWorkFileBytes(
    List<int> bytes,
    String fileName,
  ) async {
    return uploadWorkFile(bytes, fileName);
  }

  static Future<Map<String, dynamic>> getFreelancerWallet() async {
    try {
      final token = await TokenStorage.getToken();
      print('📡 GET /api/freelancer/wallet');
      print('🔗 URL: $baseUrl/freelancer/wallet');
      print('🔑 Token exists: ${token != null}');

      final response = await http.get(
        Uri.parse('$baseUrl/freelancer/wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          print('📡 Decoded response: $decoded');

          return {
            'success': true,
            'wallet': decoded['wallet'],
            'transactions': decoded['transactions'] ?? [],
          };
        } catch (e) {
          print('❌ Error decoding JSON: $e');
          return {
            'success': false,
            'wallet': null,
            'transactions': [],
            'message': 'Invalid JSON response',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token expired');
        return {
          'success': false,
          'wallet': null,
          'transactions': [],
          'message': 'Session expired. Please login again.',
          'requiresLogin': true,
        };
      } else if (response.statusCode == 404) {
        print('📝 Wallet not found, attempting to create...');
        final createResult = await createFreelancerWallet();
        if (createResult['success'] == true) {
          return getFreelancerWallet();
        }
        return {
          'success': false,
          'wallet': null,
          'transactions': [],
          'message': 'Wallet not found and could not be created',
        };
      } else {
        try {
          final result = jsonDecode(response.body);
          return {
            'success': false,
            'wallet': null,
            'transactions': [],
            'message':
                result['message'] ??
                'Error getting wallet (${response.statusCode})',
          };
        } catch (_) {
          return {
            'success': false,
            'wallet': null,
            'transactions': [],
            'message': 'Error getting wallet: ${response.statusCode}',
          };
        }
      }
    } catch (error) {
      print('❌ Error in getFreelancerWallet: $error');
      return {
        'success': false,
        'wallet': null,
        'transactions': [],
        'message': 'Network error: Unable to get wallet',
      };
    }
  }

  static Future<Map<String, dynamic>> createFreelancerWallet() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/freelancer/wallet/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Create freelancer wallet response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to create wallet'};
    } catch (e) {
      print('❌ Error creating freelancer wallet: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawal(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/wallet/withdraw'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> requestFreelancerWithdrawal(
    double amount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/wallet/withdraw'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<String?> createCheckoutSession({
    required int contractId,
    required String paymentIntentId,
  }) async {
    try {
      final url = '$BASE_URL/client/contracts/$contractId/create-checkout';
      print('🔍 URL: $url');
      print('🔍 Headers: $headers');
      print('🔍 paymentIntentId: $paymentIntentId');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Server error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      print('🔍 Parsed data: $data');

      if (data['checkoutUrl'] != null &&
          data['checkoutUrl'].toString().isNotEmpty) {
        print('✅ Checkout URL: ${data['checkoutUrl']}');
        return data['checkoutUrl'];
      } else {
        print('❌ No checkout URL in response');
        return null;
      }
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateMilestoneProgress({
    required int contractId,
    required int milestoneIndex,
    required double progress,
    String? status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/milestones/progress'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'milestoneIndex': milestoneIndex,
          'progress': progress,
          if (status != null) 'status': status,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error updating milestone progress: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> approveMilestone({
    required int contractId,
    required int milestoneIndex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/milestones/$contractId/milestones/$milestoneIndex/approve',
        ),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error approving milestone: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createDirectPaymentIntent({
    required int contractId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/client/contracts/$contractId/create-direct-payment',
        ),
        headers: headers,
      );

      print('📡 Direct Payment Response Status: ${response.statusCode}');
      print('📄 Direct Payment Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error creating direct payment intent: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createEscrowPaymentIntent({
    required int contractId,
  }) async {
    return createDirectPaymentIntent(contractId: contractId);
  }

  static Future<Map<String, dynamic>> manualConfirmPayment(
    int contractId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/contracts/$contractId/manual-confirm'),
        headers: headers,
      );
      print('📡 Manual confirm response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error in manualConfirmPayment: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getProjectsSummary({
    String? status,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status != 'all') 'status': status,
      };
      final uri = Uri.parse(
        '$BASE_URL/client/dashboard/projects-summary',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'projects': [], 'total': 0};
    } catch (e) {
      print('❌ getProjectsSummary: $e');
      return {'projects': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getClientProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/profile'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting client profile: $e');
      return {'name': 'Client', 'avatar': null};
    }
  }

  static Future<Map<String, dynamic>> getAdminUsers({
    String role = 'all',
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final uri = Uri.parse(
        '$BASE_URL/admin/users?role=$role&status=$status&search=$search&page=$page&limit=$limit',
      );

      print('🌐 API Call: ${uri.toString()}');

      final response = await http.get(uri, headers: headers);

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Parsed Data Keys: ${data.keys}');
        return data;
      }
      return {'users': [], 'total': 0, 'totalPages': 1};
    } catch (e) {
      print('❌ Error: $e');
      return {'users': [], 'total': 0, 'totalPages': 1};
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/users/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'freelancersCount': 0,
        'suspendedCount': 0,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'freelancersCount': 0,
        'suspendedCount': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(
    int userId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/admin/users/$userId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating user status: $e');
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> verifyUser(
    int userId,
    bool verify,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/admin/users/$userId/verify'),
        headers: headers,
        body: jsonEncode({'verified': verify}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error verifying user: $e');
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String role,
    String? phone,
    String? nationalId,
    double? hourlyRate,
    List<String>? skills,
    String? clientType,
    String? companyName,
    String? commercialRegisterNumber,
    String? taxNumber,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'role': role,
      };

      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (nationalId != null && nationalId.isNotEmpty)
        body['national_id'] = nationalId;
      if (hourlyRate != null) body['hourly_rate'] = hourlyRate.toString();
      if (skills != null && skills.isNotEmpty)
        body['skills'] = jsonEncode(skills);
      if (clientType != null && clientType.isNotEmpty)
        body['client_type'] = clientType;
      if (companyName != null && companyName.isNotEmpty)
        body['company_name'] = companyName;
      if (commercialRegisterNumber != null &&
          commercialRegisterNumber.isNotEmpty)
        body['commercial_register_number'] = commercialRegisterNumber;
      if (taxNumber != null && taxNumber.isNotEmpty)
        body['tax_number'] = taxNumber;

      final response = await http.post(
        Uri.parse('$BASE_URL/admin/users'),
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating admin user: $e');
      return {'success': false, 'message': 'Failed to create user'};
    }
  }

  static Future<Map<String, dynamic>> resendAccountEmail(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/users/$userId/resend-email'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error resending account email: $e');
      return {'success': false, 'message': 'Failed to resend email'};
    }
  }

  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/dashboard/stats'),
        headers: headers,
      );

      print('📊 Admin stats response status: ${response.statusCode}');
      print('📊 Admin stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('❌ Failed to get admin stats: ${response.statusCode}');
        return {
          'stats': {
            'totalUsers': 0,
            'totalFreelancers': 0,
            'totalClients': 0,
            'totalProjects': 0,
            'totalContracts': 0,
            'totalEarnings': 0,
            'pendingProjects': 0,
            'activeContracts': 0,
            'completedContracts': 0,
            'pendingDisputes': 0,
          },
          'monthlyStats': [],
          'recentUsers': [],
          'recentProjects': [],
        };
      }
    } catch (e) {
      print('❌ Error getting admin stats: $e');
      return {
        'stats': {
          'totalUsers': 0,
          'totalFreelancers': 0,
          'totalClients': 0,
          'totalProjects': 0,
          'totalContracts': 0,
          'totalEarnings': 0,
          'pendingProjects': 0,
          'activeContracts': 0,
          'completedContracts': 0,
          'pendingDisputes': 0,
        },
        'monthlyStats': [],
        'recentUsers': [],
        'recentProjects': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getAdminProjects({
    String status = 'all',
    String category = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? budgetRange,
  }) async {
    try {
      final queryParams = {
        'status': status,
        'category': category,
        'search': search,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (budgetRange != null) queryParams['budgetRange'] = budgetRange;

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/projects?${Uri(queryParameters: queryParams).query}',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'projects': [], 'total': 0, 'totalPages': 1};
    } catch (e) {
      print('Error getting admin projects: $e');
      return {'success': false, 'projects': [], 'total': 0, 'totalPages': 1};
    }
  }

  static Future<Map<String, dynamic>> deleteAdminProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/admin/projects/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error deleting admin project: $e');
      return {'success': false, 'message': 'Request failed'};
    }
  }

  static Future<Map<String, dynamic>> getAdminContracts({
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/contracts?status=$status&page=$page&limit=$limit',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'contracts': [], 'total': 0, 'totalPages': 1};
    } catch (e) {
      print('Error getting admin contracts: $e');
      return {'success': false, 'contracts': [], 'total': 0, 'totalPages': 1};
    }
  }

  static Future<Map<String, dynamic>> resolveAdminDispute({
    required int contractId,
    required String resolution,
    String? refundTo,
    double? amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/contracts/$contractId/resolve'),
        headers: headers,
        body: jsonEncode({
          'resolution': resolution,
          if (refundTo != null) 'refundTo': refundTo,
          if (amount != null) 'amount': amount,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error resolving dispute: $e');
      return {'success': false, 'message': 'Request failed'};
    }
  }

  static Future<Map<String, dynamic>> analyzeProject({
    required String title,
    required String description,
    String? category,
    List<String>? skills,
    double? budget,
  }) async {
    try {
      print('🔍 Analyzing project via API:');
      print('  URL: $BASE_URL/ai/analyze-project');
      print('  Title: $title');
      print(
        '  Description: ${description.substring(0, description.length > 100 ? 100 : description.length)}',
      );

      final response = await http.post(
        Uri.parse('$BASE_URL/ai/analyze-project'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'skills': skills ?? [],
          'budget': budget,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 Parsed data: $data');

        if (data['success'] == true && data['analysis'] != null) {
          return data['analysis'];
        }
        return {};
      }
      return {};
    } catch (e) {
      print('❌ Error analyzing project: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getSmartPricing(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/smart-pricing/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting smart pricing: $e');
      return {'success': false, 'pricing': null};
    }
  }

  static Future<Map<String, dynamic>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/personalized-recommendations?limit=$limit'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting recommendations: $e');
      return {'success': false, 'recommendations': []};
    }
  }

  static Future<Map<String, dynamic>> chatWithAI(
    String message, {
    int? projectId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ai/chat'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'context': {'projectId': projectId},
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error chatting with AI: $e');
      return {
        'success': true,
        'reply': "I'm having trouble connecting. Please try again.",
        'suggestedActions': [],
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/chat/history'),
        headers: headers,
      );

      print('📡 Chat history response: ${response.statusCode}');
      print('📡 Chat history body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['history'];

        if (history is List) {
          return history.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('❌ Error getting chat history: $e');
      return [];
    }
  }

  static Future<void> clearChatHistory() async {
    try {
      await http.delete(
        Uri.parse('$BASE_URL/ai/chat/history'),
        headers: headers,
      );
    } catch (e) {
      print('❌ Error clearing chat history: $e');
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/subscription/plans'),
        headers: headers,
      );

      print('📡 Subscription plans response status: ${response.statusCode}');
      print('📡 Subscription plans response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 Parsed data: $data');
        return data;
      } else {
        print('❌ Error response: ${response.body}');
        return {'success': false, 'plans': []};
      }
    } catch (e) {
      print('❌ Error getting subscription plans: $e');
      return {'success': false, 'plans': []};
    }
  }

  static Future<Map<String, dynamic>> getUserSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/subscription/me'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting user subscription: $e');
      return {'success': false, 'subscription': null};
    }
  }

  static Future<Map<String, dynamic>> createSubscriptionCheckout(
    String planSlug,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/checkout'),
        headers: headers,
        body: jsonEncode({'planSlug': planSlug}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating checkout session: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createSubscriptionPaymentIntent(
    String planSlug,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/payment-intent'),
        headers: headers,
        body: jsonEncode({'planSlug': planSlug}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating subscription payment intent: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> confirmSubscriptionPayment({
    required String planSlug,
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/confirm-payment'),
        headers: headers,
        body: jsonEncode({
          'planSlug': planSlug,
          'paymentIntentId': paymentIntentId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error confirming subscription payment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<String?> createSubscriptionCheckoutSession({
    required String planSlug,
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/checkout-session'),
        headers: headers,
        body: jsonEncode({'planSlug': 'business'}),
      );

      final data = jsonDecode(response.body);
      return data['checkoutUrl'];
    } catch (e) {
      print('Error creating subscription checkout session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> manualConfirmSubscriptionPayment(
    String planSlug,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/manual-confirm'),
        headers: headers,
        body: jsonEncode({'planSlug': planSlug}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error in manualConfirmSubscriptionPayment: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<String?> createSubscriptionCheckoutSessionDirect(
    String planSlug, {
    String? couponCode,
  }) async {
    final body = {'planSlug': planSlug};
    if (couponCode != null) body['couponCode'] = couponCode;
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/checkout-session'),
        headers: headers,
        body: jsonEncode({'planSlug': planSlug}),
      );

      final data = jsonDecode(response.body);
      print('🔍 Checkout session response: $data');
      return data['checkoutUrl'];
    } catch (e) {
      print('Error creating subscription checkout session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> confirmCheckoutSession(
    String sessionId,
  ) async {
    try {
      print('🔐 confirmCheckoutSession called with sessionId: $sessionId');

      final token = await TokenStorage.getToken();
      print('🔐 Token exists: ${token != null}');

      if (token == null) {
        print('❌ No token found, user might not be logged in');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$BASE_URL/subscription/confirm-checkout';
      print('🔐 Request URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'session_id': sessionId}),
      );

      print('🔐 Response status: ${response.statusCode}');
      print('🔐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error confirming checkout: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> refreshUserSubscription() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔄 Refresh subscription response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Error refreshing subscription: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/cancel'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error canceling subscription: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFeaturePrices() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/features/prices'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting feature prices: $e');
      return {'success': false, 'prices': {}};
    }
  }

  static Future<Map<String, dynamic>> getUserUsage() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/user/usage'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting user usage: $e');
      return {'success': false, 'usage': null};
    }
  }

  static Future<Map<String, dynamic>> manualActivateSubscription(
    String planSlug,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription-dev/manual-activate'),
        headers: headers,
        body: jsonEncode({'planSlug': planSlug}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error in manual activation: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> refreshSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/subscription/me'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error refreshing subscription: $e');
      return {'success': false, 'subscription': null};
    }
  }

  static Future<Map<String, dynamic>> getAdminSubscriptionStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/subscription/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'stats': {}};
    } catch (e) {
      print('Error getting subscription stats: $e');
      return {'success': false, 'stats': {}};
    }
  }

  static Future<List<SubscriptionPlan>> getAdminPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/subscription/plans'),
        headers: headers,
      );
      print('📡 getAdminPlans status: ${response.statusCode}');
      print('📡 getAdminPlans body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> plansJson = data['plans'];
        return plansJson.map((json) {
          try {
            return SubscriptionPlan.fromJson(json);
          } catch (e) {
            print('❌ Error parsing plan: $e, JSON: $json');
            rethrow;
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting admin plans: $e');
      return [];
    }
  }

  static Future<SubscriptionPlan?> createPlan(SubscriptionPlan plan) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/subscription/plans'),
        headers: headers,
        body: jsonEncode(plan.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubscriptionPlan.fromJson(data['plan']);
      }
      return null;
    } catch (e) {
      print('Error creating plan: $e');
      return null;
    }
  }

  static Future<SubscriptionPlan?> updatePlan(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/admin/subscription/plans/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final dataJson = jsonDecode(response.body);
        return SubscriptionPlan.fromJson(dataJson['plan']);
      }
      return null;
    } catch (e) {
      print('Error updating plan: $e');
      return null;
    }
  }

  static Future<bool> deletePlan(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/admin/subscription/plans/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting plan: $e');
      return false;
    }
  }

  static Future<List<Coupon>> getAdminCoupons({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/subscription/coupons?page=$page&limit=$limit',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> couponsJson = data['coupons'];
        return couponsJson.map((json) => Coupon.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting coupons: $e');
      return [];
    }
  }

  static Future<Coupon?> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/subscription/coupons'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final dataJson = jsonDecode(response.body);
        return Coupon.fromJson(dataJson['coupon']);
      }
      return null;
    } catch (e) {
      print('Error creating coupon: $e');
      return null;
    }
  }

  static Future<Coupon?> updateCoupon(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/admin/subscription/coupons/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final dataJson = jsonDecode(response.body);
        return Coupon.fromJson(dataJson['coupon']);
      }
      return null;
    } catch (e) {
      print('Error updating coupon: $e');
      return null;
    }
  }

  static Future<bool> deleteCoupon(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/admin/subscription/coupons/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting coupon: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> purchaseFeature(
    String feature, {
    int? entityId,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/features/purchase'),
      headers: headers,
      body: jsonEncode({'feature': feature, 'entityId': entityId}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAffiliateInfo() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/affiliate/info'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> validateCoupon(
    String code,
    String planSlug,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/subscription/validate-coupon'),
        headers: headers,
        body: jsonEncode({'code': code, 'planSlug': planSlug}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error validating coupon: $e');
      return {'valid': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/invoices?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'invoices': []};
    } catch (e) {
      print('Error getting invoices: $e');
      return {'success': false, 'invoices': []};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerPublicProfile(
    int freelancerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/profiles/freelancer/$freelancerId'),
        headers: headers,
      );

      print('📡 Freelancer profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('❌ Error getting freelancer profile: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerPublicProfileV2(
    int freelancerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/profile/public/$freelancerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  static Future<bool> addToFavorites(int projectId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/favorites/$projectId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  static Future<bool> removeFromFavorites(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/favorites/$projectId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  static Future<FavoriteResponse> getUserFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/favorites?page=$page&limit=$limit'),
        headers: headers,
      );
      return FavoriteResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Error getting favorites: $e');
      return FavoriteResponse(
        success: false,
        favorites: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
  }

  static Future<bool> checkFavorite(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/favorites/check/$projectId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data['isFavorite'] == true;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  static Future<List<Project>> getRecentProjects({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/favorites/recent/projects?limit=$limit'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      final List<dynamic> projectsJson = data['projects'];
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      print('Error getting recent projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitWork({
    required int contractId,
    int? milestoneIndex,
    required String title,
    String? description,
    List<String> files = const [],
    List<String> links = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/work-submissions'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'milestoneIndex': milestoneIndex,
          'title': title,
          'description': description,
          'files': files,
          'links': links,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error submitting work: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> approveWork(int submissionId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/work-submissions/$submissionId/approve'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error approving work: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> requestRevision({
    required int submissionId,
    required String revisionMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/work-submissions/$submissionId/revision'),
        headers: headers,
        body: jsonEncode({'revisionMessage': revisionMessage}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting revision: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<List<WorkSubmission>> getContractSubmissions(
    int contractId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/work-submissions/contract/$contractId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      final List<dynamic> submissionsJson = data['submissions'];
      return submissionsJson
          .map((json) => WorkSubmission.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting submissions: $e');
      return [];
    }
  }

  static Future<FinancialStatsResponse> getFinancialStats({
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$BASE_URL/financial/stats?period=$period';
      if (startDate != null && endDate != null) {
        url +=
            '&startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
      }
      final response = await http.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body);
      return FinancialStatsResponse.fromJson(data);
    } catch (e) {
      print('Error getting financial stats: $e');
      return FinancialStatsResponse(
        stats: FinancialStats(
          totalEarnings: 0,
          totalFees: 0,
          totalWithdrawals: 0,
          netEarnings: 0,
        ),
        periodStats: [],
        recentTransactions: [],
      );
    }
  }

  static Future<String?> generateFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/financial/report?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
        ),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data['downloadUrl'];
    } catch (e) {
      print('Error generating report: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawalV2({
    required double amount,
    required String method,
    Map<String, dynamic>? accountDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/financial/withdraw'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'accountDetails': accountDetails,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getAdvancedFinancialAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/financial/analytics'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting analytics: $e');
      return {'success': false};
    }
  }

  static Future<SearchResponse> advancedProjectSearch({
    String? query,
    String? category,
    double? minBudget,
    double? maxBudget,
    int? minDuration,
    int? maxDuration,
    String? skills,
    String? sortBy = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': ?sortBy,
      };
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (category != null && category != 'all') params['category'] = category;
      if (minBudget != null) params['minBudget'] = minBudget.toString();
      if (maxBudget != null) params['maxBudget'] = maxBudget.toString();
      if (minDuration != null) params['minDuration'] = minDuration.toString();
      if (maxDuration != null) params['maxDuration'] = maxDuration.toString();
      if (skills != null && skills.isNotEmpty) params['skills'] = skills;

      final uri = Uri.parse(
        '$BASE_URL/search/projects',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      return SearchResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Error in advanced search: $e');
      return SearchResponse(
        success: false,
        projects: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
  }

  static Future<SavedFilter> saveSearchFilter({
    required String name,
    required Map<String, dynamic> filterData,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/search/filters'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'filterData': filterData,
          'isDefault': isDefault,
        }),
      );
      final data = jsonDecode(response.body);
      return SavedFilter.fromJson(data['filter']);
    } catch (e) {
      print('Error saving filter: $e');
      rethrow;
    }
  }

  static Future<List<SavedFilter>> getSavedFilters() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/search/filters'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      final List<dynamic> filtersJson = data['filters'];
      return filtersJson.map((json) => SavedFilter.fromJson(json)).toList();
    } catch (e) {
      print('Error getting saved filters: $e');
      return [];
    }
  }

  static Future<void> deleteSavedFilter(int filterId) async {
    try {
      await http.delete(
        Uri.parse('$BASE_URL/search/filters/$filterId'),
        headers: headers,
      );
    } catch (e) {
      print('Error deleting filter: $e');
      rethrow;
    }
  }

  static Future<ProjectAlert> createProjectAlert({
    required String name,
    List<String> keywords = const [],
    List<String> skills = const [],
    double? minBudget,
    double? maxBudget,
    List<String> categories = const [],
    List<String> notificationMethods = const ['email', 'push'],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/search/alerts'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'keywords': keywords,
          'skills': skills,
          'minBudget': minBudget,
          'maxBudget': maxBudget,
          'categories': categories,
          'notificationMethods': notificationMethods,
        }),
      );
      final data = jsonDecode(response.body);
      return ProjectAlert.fromJson(data['alert']);
    } catch (e) {
      print('Error creating alert: $e');
      rethrow;
    }
  }

  static Future<List<ProjectAlert>> getUserAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/search/alerts'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      final List<dynamic> alertsJson = data['alerts'];
      return alertsJson.map((json) => ProjectAlert.fromJson(json)).toList();
    } catch (e) {
      print('Error getting alerts: $e');
      return [];
    }
  }

  static Future<void> deleteAlert(int alertId) async {
    try {
      await http.delete(
        Uri.parse('$BASE_URL/search/alerts/$alertId'),
        headers: headers,
      );
    } catch (e) {
      print('Error deleting alert: $e');
      rethrow;
    }
  }

  static Future<void> toggleAlert(int alertId) async {
    try {
      await http.patch(
        Uri.parse('$BASE_URL/search/alerts/$alertId/toggle'),
        headers: headers,
      );
    } catch (e) {
      print('Error toggling alert: $e');
      rethrow;
    }
  }

  static Future<bool> isProjectFavorite(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/favorites/check/$projectId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createInterviewInvitation({
    required int proposalId,
    List<DateTime>? suggestedTimes,
    String? message,
    int? durationMinutes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/invite'),
        headers: headers,
        body: jsonEncode({
          'proposal_id': proposalId,
          'suggested_times': suggestedTimes
              ?.map((t) => t.toIso8601String())
              .toList(),
          'message': message,
          'duration_minutes': durationMinutes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating interview invitation: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getUserInterviews({
    String? status,
  }) async {
    try {
      final url = status != null && status != 'all'
          ? '$BASE_URL/interviews/my?status=$status'
          : '$BASE_URL/interviews/my';
      final response = await http.get(Uri.parse(url), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting interviews: $e');
      return {'success': false, 'invitations': [], 'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> getInterviewById(int invitationId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/interviews/$invitationId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting interview: $e');
      return {'success': false, 'invitation': null};
    }
  }

  static Future<Map<String, dynamic>> respondToInterview({
    required int invitationId,
    required String status,
    DateTime? selectedTime,
    String? responseMessage,
  }) async {
    try {
      final body = {'status': status};

      if (selectedTime != null) {
        body['selected_time'] = selectedTime.toIso8601String();
      }
      if (responseMessage != null) {
        body['response_message'] = responseMessage;
      }

      print('📤 Sending to backend: $body');

      final response = await http.put(
        Uri.parse('$BASE_URL/interviews/$invitationId/respond'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Error responding to interview: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> rescheduleInterview({
    required int invitationId,
    required DateTime newTime,
    String? reason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/interviews/$invitationId/reschedule'),
        headers: headers,
        body: jsonEncode({
          'new_time': newTime.toIso8601String(),
          'reason': reason,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error rescheduling interview: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> addInterviewNotes({
    required int invitationId,
    required String meetingNotes,
    String? feedback,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/$invitationId/notes'),
        headers: headers,
        body: jsonEncode({'meeting_notes': meetingNotes, 'feedback': feedback}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding interview notes: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> cancelInterview({
    required int invitationId,
    String? reason,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/interviews/$invitationId/cancel'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error cancelling interview: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<InterviewStats> getInterviewStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/interviews/stats'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return InterviewStats.fromJson(data['stats'] ?? {});
    } catch (e) {
      print('Error getting interview stats: $e');
      return InterviewStats();
    }
  }

  static Future<Map<String, dynamic>> createSmartInterviewInvitation({
    required int proposalId,
    String? message,
    int? durationMinutes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/smart-invite'),
        headers: headers,
        body: jsonEncode({
          'proposal_id': proposalId,
          'message': message,
          'duration_minutes': durationMinutes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating smart interview invitation: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getSmartAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/interviews/smart-analytics'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting smart analytics: $e');
      return {'success': false, 'analytics': {}};
    }
  }

  static Future<List<DateTime>> getTimeSuggestions({
    required int proposalId,
    required int freelancerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/interviews/time-suggestions?proposalId=$proposalId&freelancerId=$freelancerId',
        ),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['suggestions'] != null) {
        return (data['suggestions'] as List)
            .map((t) => DateTime.parse(t))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting time suggestions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createGroupInterviewInvitation({
    required int proposalId,
    required List<int> freelancerIds,
    required List<DateTime> suggestedTimes,
    String? message,
    int durationMinutes = 30,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/group-invite'),
        headers: headers,
        body: jsonEncode({
          'proposal_id': proposalId,
          'freelancer_ids': freelancerIds,
          'suggested_times': suggestedTimes
              .map((t) => t.toIso8601String())
              .toList(),
          'message': message,
          'duration_minutes': durationMinutes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating group interview: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> addToCalendar({
    required int invitationId,
    required String calendarType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/$invitationId/add-to-calendar'),
        headers: headers,
        body: jsonEncode({'calendarType': calendarType}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding to calendar: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> sendManualReminder(
    int invitationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/$invitationId/send-reminder'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error sending reminder: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> addPostInterviewFeedback({
    required int invitationId,
    required int rating,
    String? comment,
    String? improvements,
    bool? wouldHireAgain,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/$invitationId/feedback'),
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
          'improvements': improvements,
          'would_hire_again': wouldHireAgain,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding feedback: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<String> exportInterviewStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/interviews/export-stats'),
        headers: headers,
      );
      return response.body;
    } catch (e) {
      print('Error exporting stats: $e');
      return '';
    }
  }

  static Future<Map<String, dynamic>> compareFreelancers({
    required List<int> freelancerIds,
    required int projectId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/interviews/compare-freelancers'),
        headers: headers,
        body: jsonEncode({
          'freelancerIds': freelancerIds,
          'projectId': projectId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error comparing freelancers: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getQuestionLibrary() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/interviews/question-library'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting question library: $e');
      return {'success': false, 'questions': {}};
    }
  }

  static Future<Map<String, dynamic>> createContractWithSOW({
    required int proposalId,
    required double agreedAmount,
    List<Map<String, dynamic>>? milestones,
    required String sowHtml,
    required Map<String, dynamic> sowAnalysis,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/contracts/create-from-proposal'),
        headers: headers,
        body: jsonEncode({
          'proposalId': proposalId,
          'agreedAmount': agreedAmount,
          'milestones': milestones,
          'sowHtml': sowHtml,
          'sowAnalysis': sowAnalysis,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating contract with SOW: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> analyzeProjectWithMarket(
    int projectId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/analyze-with-market/$projectId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? {};
      }
      return {};
    } catch (e) {
      print('Error analyzing project with market: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> generateSOW({
    required int projectId,
    required int freelancerId,
    required double agreedAmount,
    required List<Map<String, dynamic>> milestones,
    String? additionalTerms,
    required int contractId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ai/generate-sow'),
        headers: headers,
        body: jsonEncode({
          'projectId': projectId,
          'freelancerId': freelancerId,
          'agreedAmount': agreedAmount,
          'milestones': milestones,
          'additionalTerms': additionalTerms,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('Error generating SOW: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMarketRecommendations(
    int projectId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/market-recommendations/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting market recommendations: $e');
      return {'success': false, 'recommendations': []};
    }
  }

  static Future<Map<String, dynamic>> createContractDirectly({
    required int proposalId,
    required double agreedAmount,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/contracts/create-from-proposal'),
        headers: headers,
        body: jsonEncode({
          'proposalId': proposalId,
          'agreedAmount': agreedAmount,
          'milestones': milestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating contract: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateContractWithSOW({
    required int contractId,
    required String sowHtml,
    required Map<String, dynamic> sowAnalysis,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/contracts/$contractId/update-sow'),
        headers: headers,
        body: jsonEncode({'sowHtml': sowHtml, 'sowAnalysis': sowAnalysis}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating contract with SOW: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<String?> generateSOWPDF({
    required int contractId,
    required Map<String, dynamic> sowData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/generate-pdf'),
        headers: headers,
        body: jsonEncode({'sowData': sowData}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['pdfUrl'];
      }
      return null;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> addReviewReply(
    int reviewId,
    String reply,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/$reviewId/reply'),
        headers: headers,
        body: jsonEncode({'reply': reply}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markReviewHelpful(int reviewId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/$reviewId/helpful'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> searchFreelancers({
    String query = '',
    String skill = '',
    double minRating = 0,
    double maxHourlyRate = 500,
    int minExperience = 0,
    String sortBy = 'rating',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'minRating': minRating.toString(),
        'maxHourlyRate': maxHourlyRate.toString(),
        'minExperience': minExperience.toString(),
        'sortBy': sortBy,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (skill.isNotEmpty) {
        queryParams['skill'] = skill;
      }

      final uri = Uri.parse(
        '$baseUrl/client/search',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List dataList = data['freelancers'] ?? [];
          return {
            'success': true,
            'freelancers': dataList
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
            'pagination': data['pagination'],
          };
        }
      }

      return {
        'success': false,
        'freelancers': [],
        'message': 'Failed to load freelancers',
      };
    } catch (e) {
      debugPrint('Error searching freelancers: $e');
      return {'success': false, 'freelancers': [], 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerPreview({
    required int freelancerId,
    int? projectId,
  }) async {
    try {
      final uri = projectId != null
          ? Uri.parse(
              '$baseUrl/client/$freelancerId/preview',
            ).replace(queryParameters: {'projectId': projectId.toString()})
          : Uri.parse('$baseUrl/client/$freelancerId/preview');

      final response = await http.get(uri, headers: await headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['freelancer'];
        }
      }

      return {};
    } catch (e) {
      debugPrint('Error getting freelancer preview: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getTopFreelancers({
    int limit = 10,
    String? skill,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};

      if (skill != null && skill.isNotEmpty) {
        queryParams['skill'] = skill;
      }

      final uri = Uri.parse(
        '$baseUrl/client/top',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List dataList = data['freelancers'] ?? [];
          return {
            'success': true,
            'freelancers': dataList
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          };
        }
      }

      return {'success': false, 'freelancers': []};
    } catch (e) {
      debugPrint('Error getting top freelancers: $e');
      return {'success': false, 'freelancers': []};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerStatsForClient({
    required int freelancerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client/$freelancerId/stats'),
        headers: await headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {'success': false, 'stats': {}};
    } catch (e) {
      debugPrint('Error getting freelancer stats: $e');
      return {'success': false, 'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> sendOfferToFreelancer({
    required int freelancerId,
    required int projectId,
    double? amount,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/client/offers/send'),
        headers: await headers,
        body: jsonEncode({
          'freelancerId': freelancerId,
          'projectId': projectId,
          'amount': amount,
          'message': message,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOpenProjectsForHiring() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client/projects/open'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'projects': []};
    }
  }

  static Future<Map<String, dynamic>> getMyOffers() async {
    try {
      print('🔍 API Call: $BASE_URL/freelancer/offers');
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/offers'),
        headers: await headers,
      );
      print('📡 Offers response status: ${response.statusCode}');
      print('📡 Offers response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('📡 Parsed data: $data');

      return data;
    } catch (e) {
      print('❌ Error getting offers: $e');
      return {'success': false, 'message': e.toString(), 'offers': []};
    }
  }

  static Future<int> getUnreadOffersCount() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/offers/unread-count'),
        headers: await headers,
      );
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } catch (e) {
      print('Error getting unread offers count: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> respondToOffer(
    int offerId,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/offers/$offerId/respond'),
        headers: await headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getActiveAds({
    required String placement,
    int limit = 3,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ads/active?placement=$placement&limit=$limit'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> trackAdClick(int campaignId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ads/$campaignId/click'),
        headers: await headers,
        body: jsonEncode({}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMyAdCampaigns({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '$BASE_URL/ads/my-campaigns?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      final response = await http.get(Uri.parse(url), headers: await headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'campaigns': [],
        'total': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> createAdCampaign(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ads/campaigns'),
        headers: await headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> activateAdCampaign(int campaignId) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/ads/$campaignId/activate'),
        headers: await headers,
        body: jsonEncode({}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> pauseAdCampaign(int campaignId) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/ads/$campaignId/pause'),
        headers: await headers,
        body: jsonEncode({}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createAdPaymentSession(
    int campaignId, {
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ads/$campaignId/create-payment'),
        headers: await headers,
        body: jsonEncode({'successUrl': successUrl, 'cancelUrl': cancelUrl}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> payAdWithWallet(int campaignId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ads/$campaignId/pay-with-wallet'),
        headers: await headers,
        body: jsonEncode({}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdPaymentStatus(int campaignId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ads/$campaignId/payment-status'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdRevenueStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ads/admin/revenue-stats'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> recordManualAdPayment(
    int campaignId, {
    required double amount,
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ads/admin/$campaignId/record-payment'),
        headers: await headers,
        body: jsonEncode({'amount': amount, 'reference': reference}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminGetAllCampaigns({
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? budgetRange,
    String? performanceFilter,
  }) async {
    try {
      final queryParams = {
        'status': status,
        'search': search,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (budgetRange != null) queryParams['budgetRange'] = budgetRange;
      if (performanceFilter != null)
        queryParams['performanceFilter'] = performanceFilter;

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/ads/admin/campaigns?${Uri(queryParameters: queryParams).query}',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'campaigns': [], 'total': 0, 'totalPages': 0};
    }
  }

  static Future<Map<String, dynamic>> adminGetCampaignDetails(
    int campaignId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ads/admin/campaigns/$campaignId'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> adminUpdateCampaign(
    int campaignId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/ads/admin/campaigns/$campaignId'),
        headers: await headers,
        body: jsonEncode(updateData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminChangeCampaignStatus(
    int campaignId,
    String status, {
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$BASE_URL/ads/admin/campaigns/$campaignId/status'),
        headers: await headers,
        body: jsonEncode({'status': status, 'reason': reason}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminDeleteCampaign(
    int campaignId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/ads/admin/campaigns/$campaignId'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminGetAdAnalytics({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/ads/admin/analytics?${Uri(queryParameters: queryParams).query}',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'analytics': {}};
    }
  }

  static Future<Map<String, dynamic>> adminGetPaymentTransactions({
    int? campaignId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};
      if (campaignId != null) queryParams['campaignId'] = campaignId.toString();

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/ads/admin/payments?${Uri(queryParameters: queryParams).query}',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'transactions': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getAdminDisputes({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/disputes?status=$status&page=$page&limit=$limit',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting admin disputes: $e');
      return {'success': false, 'disputes': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> resolveDispute({
    required int disputeId,
    required String resolution,
    double? refundAmount,
    String? adminNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/disputes/$disputeId/resolve'),
        headers: await headers,
        body: jsonEncode({
          'resolution': resolution,
          'refundAmount': refundAmount,
          'adminNotes': adminNotes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error resolving dispute: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> rejectDispute({
    required int disputeId,
    required String adminNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/disputes/$disputeId/reject'),
        headers: await headers,
        body: jsonEncode({'adminNotes': adminNotes}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error rejecting dispute: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createDispute({
    required int contractId,
    required String title,
    required String description,
    List<String> evidenceFiles = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/disputes'),
        headers: await headers,
        body: jsonEncode({
          'contractId': contractId,
          'title': title,
          'description': description,
          'evidenceFiles': evidenceFiles,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating dispute: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getUserDisputes({
    required String status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/disputes/my?status=$status&page=$page&limit=$limit',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting user disputes: $e');
      return {'success': false, 'disputes': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getUserDisputeDetails(
    int disputeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/disputes/$disputeId'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting dispute details: $e');
      return {'success': false, 'dispute': null};
    }
  }

  static Future<Map<String, dynamic>> getTopPerformers({
    String criteria = 'overall',
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/analytics/top-performers?criteria=$criteria&limit=$limit',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting top performers: $e');
      return {'success': false, 'performers': {}};
    }
  }

  static Future<Map<String, dynamic>> getPredictiveAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/analytics/predictive'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting predictive analytics: $e');
      return {'success': false, 'predictions': {}};
    }
  }

  static Future<Map<String, dynamic>> getActiveInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/analytics/insights'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting insights: $e');
      return {'success': false, 'insights': []};
    }
  }

  static Future<Map<String, dynamic>> resolveInsight(int insightId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/admin/analytics/insights/$insightId/resolve'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error resolving insight: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAuditLogs({
    String? adminId,
    String? action,
    String? targetType,
    String? severity,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (adminId != null) queryParams['adminId'] = adminId;
      if (action != null) queryParams['action'] = action;
      if (targetType != null) queryParams['targetType'] = targetType;
      if (severity != null) queryParams['severity'] = severity;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/admin/analytics/audit-logs?${Uri(queryParameters: queryParams).query}',
        ),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting audit logs: $e');
      return {'success': false, 'logs': []};
    }
  }

  static Future<Map<String, dynamic>> getAdvancedStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/analytics/advanced-stats'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting advanced stats: $e');
      return {'success': false, 'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> getUserSatisfaction() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/admin/analytics/satisfaction'),
        headers: await headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting user satisfaction: $e');
      return {'success': false, 'analysis': {}};
    }
  }
}

class FinancialStatsResponse {
  final FinancialStats stats;
  final List<Map<String, dynamic>> periodStats;
  final List<FinancialTransaction> recentTransactions;

  FinancialStatsResponse({
    required this.stats,
    required this.periodStats,
    required this.recentTransactions,
  });

  factory FinancialStatsResponse.fromJson(Map<String, dynamic> json) {
    return FinancialStatsResponse(
      stats: FinancialStats.fromJson(json['stats'] ?? {}),
      periodStats: List<Map<String, dynamic>>.from(json['periodStats'] ?? []),
      recentTransactions:
          (json['recentTransactions'] as List?)
              ?.map((tx) => FinancialTransaction.fromJson(tx))
              .toList() ??
          [],
    );
  }
}
