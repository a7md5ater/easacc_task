# API_INTEGRATION.md

## 1. API Architecture Overview

This project uses **Dio** and **Retrofit** to structure and manage HTTP API requests, with 
- a central Dio instance configured in `dio_factory.dart`,
- layered request/response/error interceptors (`dio_interceptors.dart`),
- all dependencies managed by `get_it` (see `lib/app/injector.dart`).

### Retrofit+Dio Setup
- **Dio** is the HTTP client.
- **Retrofit** provides a declarative API for endpoints (using Dart annotations).
- Custom error mapping is handled via failure classes in `lib/core/failures/`.
- Interceptors manage logging, authentication (JWT), and automatic token refresh.

---

## 2. Network Layer Structure

```
lib/core/network/
├── dio/
│   ├── dio_factory.dart           # Dio instance configuration
│   └── dio_interceptors.dart      # Request/response interceptors
├── responses/
│   ├── api_response.dart          # Base API response wrapper
│   └── error_response.dart        # Error response model
└── network_info.dart              # Network connectivity checker
```

---

## 3. Dio Configuration (dio_factory.dart)

Responsible for initializing Dio with:
- **Base URL**
- **Headers** (Content-Type, API Key, Accept-Language, Authorization)
- **Timeouts**
- **Interceptors**

```dart
class DioFactory {
  static Dio? _dio;
  static Dio getDio({required SecureStorage tokenStorage}) {
    final currentLocale = ...;
    final Duration timeOut = const Duration(seconds: 30);
    if (_dio == null) {
      _dio = Dio();
      _dio!
        ..options.baseUrl = 'https://api.jea.local.wtmsrv.com/api/'
        ..options.headers = {
          'Content-Type': 'application/json',
          'x-api-key': 'bW90b3Itd2hlZWsdxzQGtleTIwMjU=',
          'Accept-Language': currentLocale,
        }
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut
        ..options.sendTimeout = timeOut;
      _addDioInterceptor(tokenStorage: tokenStorage);
    }
    return _dio!;
  }
  // ...
}
```

---

## 4. Interceptors (dio_interceptors.dart)

Interceptors manage authentication, token refresh, timeouts, and logging. Order matters: mutate first, then log.

### AuthInterceptor
Automatically adds Authorization header to all non-auth requests:
```dart
class AuthInterceptor extends Interceptor {
  final SecureStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip adding token for auth endpoints
    if (options.path.contains('auth/') && !options.path.contains('logout')) {
      return handler.next(options);
    }

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }
}
```

### RefreshTokenInterceptor
Handles 401 errors by refreshing tokens and retrying failed requests:

**Key Features**:
- **Request Queueing**: Queues all 401 requests while refresh is in progress
- **Single Refresh**: Only one refresh attempt at a time
- **Automatic Retry**: Retries all queued requests with new token
- **Session Management**: Clears tokens and redirects to signin on refresh failure
- **Prevents Infinite Loops**: Marks retried requests to avoid re-refreshing

```dart
class RefreshTokenInterceptor extends Interceptor {
  final SecureStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _requestQueue = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Skip auth endpoints (except logout)
      if (err.requestOptions.path.contains('auth') && 
          !err.requestOptions.path.contains('logout')) {
        return handler.next(err);
      }

      // Prevent infinite loops
      if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
        await _handleTokenRefreshFailure();
        return handler.next(err);
      }

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _handleTokenRefreshFailure();
        return handler.next(err);
      }

      // Queue request and refresh if needed
      if (_isRefreshing) {
        _requestQueue.add(_PendingRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;
      _requestQueue.add(_PendingRequest(err.requestOptions, handler));

      try {
        final refreshResult = await _refreshTokens(refreshToken);
        
        if (refreshResult['success'] == true) {
          // Retry all queued requests with new token
          final queued = List<_PendingRequest>.from(_requestQueue);
          _requestQueue.clear();

          for (final pending in queued) {
            final response = await _retryRequest(
              pending.options,
              refreshResult['tokens']['access_token'],
            );
            pending.handler.resolve(response);
          }
        } else if (refreshResult['shouldClearTokens'] == true) {
          await _handleTokenRefreshFailure();
          // Fail all queued requests
          for (final pending in _requestQueue) {
            pending.handler.next(err);
          }
          _requestQueue.clear();
        }
        _isRefreshing = false;
      } catch (e) {
        _isRefreshing = false;
        _requestQueue.clear();
      }
    } else {
      return handler.next(err);
    }
  }

  Future<void> _handleTokenRefreshFailure() async {
    await _tokenStorage.clearTokens();
    final context = AppRouter.rootNavigatorKey.currentContext;
    
    if (context != null && context.mounted) {
      context.userCubit.clearUser();
      context.customAlertDialog(
        icon: AppIcons.error,
        title: 'sessionExpired'.tr(),
        description: 'sessionExpiredDesc'.tr(),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.goNamed(Routes.signin);
        },
      );
    }
  }
}
```

### TimeoutInterceptor
Allows per-request timeout customization:
```dart
class TimeoutInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final receiveTimeout = options.extra['receiveTimeout'];
    final sendTimeout = options.extra['sendTimeout'];

    if (receiveTimeout != null && receiveTimeout is int) {
      options.receiveTimeout = Duration(milliseconds: receiveTimeout);
    }

    if (sendTimeout != null && sendTimeout is int) {
      options.sendTimeout = Duration(milliseconds: sendTimeout);
    }

    return handler.next(options);
  }
}
```

**Usage**:
```dart
// Custom timeout for a specific request
await dio.get(
  endpoint,
  options: Options(
    extra: {
      'receiveTimeout': 60000, // 60 seconds
      'sendTimeout': 30000,    // 30 seconds
    },
  ),
);
```

### LogInterceptor
Built-in Dio interceptor for debugging:
```dart
_dio.interceptors.add(
  LogInterceptor(
    request: true,
    requestBody: true,
    requestHeader: true,
    responseBody: true,
    responseHeader: true,
    error: true,
  ),
);
```

---

## 5. Retrofit Setup

Define API endpoints using Retrofit annotations in data sources.
Example (see Salary Statement Inquiry feature):
```dart
@RestApi()
abstract class SalaryStatementInquiryRemoteDataSource {
  factory SalaryStatementInquiryRemoteDataSource(Dio dio) = _SalaryStatementInquiryRemoteDataSource;

  @GET(SalaryStatementInquiryEndpoints.checkService)
  Future<ApiResponse<CheckSalaryStatementInquiryData>> checkService();

  @GET('${SalaryStatementInquiryEndpoints.financialData}/{id}')
  Future<ApiResponse<SalaryStatementInquiryData>> getSalaryStatement({ @Path('id') required int id });
}
```
**Common annotations:**
- `@GET`, `@POST`, `@PUT`, `@DELETE` for HTTP verbs
- `@Path`, `@Query`, `@Body` for params

---

## 6. Response Handling

API responses follow a generic and type-safe pattern:
- `api_response.dart`: Wrapper for all REST responses
```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  String? status;
  String? message;
  T? data; // generic data
  Meta? meta;
  // ...
}
```
- `error_response.dart`: For parsing server-side error payloads
```dart
@JsonSerializable(genericArgumentFactories: true)
class ErrorResponse<T> {
  String? status;
  String? message;
  T? errorData;
  // ...
}
```
**Parsing:**
```dart
final result = ApiResponse<Model>.fromJson(json, Model.fromJson);
```

---

## 7. Error Handling

Custom classes in `lib/core/failures/` handle errors:
- **ServerFailure**: Errors from API/HTTP (4xx, 5xx)
- **CacheFailure**: Data/storage errors
- **NetworkFailure**: No connectivity

**Mapping example (repository):**
```dart
try {
  final result = await apiCall();
  return Right(result);
} on DioException catch (e) {
  return Left(ServerFailure(error: e));
}
```

---

## 8. Feature-Specific Data Layer (Example: SalaryStatementInquiry)

Feature folder structure:
```
features/salary_statement_inquiry/data/
├── datasources/
│   └── salary_statement_inquiry_remote_data_source.dart
├── models/
│   └── check_salary_statement_inquiry_data.dart
├── repositories/
│   └── salary_statement_inquiry_repository_impl.dart
```
**Remote Data Source:**
```dart
@RestApi()
abstract class SalaryStatementInquiryRemoteDataSource { ... }
```
**Repository Implementation:**
```dart
class SalaryStatementInquiryRepositoryImpl implements SalaryStatementInquiryRepository {
  @override
  Future<Either<Failure, ApiResponse<CheckSalaryStatementInquiryData>>> checkService() {
    return handleApiCall<ApiResponse<CheckSalaryStatementInquiryData>>(
      apiCall: () => _salaryStatementInquiryRemoteDataSource.checkService(),
    );
  }
}
```
**Model (with JSON):**
```dart
@JsonSerializable()
class CheckSalaryStatementInquiryData extends Equatable { ... }
```

---

## 9. Dependency Injection (get_it)

All API dependencies are registered in `lib/app/injector.dart`:

```dart
final di = GetIt.instance;
void setupGetIt() async {
  di.registerLazySingleton<Dio>(() => DioFactory.getDio(tokenStorage: di()));
  di.registerLazySingleton<SalaryStatementInquiryRemoteDataSource>(
    () => SalaryStatementInquiryRemoteDataSource(di()),
  );
  di.registerLazySingleton<SalaryStatementInquiryRepository>(
    () => SalaryStatementInquiryRepositoryImpl(
      networkInfo: di(),
      salaryStatementInquiryRemoteDataSource: di(),
    ),
  );
}
```

---

## 10. Network Connectivity

`network_info.dart` uses a platform checker. Before every API call, check connectivity:
```dart
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection connectionChecker;
  @override
  Future<bool> connected() => connectionChecker.hasInternetAccess;
}
```
Repository pattern ensures a check before requests and error handling for offline state.

---

## 11. Authentication Flow

- Token storage in `lib/core/local_storage/secure_storage.dart` using `flutter_secure_storage`
- Interceptors (see above) automatically handle token refresh
- Biometric authentication via `biometric_auth_service.dart` for user login/authorization:
```dart
class BiometricAuthServiceImpl implements BiometricAuthService {
  Future<bool> authenticate() async { ... }
}
```
- User session is cleared if refresh fails

---

## 12. Request Types

Request types are modeled and extended for UI/logic:
```dart
enum RequestType { submitted, approved, pending, cancelled, rejected }

extension RequestTypeExtension on RequestType {
  String get name { ... }
  Color get color { ... }
}
```

---

## 13. Base Repository Mixin

All repositories use `BaseRepositoryMixin` to standardize error handling:

```dart
mixin BaseRepositoryMixin {
  NetworkInfo get networkInfo;

  Future<Either<Failure, T>> handleApiCall<T>({
    required Future<T> Function() apiCall,
  }) async {
    if (await networkInfo.connected()) {
      try {
        final result = await apiCall();
        return Right(result);
      } on DioException catch (dioError) {
        return Left(ServerFailure(error: dioError));
      } on CacheFailure catch (cacheError) {
        return Left(cacheError);
      } catch (error) {
        return Left(RuntimeFailure(error: error));
      }
    } else {
      return Left(ServerFailure(error: NoInternetConnection()));
    }
  }
}
```

**Usage in Repository**:
```dart
class FeatureRepositoryImpl 
    with BaseRepositoryMixin 
    implements FeatureRepository {
  
  final NetworkInfo networkInfo;
  final FeatureRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, ApiResponse<Data>>> getData() {
    return handleApiCall<ApiResponse<Data>>(
      apiCall: () => remoteDataSource.getData(),
    );
  }
}
```

**Benefits**:
- Automatic network checking before API calls
- Consistent error mapping across all repositories
- Centralized exception handling
- Clean and DRY repository code

---

## 14. Shared Remote Data Source

The app uses `AppRemoteDataSource` for common API operations shared across features:

```dart
@RestApi()
abstract class AppRemoteDataSource {
  factory AppRemoteDataSource(Dio dio) = _AppRemoteDataSource;

  @POST(AppEndpoints.uploadDocument)
  Future<ApiResponse<UploadDocumentData>> uploadDocument({
    @Part(name: 'document') required File document,
  });
}
```

**Registration**:
```dart
// In injector.dart
di.registerLazySingleton<AppRemoteDataSource>(
  () => AppRemoteDataSource(di()),
);
```

**Usage in Feature Repository**:
```dart
class PublicSecurityExemptionRepositoryImpl {
  final AppRemoteDataSource appRemoteDataSource;
  
  @override
  Future<Either<Failure, T>> submit({required File document}) async {
    return handleApiCall(
      apiCall: () async {
        // Use shared upload
        final uploadResponse = await appRemoteDataSource.uploadDocument(
          document: document,
        );
        
        final documentId = uploadResponse.data?.documentId;
        
        // Then use feature-specific endpoint
        return await publicSecurityRemoteDataSource.submit(
          documentId: documentId,
        );
      },
    );
  }
}
```

---

## 15. Best Practices

### Network & Error Handling
```dart
// ✅ Good: Always use handleApiCall wrapper
return handleApiCall<T>(
  apiCall: () => remoteDataSource.getData(),
);

// ❌ Bad: Direct API call without error handling
return remoteDataSource.getData();
```

### Repository Pattern
```dart
// ✅ Good: Encapsulate related API calls in repository
@override
Future<Either<Failure, T>> submitWithDocument({
  required File document,
  required Map<String, dynamic> data,
}) async {
  return handleApiCall(
    apiCall: () async {
      final upload = await appRemoteDataSource.uploadDocument(document: document);
      return await featureDataSource.submit(
        documentId: upload.data.id,
        data: data,
      );
    },
  );
}

// ❌ Bad: Multiple use cases for sequential operations
// This forces the cubit to handle sequencing and errors
```

### Dependency Injection
```dart
// ✅ Good: Register as LazySingleton
di.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(
    networkInfo: di(),
    remoteDataSource: di(),
  ),
);

// ✅ Good: Register cubits as Factory (new instance per route)
di.registerFactory<FeatureCubit>(
  () => FeatureCubit(usecase: di()),
);
```

### Token Management
```dart
// ✅ Good: Let interceptors handle tokens
// No need to manually add Authorization header

// ✅ Good: Store tokens securely
await secureStorage.saveTokens(
  accessToken: token,
  refreshToken: refresh,
);

// ❌ Bad: Store tokens in SharedPreferences or plain storage
```

### API Response Parsing
```dart
// ✅ Good: Use type-safe generic response
Future<ApiResponse<MyData>> getData();

// ✅ Good: Handle nullable data
final data = response.data;
if (data != null) {
  return Right(data);
}
return Left(ServerFailure(message: 'No data'));
```

### Endpoint Organization
```dart
// ✅ Good: Centralize endpoints in constants
class FeatureEndpoints {
  static const String base = 'feature';
  static const String get = '$base/get';
  static const String submit = '$base/submit';
}

// ❌ Bad: Hard-code endpoints in data source
@GET('feature/get')  // Magic string
```

### Testing
```dart
// ✅ Good: Mock NetworkInfo for testing
final mockNetworkInfo = MockNetworkInfo();
when(mockNetworkInfo.connected()).thenAnswer((_) async => true);

// ✅ Good: Mock RemoteDataSource
final mockDataSource = MockFeatureRemoteDataSource();
when(mockDataSource.getData()).thenAnswer((_) async => testData);
```

---

## 14. Testing API Integration

- **Mock Dio** using `mockito` and inject with get_it
- Write unit tests for:
    - Data sources (Retrofit/mocked Dio responses)
    - Repositories (handling of errors, network, parsing)
- Example:
```dart
final mockDio = MockDio();
final api = SalaryStatementInquiryRemoteDataSource(mockDio);
// ...
```

---

## 16. Code Generation

The app uses code generation for JSON serialization and Retrofit:

### Setup
```yaml
# pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.4
  json_serializable: ^6.7.0
  retrofit_generator: ^8.2.1
```

### Generate Code
```bash
# Generate once
flutter pub run build_runner build

# Watch for changes (recommended during development)
flutter pub run build_runner watch

# Clean and regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

### JSON Serialization
```dart
import 'package:json_annotation/json_annotation.dart';

part 'my_data.g.dart';

@JsonSerializable()
class MyData extends Equatable {
  final String id;
  final String name;
  
  const MyData({required this.id, required this.name});
  
  factory MyData.fromJson(Map<String, dynamic> json) => 
      _$MyDataFromJson(json);
  
  Map<String, dynamic> toJson() => _$MyDataToJson(this);
  
  @override
  List<Object?> get props => [id, name];
}
```

### Retrofit Generation
```dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'feature_remote_data_source.g.dart';

@RestApi()
abstract class FeatureRemoteDataSource {
  factory FeatureRemoteDataSource(Dio dio) = _FeatureRemoteDataSource;
  
  @GET('/endpoint')
  Future<ApiResponse<Data>> getData();
}
```

---

## 17. Common Issues & Solutions

### Certificate Errors
- **Issue**: SSL certificate verification failed
- **Solution**: 
  - Verify base URL is correct (https)
  - Ensure device/emulator trusts the certificate
  - For development, you may need to add certificate pinning

### Timeouts
- **Issue**: Request timeout errors
- **Solutions**:
  ```dart
  // Global timeout (in DioFactory)
  _dio!
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 30)
    ..options.sendTimeout = const Duration(seconds: 30);
  
  // Per-request timeout
  await dio.get(
    endpoint,
    options: Options(
      extra: {
        'receiveTimeout': 60000,
      },
    ),
  );
  ```

### Token Expiration & 401 Errors
- **Issue**: Getting 401 even after successful login
- **Solutions**:
  1. Check if AuthInterceptor is adding the token
  2. Verify refresh token endpoint and flow
  3. Check token storage: `await secureStorage.getAccessToken()`
  4. Ensure refresh interceptor is properly handling 401s
  5. Check if auth endpoints are excluded from token addition

### Network Errors
- **Issue**: No internet connection errors
- **Solutions**:
  ```dart
  // Always wrapped by handleApiCall
  if (await networkInfo.connected()) {
    // Make API call
  } else {
    return Left(ServerFailure(error: NoInternetConnection()));
  }
  ```

### JSON Parsing Errors
- **Issue**: `type 'Null' is not a subtype of type 'String'`
- **Solutions**:
  1. Make fields nullable: `String? name`
  2. Provide defaults: `@JsonKey(defaultValue: '')`
  3. Handle null in fromJson factory
  ```dart
  @JsonKey(name: 'user_name', defaultValue: '')
  final String userName;
  ```

### Multiple API Calls Failing
- **Issue**: All API calls failing after token refresh
- **Solution**: Check RefreshTokenInterceptor request queue logic and ensure retried requests are marked properly

### Dio Instance Singleton Issues
- **Issue**: Language change not reflecting in API calls
- **Solution**: Use `DioFactory.updateLanguage()` when changing locale:
  ```dart
  context.changeLanguage(languageCode: 'ar');
  // Language is automatically updated in Dio headers
  ```

---

## 18. Environment Configuration

For different environments (dev, staging, production):

```dart
class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://api.production.com/api/';
      case 'staging':
        return 'https://api.staging.com/api/';
      default:
        return 'https://api.dev.com/api/';
    }
  }
  
  static String get apiKey {
    // Different keys per environment
    return environment == 'prod' 
        ? 'prod_api_key'
        : 'dev_api_key';
  }
}

// In DioFactory
..options.baseUrl = AppConfig.baseUrl
..options.headers = {
  'x-api-key': AppConfig.apiKey,
}
```

**Run with environment**:
```bash
flutter run --dart-define=ENV=staging
flutter build apk --dart-define=ENV=prod
```

---

**For more details, see specific feature folders and the DI file (`app/injector.dart`).**
