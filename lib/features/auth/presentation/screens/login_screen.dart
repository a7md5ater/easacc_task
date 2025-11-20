import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/injector.dart';
import '../../cubit/auth_cubit.dart';
import '../../../../core/shared_widgets/social_login_button.dart';
import '../../../../core/shared_widgets/loading_indicator.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/settings');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading && state is! AuthInitial) {
                return const LoadingIndicator(message: 'Signing in...');
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo/Title
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),
                    // Google Sign In Button
                    SocialLoginButton(
                      text: 'Continue with Google',
                      icon: Icons.g_mobiledata,
                      color: Colors.red,
                      onPressed: () {
                        context.read<AuthCubit>().loginWithGoogle();
                      },
                      isLoading: state is AuthLoading,
                    ),
                    const SizedBox(height: 16),
                    // Facebook Sign In Button
                    SocialLoginButton(
                      text: 'Continue with Facebook',
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      onPressed: () {
                        context.read<AuthCubit>().loginWithFacebook();
                      },
                      isLoading: state is AuthLoading,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
