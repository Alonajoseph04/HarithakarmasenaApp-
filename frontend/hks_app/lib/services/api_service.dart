import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'token_storage.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.146.22:8000/api';
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  // AUTH
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/auth/login/', data: {'username': username, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _dio.post('/auth/otp/send/', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _dio.post('/auth/otp/verify/', data: {'phone': phone, 'otp': otp});
    return res.data;
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    await _dio.post('/auth/change-password/', data: {'old_password': oldPass, 'new_password': newPass});
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me/');
    return res.data;
  }

  // WARDS
  Future<List<dynamic>> getWards() async {
    final res = await _dio.get('/wards/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createWard(Map<String, dynamic> data) async {
    final res = await _dio.post('/wards/', data: data);
    return res.data;
  }

  Future<void> deleteWard(int id) async {
    await _dio.delete('/wards/$id/');
  }

  Future<Map<String, dynamic>> updateWard(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/wards/$id/', data: data);
    return res.data;
  }

  // WORKERS
  Future<List<dynamic>> getWorkers() async {
    final res = await _dio.get('/workers/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createWorker(Map<String, dynamic> data) async {
    final res = await _dio.post('/workers/', data: data);
    return res.data;
  }

  Future<void> deleteWorker(int id) async {
    await _dio.delete('/workers/$id/');
  }

  Future<Map<String, dynamic>> updateWorker(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/workers/$id/', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getWorkerMe() async {
    final res = await _dio.get('/workers/me/');
    return res.data;
  }

  Future<Map<String, dynamic>> getWardProgress(int wardId) async {
    final res = await _dio.get('/workers/ward_progress/', queryParameters: {'ward_id': wardId});
    return res.data;
  }

  // HOUSEHOLDS
  Future<List<dynamic>> getHouseholds({int? wardId}) async {
    final params = wardId != null ? {'ward': wardId} : null;
    final res = await _dio.get('/households/', queryParameters: params);
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createHousehold(Map<String, dynamic> data) async {
    final res = await _dio.post('/households/', data: data);
    return res.data;
  }

  Future<void> deleteHousehold(int id) async {
    await _dio.delete('/households/$id/');
  }

  Future<Map<String, dynamic>> updateHousehold(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/households/$id/', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getHouseholdByQr(String qrCode) async {
    final res = await _dio.get('/households/by_qr/', queryParameters: {'qr_code': qrCode});
    return res.data;
  }

  Future<Map<String, dynamic>> getHouseholdByCode(String code) async {
    final res = await _dio.get('/households/by_code/', queryParameters: {'code': code});
    return res.data;
  }

  Future<Map<String, dynamic>> getHouseholdMe() async {
    final res = await _dio.get('/households/me/');
    return res.data;
  }

  // COLLECTIONS
  Future<List<dynamic>> getCollections({int? householdId, int? workerId}) async {
    final params = <String, dynamic>{};
    if (householdId != null) params['household'] = householdId;
    if (workerId != null) params['worker'] = workerId;
    final res = await _dio.get('/collections/', queryParameters: params);
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> data) async {
    final res = await _dio.post('/collections/', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getStats({String period = 'today', int? workerId}) async {
    final params = <String, dynamic>{'period': period};
    if (workerId != null) params['worker_id'] = workerId;
    final res = await _dio.get('/collections/stats/', queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> getAdminSummary() async {
    final res = await _dio.get('/collections/admin_summary/');
    return res.data;
  }

  // NOTIFICATIONS
  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread_count/');
    return res.data['unread_count'] ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.patch('/notifications/$id/mark_read/');
  }

  Future<void> markAllRead() async {
    await _dio.patch('/notifications/mark_all_read/');
  }

  Future<void> broadcast(String title, String message, String target) async {
    await _dio.post('/notifications/broadcast/', data: {
      'title': title,
      'message': message,
      'target': target,
    });
  }

  // RATING / FEEDBACK — structured 4-question feedback
  Future<void> rateWorker(
    int collectionId,
    int overall, {
    int? punctuality,
    int? cleanliness,
    int? attitude,
    String feedback = '',
  }) async {
    await _dio.patch('/collections/$collectionId/rate_worker/', data: {
      'worker_rating': overall,
      'feedback_punctuality': punctuality,
      'feedback_cleanliness': cleanliness,
      'feedback_attitude': attitude,
      'worker_feedback': feedback,
    });
  }

  // WORKER NOTIFY WARD
  Future<Map<String, dynamic>> notifyWard({String? message, int? wardId, String? scheduledDate}) async {
    final data = <String, dynamic>{};
    if (message != null) data['message'] = message;
    if (wardId != null) data['ward_id'] = wardId;
    if (scheduledDate != null) data['scheduled_date'] = scheduledDate;
    final res = await _dio.post('/workers/notify_ward/', data: data);
    return res.data;
  }

  // WORKER COVERAGE (admin view: covered/pending houses by worker in ward)
  Future<Map<String, dynamic>> getWorkerCoverage({
    required int wardId,
    int? workerId,
    String status = 'all', // 'covered', 'pending', or 'all'
    String? date,
  }) async {
    final params = <String, dynamic>{'ward_id': wardId, 'status': status};
    if (workerId != null) params['worker_id'] = workerId;
    if (date != null) params['date'] = date;
    final res = await _dio.get('/workers/worker_coverage/', queryParameters: params);
    return res.data;
  }

  // SKIP REQUESTS (household)
  Future<List<dynamic>> getSkipRequests() async {
    final res = await _dio.get('/collections/skip-requests/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createSkipRequest(Map<String, dynamic> data) async {
    final res = await _dio.post('/collections/skip-requests/', data: data);
    return res.data;
  }

  // SKIP REQUESTS (worker view)
  Future<List<dynamic>> getWorkerSkipRequests() async {
    final res = await _dio.get('/workers/skip_requests/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<void> acknowledgeSkipRequest(int id) async {
    await _dio.patch('/collections/skip-requests/$id/acknowledge/');
  }

  // EXTRA PICKUP REQUESTS
  Future<List<dynamic>> getExtraPickupRequests() async {
    final res = await _dio.get('/collections/extra-pickup/');
    return res.data is List ? res.data : res.data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createExtraPickupRequest({
    required String wasteType,
    String notes = '',
  }) async {
    final res = await _dio.post('/collections/extra-pickup/', data: {
      'waste_type': wasteType,
      'notes': notes,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> approveExtraPickup(int id) async {
    final res = await _dio.patch('/collections/extra-pickup/$id/approve/');
    return res.data;
  }

  Future<Map<String, dynamic>> rejectExtraPickup(int id, {String reason = ''}) async {
    final res = await _dio.patch('/collections/extra-pickup/$id/reject/', data: {'reason': reason});
    return res.data;
  }
}

