import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/bloc/auth/auth_state.dart';
import 'package:ligne/ui/widgets/loading/loading_indicator.dart';
import 'package:ligne/utils/dialogs/error_dialog.dart';
import 'package:ligne/utils/dialogs/password_reset_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> 
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);
      
      // Simulate network delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final email = _emailController.text.trim();
      context.read<AuthBloc>().add(AuthEventForgotPassword(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgotPassword) {
          setState(() => _isLoading = false);
          
          if (state.hasSentEmail) {
            _emailController.clear();
            if (mounted) {
              await showPasswordResetDialog(context);
            }
          }

          if (state.exception != null && mounted && context.mounted) {
            await showErrorDialog(
              context, 
              context.loc.forgot_password_view_generic_error,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: () {
              // Navigate back to login by updating the auth state
              context.read<AuthBloc>().add(const AuthEventLogout());
              // Also pop the current route if it's in a navigation stack
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        // Header Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 48,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              context.loc.forgot_password,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Enter your email address and we\'ll send you a link to reset your password.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Email Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: context.loc.email_text_field_placeholder,
                                  hintText: 'your@email.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _handleResetPassword(),
                              ),
                              const SizedBox(height: 32),
                              // Reset Password Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleResetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: LoadingIndicator(
                                            size: LoadingIndicatorSize.small,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          context.loc.forgot_password_view_send_me_link,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        // Back to Login
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(const AuthEventLogout()),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            context.loc.forgot_password_view_back_to_login,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
