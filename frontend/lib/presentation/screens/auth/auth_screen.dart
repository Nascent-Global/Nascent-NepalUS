import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/aura_background.dart';
import '../../widgets/glass_card.dart';

enum AuthScreenMode { login, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthScreenMode.login});

  final AuthScreenMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthScreenMode _mode;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final authNotifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_mode == AuthScreenMode.login) {
      await authNotifier.login(email: email, password: password);
      return;
    }

    await authNotifier.register(
      username: _usernameController.text.trim(),
      email: email,
      password: password,
      timezone: DateTime.now().timeZoneName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isLoginMode = _mode == AuthScreenMode.login;

    if (authState.isAuthenticated && Navigator.of(context).canPop()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GlassCard(
                      variant: GlassCardVariant.primary,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(
                            top: -6,
                            right: -4,
                            child: _HeroAccent(),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.waving_hand_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Burnout Radar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLoginMode
                                    ? 'Sign in to continue your daily rhythm.'
                                    : 'Create your account and start tracking with clarity.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                  ),
                                ),
                                child: Text(
                                  isLoginMode
                                      ? 'Welcome back'
                                      : 'New here? Let\'s get started',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      variant: GlassCardVariant.frosted,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -2,
                            right: 2,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: AppTheme.warning.withValues(alpha: 0.78),
                            ),
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isLoginMode
                                            ? Icons.login_rounded
                                            : Icons.person_add_alt_1_rounded,
                                        size: 18,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLoginMode
                                          ? 'Sign In'
                                          : 'Create Account',
                                      style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<AuthScreenMode>(
                                  selected: {_mode},
                                  style: SegmentedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryDark,
                                    selectedForegroundColor: Colors.white,
                                    selectedBackgroundColor: AppTheme.primary,
                                    side: BorderSide(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.26,
                                      ),
                                      width: 1.1,
                                    ),
                                  ),
                                  segments: const [
                                    ButtonSegment<AuthScreenMode>(
                                      value: AuthScreenMode.login,
                                      label: Text('Login'),
                                    ),
                                    ButtonSegment<AuthScreenMode>(
                                      value: AuthScreenMode.register,
                                      label: Text('Register'),
                                    ),
                                  ],
                                  onSelectionChanged: isLoading
                                      ? null
                                      : (selection) {
                                          setState(() {
                                            _mode = selection.first;
                                          });
                                          ref
                                              .read(
                                                authControllerProvider.notifier,
                                              )
                                              .clearError();
                                        },
                                ),
                                const SizedBox(height: 16),
                                if (!isLoginMode) ...[
                                  TextFormField(
                                    controller: _usernameController,
                                    enabled: !isLoading,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_rounded),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (isLoginMode) {
                                        return null;
                                      }
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Username is required.';
                                      }
                                      if (text.length < 2) {
                                        return 'Use at least 2 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Email is required.';
                                    }
                                    if (!_emailRegex.hasMatch(text)) {
                                      return 'Enter a valid email.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !isLoading,
                                  obscureText: true,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_rounded),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Password is required.';
                                    }
                                    if (text.length < 6) {
                                      return 'Use at least 6 characters.';
                                    }
                                    return null;
                                  },
                                ),
                                if (authState.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Text(
                                      authState.errorMessage!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: isLoginMode
                                        ? AppTheme.primary
                                        : AppTheme.secondary,
                                    foregroundColor: isLoginMode
                                        ? Colors.white
                                        : AppTheme.secondaryDark,
                                  ),
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : Icon(
                                          isLoginMode
                                              ? Icons.login_rounded
                                              : Icons.person_add_alt_1_rounded,
                                        ),
                                  label: Text(
                                    isLoginMode ? 'Login' : 'Create Account',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroAccent extends StatelessWidget {
  const _HeroAccent();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
    );
  }
}
