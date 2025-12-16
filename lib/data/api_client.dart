import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient({required String baseUrl, String? bearerToken}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Можно залогировать/прикрутить correlation-id
        handler.next(options);
      },
      onError: (e, handler) {
        // Глобальная обработка ошибок/ретраи (по желанию)
        handler.next(e);
      },
    ));
    return ApiClient._(dio);
  }
}
