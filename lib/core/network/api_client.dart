class ApiResponse<T> {
  ApiResponse({this.data, this.error});

  final T? data;
  final ApiError? error;

  bool get isSuccess => error == null;
}

class ApiError {
  ApiError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse(baseUrl).replace(path: path, queryParameters: query);
  }

  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    throw UnimplementedError('Implement HTTP GET');
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    throw UnimplementedError('Implement HTTP POST');
  }
}

class MockApiClient extends ApiClient {
  MockApiClient({required super.baseUrl});

  @override
  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return ApiResponse(data: {'path': path, 'query': query});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return ApiResponse(data: {'path': path, 'body': body});
  }
}
