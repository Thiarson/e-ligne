// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get project_title => 'E-Ligne';

  @override
  String get loading => 'Please wait a moment';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get cancel => 'Cancel';

  @override
  String get generic_error_prompt => 'An error occurred';

  @override
  String get login => 'Login';

  @override
  String get login_email_hint => 'Email';

  @override
  String get login_password_hint => 'Password';

  @override
  String get login_forgot_password => 'Forgot Password';

  @override
  String get login_not_register_yet => 'Not register yet? Register here!';

  @override
  String get login_error_wrong_credentials => 'Email or Password incorrect';

  @override
  String get login_generic_error => 'Authentication error. Please retry again';

  @override
  String get internet_error => 'Please verify your internet connection';

  @override
  String get register => 'Register';

  @override
  String get register_to_login => 'Already registered? Login here!';

  @override
  String get register_error_weak_password => 'Password too weak';

  @override
  String get register_error_email_used => 'Email already used';

  @override
  String get register_error_invalid_email => 'Invalid email address entered';

  @override
  String get register_generic_error => 'Registration error. Please retry again';

  @override
  String get verify_email => 'Verify Email';

  @override
  String get verify_email_sent_email_verif => 'We\'ve sent an email verification. Please open it to verify your account.';

  @override
  String get verify_email_click_link => 'If you haven\'t received a verification email yet, click the link below.';

  @override
  String get verify_email_send_verification => 'Send email verification';

  @override
  String get verify_email_restart_registration => 'Restart registration';

  @override
  String get password_reset => 'Password reset';

  @override
  String get password_reset_dialog_prompt => 'A password reset link has been sent. Please check your email.';

  @override
  String get email_text_field_placeholder => 'Enter your email here';

  @override
  String get password_text_field_placeholder => 'Enter your password here';

  @override
  String get forgot_password => 'Forgot Password';

  @override
  String get forgot_password_view_generic_error => 'Please make sure that you are registered.';

  @override
  String get forgot_password_view_send_me_link => 'Send me password reset link';

  @override
  String get forgot_password_view_back_to_login => 'Back to login page';

  @override
  String get logout_button => 'logout';

  @override
  String get logout_dialog_prompt => 'Are you sure you want to logout?';
}
