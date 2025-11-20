# UI_DESIGN_AND_LOGIC.md

## 1. Architecture Overview

This Flutter project uses a **feature-first architecture** for maintainability and scalability. Each feature is isolated with its own `cubit`, `data`, `domain`, and `presentation` folders:

- **Cubit:** State management with Cubit (flutter_bloc), using copyWith for immutability.
- **Data:** Handles API models, DTOs, and remote/local sources.
- **Domain:** Contains entities, repository contracts, and use cases.
- **Presentation:** UI screens, widgets, and user interaction logic.

### Cubit Pattern & copyWith
Cubit states are immutable and use the copyWith pattern to emit new state objects. This ensures robust and predictable UI updates.

### Separation of Concerns
- UI in `presentation`
- Business logic in `domain`
- State in `cubit`
- Data, API, persistence in `data`

### Repository Pattern Best Practices
- **Encapsulate Complex Operations**: When a feature requires multiple API calls that are always executed together, encapsulate them in a single repository method rather than creating separate use cases. This provides:
  - Simpler cubit code
  - Atomic operations (all-or-nothing execution)
  - Better error handling (failure at any step returns the error immediately)
  - Cleaner dependency injection (fewer use cases to inject)
  
**Example**: Public Security Exemption submit operation
- Instead of: `UploadDocumentUsecase` + `SubmitRequestUsecase` (2 use cases)
- Use: Single `submit()` method in repository that handles both upload and submission
- The repository performs: upload document → extract document ID → submit request
- If upload fails, the failure is returned immediately
- The cubit only needs to call one use case

### State Status Pattern
The app uses a generic `StateStatus<T>` wrapper to handle different states of async operations:
```dart
class StateStatus<T> {
  final Status status;
  final T? data;
  final String? error;
  final Map<String, dynamic>? errorData;

  const StateStatus.initial();
  const StateStatus.loading();
  const StateStatus.success(T data);
  const StateStatus.failure(String error, {Map<String, dynamic>? errorData});

  bool get isInitial => status == Status.initial;
  bool get isLoading => status == Status.loading;
  bool get isSuccess => status == Status.success;
  bool get isFailure => status == Status.failure;
}
```

**Usage in Cubit State:**
```dart
class MyFeatureState extends Equatable {
  final StateStatus<MyData> fetchData;
  final StateStatus<String> submitData;
  
  const MyFeatureState({
    this.fetchData = const StateStatus.initial(),
    this.submitData = const StateStatus.initial(),
  });
}
```

---

## 2. Project Structure

```
lib/
├── app/                    # App initialization, router, theme
├── core/
│   ├── base_entity/       # Base entity classes
│   ├── base_repository/   # Repository abstractions
│   ├── extensions/        # Dart extensions for UI helpers
│   ├── failures/          # Error handling (cache, server, failure classes)
│   ├── helpers/           # Utility helpers
│   ├── local_storage/     # Secure storage, user preferences
│   ├── shared_widgets/    # Reusable UI components
│   └── utils/             # App constants (colors, fonts, animations, etc.)
└── features/              # Feature modules
    └── [feature_name]/
        ├── cubit/         # State management
        ├── data/          # Data layer
        ├── domain/        # Business logic
        └── presentation/  # UI screens and widgets
```

---

## 3. State Management with Cubit

### Cubit vs Bloc
Cubit is a lightweight, minimal version of Bloc. It exposes simple methods (no events) and uses direct method calls for state changes.

**Bloc**: Works with events & states. More powerful for complex interactivity or event streams.
**Cubit**: Direct API. Use when only state transitions are needed.

### Example State Class (copyWith)
```dart
class EditProfileState extends Equatable {
  final bool isEditProfileValidate;
  final String currentEmail;
  // ...other fields

  const EditProfileState({
    this.isEditProfileValidate = false,
    this.currentEmail = '',
    // ...
  });

  EditProfileState copyWith({
    bool? isEditProfileValidate,
    String? currentEmail,
    // ...
  }) {
    return EditProfileState(
      isEditProfileValidate: isEditProfileValidate ?? this.isEditProfileValidate,
      currentEmail: currentEmail ?? this.currentEmail,
      // ...
    );
  }

  @override
  List<Object?> get props => [isEditProfileValidate, currentEmail];
}
```

### Emitting State with copyWith
```dart
void validateEmail(String email) {
  emit(state.copyWith(currentEmail: email));
}
```

### BlocObserver Usage
`lib/app/bloc_observer.dart` logs and observes state transitions and errors globally:
```dart
class MyBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange -- \\${bloc.runtimeType}, $change');
  }
}
```

### Typical Cubit Example
```dart
class EditProfileCubit extends Cubit<EditProfileState> {
  void validateEditProfile() {
    final isValid = ...;
    emit(state.copyWith(isEditProfileValidate: isValid));
  }
  // Other methods ...
}
```

---

## 4. Design System (`lib/core/utils`)

### AppColors
Color constants for primary, accent, text, and backgrounds:
```dart
class AppColors {
  static const Color primary = Color(0xff045785);
  static const Color primaryLight = Color(0xffB1CBD9);
  static const Color darkGreen = Color(0xff075E54);
  static const Color green = Color(0xff16B364);
  // ...
}
```

### AppFonts & FontStyles
Typography styles encapsulated in `AppTextStyle`:
```dart
AppTextStyle.bold(fontColor: AppColors.primary, fontSize: 18);
```

Font family and weights in `app_fonts.dart`:
```dart
class FontFamily {
  static const String openSans = 'OpenSans';
}
class FontWeightManager {
  static const FontWeight bold = FontWeight.w700;
}
```

### AppAnimations
Animation file references:
```dart
class AppAnimations {
  static const _source = 'assets/animations/';
}
```

### AppIcons & AppImages
All icons and images are managed centrally:
```dart
class AppIcons {
  static const user = 'assets/icons/user.svg';
  // ...
}

class AppImages {
  static const logo = 'assets/images/logo.png';
  // ...
}
```

### AppEnums
Reusable enums for common UI/business states:
```dart
enum RequestType { submitted, approved, pending, cancelled, rejected }
```

### AppFormatters
Reusable input formatters:
```dart
class MaxValueTextInputFormatter extends TextInputFormatter { /* ... */ }
```

### AppFunctions
Small helpers for input, validation, conversions:
```dart
AppFunctions.handleTextFieldValidator(validators: [/* ... */]);
```

---

## 5. Shared Widgets Library
Reusable and styled for consistency:

### app_bar.dart
```dart
CustomAppBar(title: 'Profile');
```
Props: `title`, `hasBackButton`, `onBackPress`, `showChangeLanguage`, `action`, `titleSize`

### button.dart
```dart
CustomButton(text: 'Save', onPressed: handleSave);
```
Props: `onPressed`, `text`, `fillColor`, `loadingCondition`, etc.

### text_form_field.dart
```dart
CustomTextField(title: 'Email', hintText: 'Enter email', controller: ...);
```

### date_picker widgets
Use extension (`context.showCustomDatePicker(...)`), see Extensions section.

### drop_down_list.dart
```dart
CustomDropDownList<String>(hint: 'Select', value: selected, items: ...);
```

### error_widget.dart
Shows error and retry:
```dart
CustomErrorWidget(message: 'Error', onRetry: reload);
```

### empty_view.dart
```dart
CustomEmptyView(text: 'No Data Found')
```

### no_items_founded.dart
```dart
NoItemsFounded(text: 'No Items', icon: Icons.info)
```

### network_image.dart
```dart
CustomNetworkImage(imageUrl: '...', fit: BoxFit.cover)
```

### wave_loader.dart
```dart
WaveLoader()
```

### segmented_tab_bar.dart
```dart
SegmentedTabBar(tabs: ['Tab 1', 'Tab 2']);
```

### custom_service_container.dart
A decorated container for service info.

### gradient_container.dart
```dart
GradientContainer(child: ...)
```

### expansion_tile.dart
```dart
CustomExpansionTile(title: Text('Title'), children: [ ... ])
```

---

## 6. Extensions
Located in `lib/core/extensions/`

### alert_dialog.dart
```dart
context.customAlertDialog(
  title: 'Alert', 
  description: 'Desc',
  icon: AppIcons.warning,
  buttonText: 'OK',
  onPressed: () {},
);
```

### bottom_sheet.dart
```dart
context.bottomSheet(
  title: 'Sheet', 
  icon: AppIcons.info, 
  child: MyWidget(),
);
```

### snackbar.dart
```dart
context.successSnackBar(message: 'Saved!');
context.errorSnackBar(message: 'Error occurred');
context.infoSnackBar(message: 'Info message');
```

### localization.dart
```dart
// Change app language
context.changeLanguage(languageCode: 'ar');

// Get current language
final currentLang = context.languageCode; // 'en' or 'ar'

// Get language display name
final langName = context.getLanguage; // 'English' or 'عربي'
```

### date_picker.dart
```dart
final picked = await context.showCustomDatePicker(
  initialDate: DateTime.now(),
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
);
```

### cubits.dart
Access cubits from context without BlocProvider.of:
```dart
context.userCubit.isLoggedIn;
context.editProfileCubit.doSomething();
context.homeCubit.loadData();
```

### user_context.dart
Exposes user info directly on BuildContext:
```dart
final user = context.userCubit.currentUser;
final isLoggedIn = context.userCubit.isLoggedIn;
```

### request_type.dart
Map enums to text or color:
```dart
RequestType.approved.color; // AppColors.green
RequestType.approved.name; // localized string
RequestType.pending.color; // AppColors.yellow
```

---

## 7. Feature Module Structure Example: `financial_summary_statement`

```
features/
└── financial_summary_statement/
    ├── cubit/
    │    ├── financial_summary_statement_cubit.dart   # Cubit state management
    │    └── financial_summary_statement_state.dart   # State class (copyWith)
    ├── data/
    │    ├── datasources/                   # API & remote data source
    │    │    ├── financial_summary_statement_endpoints.dart
    │    │    ├── financial_summary_statement_remote_data_source.dart
    │    │    └── financial_summary_statement_remote_data_source.g.dart
    │    ├── models/                        # DTOs and data models
    │    │    ├── financial_summary_statement_data.dart
    │    │    └── financial_summary_statement_data.g.dart
    │    └── repositories/                  # Repository implementation
    │         └── financial_summary_statement_repository_impl.dart
    ├── domain/
    │    ├── repositories/                  # Repo contract (abstract)
    │    │    └── financial_summary_statement_repository.dart
    │    └── usecases/                      # Use-cases
    │         └── get_financial_summary_usecase.dart
    └── presentation/
         ├── screens/
         │    └── financial_summary_statement_screen.dart   # Main UI Screen
         └── widgets/                              # Feature-specific widgets
              ├── financial_summary_statement_items.dart     # Main composition widget
              ├── section_title.dart
              ├── engineer_info_section.dart
              ├── retirement_info_section.dart
              ├── insurance_info_section.dart
              ├── financial_transactions_section.dart
              ├── retirement_detail_card.dart
              ├── deposit_card.dart
              ├── contact_services_section.dart
              └── note_section.dart
```

---

## 8. Navigation

Routing is managed with [go_router] and described in `ROUTING.md`. Router configuration is in `lib/app/config/router`.

---

## 9. Dependency Injection

Dependency injection is handled via [get_it], with a central setup in `lib/app/injector.dart`. See details and registrations in `API_INTEGRATION.md`.

---

## 10. Presentation Layer Best Practices

### Widget Structure
- **Avoid Widget Functions**: Never create widgets as private functions (e.g., `_buildSomething()`). Always create proper StatelessWidget or StatefulWidget classes.
- **Single Responsibility**: Each widget file should contain one widget class with a clear, specific purpose.
- **Naming Convention**: Use descriptive, feature-specific names (e.g., `EngineerInfoSection`, `RetirementDetailCard`).

### File Organization
- **Main Items Widget**: The main `*_items.dart` file should only compose other widgets, not build complex UI.
- **Separate Widget Files**: Extract sections, cards, and complex UI components into individual widget files.
- **Widget Directory Structure**:
```
features/
└── [feature_name]/
    └── presentation/
        └── widgets/
            ├── [feature_name]_items.dart        # Main composition widget
            ├── section_title.dart               # Reusable section title
            ├── [section_name]_section.dart      # Individual sections
            ├── [item_name]_card.dart            # Card components
            └── [component_name].dart            # Other components
```

### Example Structure (Financial Summary Statement):
```
financial_summary_statement/presentation/widgets/
├── financial_summary_statement_items.dart  # Main widget that composes all sections
├── section_title.dart                     # FinancialSummaryStatementSectionTitle widget
├── engineer_info_section.dart             # EngineerInfoSection widget
├── retirement_info_section.dart           # RetirementInfoSection widget
├── insurance_info_section.dart            # InsuranceInfoSection widget
├── financial_transactions_section.dart    # FinancialTransactionsSection widget
├── retirement_detail_card.dart            # RetirementDetailCard widget
├── deposit_card.dart                      # DepositCard widget
├── contact_services_section.dart          # ContactServicesSection widget
└── note_section.dart                      # FinancialSummaryStatementNoteSection widget
```

### Widget Best Practices
- Use `copyWith` for immutable state updates.
- Keep widgets small and focused on a single job.
- Prefer shared widgets for design consistency.
- Use extensions to keep UI clean and DRY.
- Stick to feature-first modular structure.
- UI logic/presentation goes in UI; business logic in domain; data management in data.
- Extract reusable components to shared_widgets when used across multiple features.

---

## 11. Error Handling

Error & failure abstractions live in `lib/core/failures/`:

- **cache_failure.dart**: For cache issues:
```dart
class CacheFailure implements Failure { ... }
```
- **failure.dart**: Base class; all failures extend this.
```dart
abstract class Failure { String get message; }
```
- **server_failure.dart**: Server/API errors (network, HTTP, parsing).
```dart
class ServerFailure extends Failure { ... }
```

Catch and display errors using Cubit state, and handle with error widgets/snackbars.

---

## 12. Local Storage

Sensitive token and user data are managed in `lib/core/local_storage/`:

### secure_storage.dart
Manages authentication tokens, preferences, and biometric enablement using `flutter_secure_storage`:
```dart
// Save tokens
await secureStorage.saveTokens(
  accessToken: 'token',
  refreshToken: 'refresh',
  expiresIn: 3600,
);

// Retrieve tokens
final token = await secureStorage.getAccessToken();
final refreshToken = await secureStorage.getRefreshToken();

// Clear tokens (logout)
await secureStorage.clearTokens();

// Biometric settings
await secureStorage.setBiometricEnabled(true);
final isEnabled = await secureStorage.getBiometricEnabled();
```

### user_cubit.dart
Global state management for user data accessible via context extension:
```dart
// Access from anywhere
final user = context.userCubit.currentUser;
final isLoggedIn = context.userCubit.isLoggedIn;

// Update user
context.userCubit.setUser(userModel);

// Clear user (logout)
context.userCubit.clearUser();
```

### user_storage.dart
Persists user data locally using Hive:
```dart
// Initialize (done in main.dart)
await di<UserStorage>().init();

// Save user data
await userStorage.saveUser(userModel);

// Retrieve user data
final user = await userStorage.getUser();

// Clear user data
await userStorage.clearUser();
```

---

## 13. Form Validation

### ValidationHelper
Located in `lib/core/helpers/validation_helper.dart`:
```dart
// Email validation
bool isValid = ValidationHelper.isValidEmail(email: 'test@example.com');

// Phone number validation
bool isValid = ValidationHelper.isValidPhoneNumber(phoneNumber: '+201234567890');
```

### TextFieldValidator
Located in `lib/core/utils/app_functions.dart`:
```dart
// Usage in TextField validator
validator: (value) => AppFunctions.handleTextFieldValidator(
  validators: [
    TextFieldValidator(
      condition: value == null || value.isEmpty,
      message: 'fieldRequired'.tr(),
    ),
    TextFieldValidator(
      condition: value != null && !ValidationHelper.isValidEmail(email: value),
      message: 'invalidEmail'.tr(),
    ),
  ],
),
```

### Form Validation in Cubits
Validation logic is handled in cubits with reactive state updates:
```dart
void validateForm() {
  final isEmailValid = emailController.text.isNotEmpty &&
      ValidationHelper.isValidEmail(email: emailController.text);
  final isPhoneValid = phoneController.text.isNotEmpty &&
      ValidationHelper.isValidPhoneNumber(phoneNumber: phoneController.text);
  
  final isFormValid = isEmailValid && isPhoneValid;
  emit(state.copyWith(isFormValid: isFormValid));
}
```

---

## 14. Internationalization (i18n)

The app uses **easy_localization** for multi-language support (English & Arabic).

### Setup
Configured in `lib/app/app.dart`:
```dart
EasyLocalization(
  supportedLocales: const [Locale('en'), Locale('ar')],
  path: 'assets/translations',
  useOnlyLangCode: true,
  startLocale: Platform.localeName.substring(0, 2) == 'ar'
      ? const Locale('ar')
      : const Locale('en'),
  fallbackLocale: const Locale('en'),
  child: MyApp(),
);
```

### Translation Files
- **Location**: `assets/translations/`
- **Files**: `en.json`, `ar.json`

### Usage
```dart
// In widgets
Text('welcome'.tr())
Text('hello'.tr(args: ['John']))

// Access locale
final locale = context.locale; // Locale('en') or Locale('ar')
final langCode = context.languageCode; // 'en' or 'ar'

// Change language (via extension)
context.changeLanguage(languageCode: 'ar');
```

### Dio Integration
Language is automatically sent to API via `Accept-Language` header:
```dart
// DioFactory updates header when language changes
DioFactory.updateLanguage(languageCode);
```

---

## 15. File Upload Pattern

Located in `lib/core/shared_widgets/file_upload_widget.dart`:

### FileUploadWidget
Reusable widget for file uploads with loading, success, and error states:
```dart
FileUploadWidget(
  pickedFile: cubit.state.pickedFile,
  isLoading: cubit.state.uploadStatus.isLoading,
  hasError: cubit.state.uploadStatus.isFailure,
  errorMessage: cubit.state.uploadStatus.error,
  onTap: () async {
    final file = await FilePicker.pickFile();
    cubit.uploadFile(file);
  },
  onDelete: () => cubit.clearFile(),
  uploadText: 'uploadDocument'.tr(),
  hintText: 'maxSize2MB'.tr(),
  uploadIcon: AppIcons.upload,
)
```

### States Handled
- **Empty**: Shows upload icon and text
- **Loading**: Shows circular progress indicator
- **Success**: Shows file name with delete option
- **Error**: Shows error message with retry option

### Custom Success Widget
```dart
FileUploadWidget(
  // ... other params
  successWidgetBuilder: (file) => CustomSuccessView(file: file),
)
```

---

## 16. Domain Layer Patterns

### Entities
Domain entities represent pure business models without JSON serialization:
```dart
// Located in features/[feature]/domain/entities/
class NotificationsEntity extends Equatable {
  final List<NotificationsGroup> groups;
  final int unreadCount;
  
  const NotificationsEntity({
    required this.groups,
    required this.unreadCount,
  });
  
  @override
  List<Object?> get props => [groups, unreadCount];
}
```

### Mappers
Transform data models to domain entities:
```dart
// Located in features/[feature]/domain/mappers/
extension NotificationsDataMapper on NotificationsData {
  NotificationsEntity toEntity() {
    // Complex transformation logic
    return NotificationsEntity(...);
  }
}

// Usage in repository
final data = await remoteDataSource.getNotifications();
return Right(data.toEntity());
```

### Use Cases
Single-responsibility classes that execute specific business logic:
```dart
class GetNotificationsUsecase {
  final NotificationsRepository repository;
  
  GetNotificationsUsecase({required this.repository});
  
  Future<Either<Failure, NotificationsEntity>> call() {
    return repository.getNotifications();
  }
}
```

---

Read further details in [`ROUTING.md`](ROUTING.md) and [`API_INTEGRATION.md`](API_INTEGRATION.md) for navigation and DI specifics.
