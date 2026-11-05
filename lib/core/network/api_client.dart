import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'json_reader.dart';

/// The one door to the Business Genie API (`/api/genie`). It adds the Bearer
/// token, turns every failure into an [ApiException] carrying the backend's
/// own sentence, and reports an expired sign-in through [onUnauthorized].
///
/// Writes are allowed only to the paths in [writablePaths]; any other write
/// throws before it leaves the phone. Each feature adds its paths as it is
/// wired to the API.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio, this.onUnauthorized})
    : _tokenStorage = tokenStorage, // ignore: prefer_initializing_formals
      _dio = dio ?? Dio(_defaultOptions) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attachToken));
  }

  static final writablePaths = <RegExp>[
    for (final pattern in const [
      // Authentication
      r'/auth/login', r'/auth/login/verify',
    ])
      RegExp('^$pattern\$'),
  ];

  /// The only calls allowed without a sign-in.
  static const publicPaths = {'/auth/login', '/auth/login/verify'};

  static bool canWrite(String path) => writablePaths.any((pattern) => pattern.hasMatch(path));

  static final _defaultOptions = BaseOptions(
    baseUrl: Env.apiRoot,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
    headers: {'Accept': 'application/json'},
  );

  static const _signedOutMarker = 'signed-out';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Called when a signed-in call answers 401 (the 15-day token ran out or
  /// was revoked).
  void Function()? onUnauthorized;

  Future<JsonMap> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: _withoutEmptyValues(query)));

  /// A write, only to the paths in [writablePaths].
  Future<JsonMap> post(String path, [Object? body]) {
    _ensureWritable(path);
    return _send(() => _dio.post<dynamic>(path, data: body ?? const {}));
  }

  /// An AI job (202 → `{ job }`) followed to its end: GET /jobs/:id until it
  /// is done or failed.
  Future<JsonMap> awaitJob(
    String jobId, {
    Duration pollEvery = const Duration(milliseconds: 900),
    Duration giveUpAfter = const Duration(minutes: 2),
  }) async {
    final deadline = DateTime.now().add(giveUpAfter);
    while (DateTime.now().isBefore(deadline)) {
      final job = await get('/jobs/$jobId');
      switch (job.readString('status')) {
        case 'done':
          return job.readMap('result');
        case 'failed':
          throw ApiException(job.readString('error', ApiException.unknownMessage), statusCode: 422);
      }
      await Future<void>.delayed(pollEvery);
    }
    throw const ApiException('That took too long. Try again.', statusCode: 408);
  }

  Future<void> _attachToken(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    final isPublic = publicPaths.contains(options.path);
    // Signed out, nothing but the sign-in steps leaves the phone.
    if (token == null && !isPublic) {
      return handler.reject(DioException(requestOptions: options, type: DioExceptionType.cancel, error: _signedOutMarker));
    }
    if (token != null && !isPublic && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  static void _ensureWritable(String path) {
    if (!canWrite(path)) throw StateError('$path is changed on Business Genie on the web.');
  }

  Future<JsonMap> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map) return data.cast<String, dynamic>();
      return {'ok': true, 'data': data};
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    if (error.error == _signedOutMarker) return const ApiException('Sign in first.', statusCode: 401);
    final response = error.response;
    if (response == null) return const ApiException(ApiException.offlineMessage);

    final body = response.data is Map ? (response.data as Map).cast<String, dynamic>() : <String, dynamic>{};
    final statusCode = response.statusCode;
    final wasSignedIn = error.requestOptions.headers.containsKey('Authorization');
    if (statusCode == 401 && wasSignedIn) onUnauthorized?.call();

    final message =
        body.readStringOrNull('error') ??
        switch (statusCode) {
          401 => 'Your sign-in has ended. Sign in again.',
          403 => "You don't have access to that.",
          404 => 'That is not here any more.',
          423 => "HR isn't switched on for your company yet.",
          429 => 'Too many tries. Wait a minute, then try again.',
          _ => ApiException.unknownMessage,
        };
    return ApiException(message, statusCode: statusCode, body: body);
  }

  static Map<String, dynamic>? _withoutEmptyValues(Map<String, dynamic>? query) =>
      query == null ? null : (Map.of(query)..removeWhere((_, value) => value == null || (value is String && value.isEmpty)));
}
