import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Builds the app's services once, in one place. Tests pass a fake [Dio]
/// and an in-memory [TokenStorage].
class AppDependencies {
  AppDependencies._({required this.apiClient, required this.tokenStorage, required this.session});

  factory AppDependencies.create({Dio? dio, TokenStorage? tokenStorage}) {
    final storage = tokenStorage ?? TokenStorage();
    final apiClient = ApiClient(tokenStorage: storage, dio: dio);
    final session = SessionController(
      repository: AuthRepositoryImpl(remote: AuthRemoteDataSource(apiClient), local: AuthLocalDataSource(storage)),
    );
    apiClient.onUnauthorized = session.handleUnauthorized;
    return AppDependencies._(apiClient: apiClient, tokenStorage: storage, session: session);
  }

  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final SessionController session;
}
