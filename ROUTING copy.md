# ROUTING.md

## 1. Router Configuration

The app uses **go_router** (v16.0.0) for declarative and structured navigation with support for nested navigation and StatefulShellRoute. The router is set up in `lib/config/router/app_router.dart`.

### Router Setup
```dart
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey(
    debugLabel: 'root',
  );

  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        final isLoggedIn = context.userCubit.isLoggedIn;
        return isLoggedIn ? Routes.landing : Routes.splash;
      }
      return null;
    },
    routes: [
      // Routes defined here
    ],
  );
}
```

### Key Features
- **Global Navigation Key**: `AppRouter.rootNavigatorKey` for accessing navigator from anywhere
- **Authentication Redirects**: Automatic redirection based on login state
- **Nested Navigation**: Support for child routes and nested screens
- **StatefulShellRoute**: Bottom navigation with preserved state across tabs
- **Debug Logging**: Enabled via `debugLogDiagnostics`

### Route Definitions
Routes are listed in `lib/config/router/routes.dart`:
```dart
class Routes {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String home = '/home';
  // ... additional feature routes
}
```

**Parameters**: Retrieve route params or query params via the GoRouter `state` argument in your builder:
```dart
GoRoute(
  path: '/profile/:userId',
  builder: (context, state) {
    final userId = state.params['userId'];
    return ProfileScreen(userId: userId);
  },
)
```

## 2. Navigation Patterns

- **Push (add to stack):**
  ```dart
  context.push(Routes.someFeature);
  ```
- **Go (replace stack):**
  ```dart
  context.go(Routes.home);
  ```
- **Replace:**
  ```dart
  context.replace(Routes.editProfile);
  ```
- **Pop (back):**
  ```dart
  context.pop();
  ```
- **Named routes:**
  ```dart
  context.goNamed(Routes.editProfile);
  ```

**Extra Parameters/State:** Pass extra objects as `extra`:
```dart
context.go(Routes.someRoute, extra: myData);
```
Then handle in the builder:
```dart
final myData = state.extra as MyType;
```

## 3. Route Guards

**Authentication:**
Redirections are set up in the router and specific routes:
```dart
redirect: (context, state) {
  final isLoggedIn = context.userCubit.isLoggedIn;
  if (!isLoggedIn && state.matchedLocation != Routes.splash) {
    return Routes.splash;
  }
  return null;
}
```
Protect features by wrapping in guards (redirect, or dynamic logic in pageBuilder), often using dependency-injected blocs/cubits for checks.

## 4. Feature Routes

### home
```dart
GoRoute(
  path: Routes.home,
  name: Routes.home,
  builder: (context, state) => BlocProvider(
    create: (context) => di<HomeCubit>(),
    child: const HomeScreen(),
  ),
),
```
### landing
```dart
GoRoute(
  path: Routes.landing, ...
  redirect: (context, state) => Routes.home,
),
```
### financial_summary_statement (payments, salary statement inquiry etc.)
```dart
GoRoute(
  path: Routes.services,
  routes: [
    GoRoute(
      path: Routes.financialSummaryStatement,
      builder: (context, state) => BlocProvider(
        create: (context) => di<FinancialSummaryStatementCubit>(),
        child: const FinancialSummaryStatementScreen(),
      ),
    ),
    GoRoute(path: Routes.inquiryAndPayment, ...),
    GoRoute(path: Routes.salaryStatementInquiry, ...),
  ],
),
```
### edit_profile
```dart
GoRoute(
  path: Routes.editProfile,
  builder: (context, state) => BlocProvider(
    create: (context) => di<EditProfileCubit>(),
    child: const EditProfileScreen(),
  ),
  routes: [
    GoRoute(path: Routes.changePassword, ...),
    GoRoute(path: Routes.uploadID, ...),
  ],
),
```
### annual_subscriptions
```dart
GoRoute(
  path: Routes.annualSubscriptions,
  builder: (context, state) => BlocProvider(
    create: (context) => di<AnnualSubscriptionsCubit>(),
    child: const AnnualSubscriptionsScreen(),
  ),
),
```
### mandatory_retirement
```dart
GoRoute(
  path: Routes.mandatoryRetirement,
  builder: (context, state) => BlocProvider(
    create: (context) => di<MandatoryRetirementCubit>(),
    child: const MandatoryRetirementScreen(),
  ),
),
```

## 5. Deep Linking

- **Enable:** go_router supports deep linking by default.
- **Setup:** Specify a `path` for each route. Use or share these links outside the app, and route will be handled accordingly.
- **Example:**
```dart
GoRoute(
  path: '/edit_profile',
  // ...
)
```
This allows a universal link like `myapp://edit_profile` to open the Edit Profile screen.
- **Query parameters** are parsed via `state.queryParams`.

Example: `myapp://salary_statement_inquiry?id=123`
```dart
final id = int.tryParse(state.queryParams['id'] ?? '0');
```

## 6. StatefulShellRoute (Bottom Navigation)

The app uses StatefulShellRoute with `indexedStack` to maintain state across bottom navigation tabs:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return BlocProvider(
      create: (context) => di<LandingCubit>(),
      child: LandingScreen(navigationShell: navigationShell),
    );
  },
  branches: [
    // Home branch
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: Routes.home,
          pageBuilder: (context, state) => NoTransitionPage(
            child: BlocProvider(
              create: (context) => di<HomeCubit>(),
              child: const HomeScreen(),
            ),
          ),
        ),
      ],
    ),
    // Other branches: Subscriptions, Payments, Requests, Profile
  ],
),
```

### Benefits
- **State Preservation**: Each tab maintains its state when switching
- **Performance**: Lazy loading of tab content
- **No Transitions**: `NoTransitionPage` for instant tab switches
- **Nested Routes**: Full support for nested navigation within each tab

---

## 7. BlocProvider Integration

Each route creates its own BlocProvider to provide feature-specific cubits:

```dart
GoRoute(
  path: Routes.annualSubscriptions,
  builder: (context, state) {
    return BlocProvider(
      create: (context) => di<AnnualSubscriptionsCubit>(),
      child: const AnnualSubscriptionsScreen(),
    );
  },
),
```

**Important**: 
- Cubits are registered as `factory` in get_it (new instance per route)
- BlocProvider automatically disposes cubit when route is popped
- For shared state, use singleton cubits (like UserCubit)

---

## 8. Child Routes Pattern

Organize related routes hierarchically:

```dart
GoRoute(
  path: Routes.settings,
  builder: (context, state) => const SettingsScreen(),
  routes: [
    GoRoute(
      path: Routes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
      routes: [
        GoRoute(
          path: Routes.changePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),
      ],
    ),
  ],
),
```

**URLs Generated**:
- Settings: `/home/settings`
- Edit Profile: `/home/settings/edit_profile`
- Change Password: `/home/settings/edit_profile/change_password`

---

## 9. Best Practices

### Route Organization
- **Feature-based grouping**: Group related routes under parent routes
- **Centralized paths**: All paths defined in `Routes` class
- **Type-safe navigation**: Use route constants, not strings
- **Consistent naming**: Use snake_case for route paths

### Navigation
```dart
// ✅ Good: Type-safe navigation
context.push(Routes.editProfile);
context.goNamed(Routes.annualSubscriptions);

// ❌ Bad: Hard-coded strings
context.push('/edit_profile');
```

### BlocProvider Management
```dart
// ✅ Good: Each route has its own provider
GoRoute(
  path: Routes.feature,
  builder: (context, state) => BlocProvider(
    create: (context) => di<FeatureCubit>(),
    child: const FeatureScreen(),
  ),
),

// ❌ Bad: Sharing provider between routes (causes issues when popping)
```

### Error Handling
```dart
// Add error builder for 404 routes
errorBuilder: (context, state) => NotFoundScreen(),
```

### Extra Parameters
```dart
// Pass complex objects via extra
context.push(Routes.details, extra: myData);

// Receive in builder
builder: (context, state) {
  final data = state.extra as MyDataType;
  return DetailsScreen(data: data);
}
```

### Path vs Named Navigation
```dart
// Path navigation: Best for simple navigation
context.push(Routes.home);

// Named navigation: Best when using path parameters
context.goNamed(Routes.salaryStatementInquiry, extra: id);
```

---

## 10. Common Patterns

### Modal Routes
```dart
// Full screen modal
context.push(Routes.screen);

// Bottom sheet (use extension)
context.bottomSheet(
  title: 'Title',
  child: MyWidget(),
);

// Dialog (use extension)
context.customAlertDialog(
  title: 'Title',
  description: 'Description',
);
```

### Conditional Navigation
```dart
// Navigate based on state
if (condition) {
  context.push(Routes.screenA);
} else {
  context.push(Routes.screenB);
}

// Navigate after async operation
await performAction();
if (mounted) context.push(Routes.success);
```

### Replace vs Push
```dart
// Push: Add to stack (can go back)
context.push(Routes.details);

// Go: Replace entire stack
context.go(Routes.home);

// Replace: Replace current route
context.replace(Routes.newRoute);
```

---

For more, see [`lib/config/router/app_router.dart`](lib/config/router/app_router.dart) and [`lib/config/router/routes.dart`](lib/config/router/routes.dart).
