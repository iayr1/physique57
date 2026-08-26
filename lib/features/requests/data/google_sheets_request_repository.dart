import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/request_model.dart';
import 'request_repository.dart';

class GoogleSheetsRequestRepository implements IRequestRepository {
  final Dio _dio;
  final String webAppUrl;

  GoogleSheetsRequestRepository({
    Dio? dio,
    String? customUrl,
  })  : _dio = dio ?? Dio(),
        webAppUrl = customUrl ?? AppConstants.defaultAppsScriptUrl;

  @override
  Future<List<RequestModel>> getEmployeeRequests(String employeeEmail) async {
    try {
      final response = await _dio.get(
        webAppUrl,
        queryParameters: {
          'action': 'getRequests',
          'employeeEmail': employeeEmail,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['requests'] ?? [];
        return data.map((json) => RequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Fallback gracefully if Google Apps Script URL is offline or invalid demo ID
      throw Exception('Google Sheets API error: ${e.toString()}');
    }
  }

  @override
  Future<RequestModel> getRequestById(String requestId) async {
    try {
      final response = await _dio.get(
        webAppUrl,
        queryParameters: {
          'action': 'getRequestById',
          'requestId': requestId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return RequestModel.fromJson(response.data['request']);
      }
      throw Exception('Request $requestId not found on Sheets');
    } catch (e) {
      throw Exception('Google Sheets API error: ${e.toString()}');
    }
  }

  @override
  Future<RequestModel> submitRequest(RequestModel newRequest) async {
    try {
      final response = await _dio.post(
        webAppUrl,
        data: {
          'action': 'createRequest',
          'payload': newRequest.toJson(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return RequestModel.fromJson(response.data['request'] ?? newRequest.toJson());
      }
      return newRequest;
    } catch (e) {
      // Fallback
      return newRequest;
    }
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    try {
      final response = await _dio.post(
        webAppUrl,
        data: {
          'action': 'cancelRequest',
          'requestId': requestId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
