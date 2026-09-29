/// Industry Standard Form Validators for Authentication & Security (NIST SP 800-63B / OWASP)
class Validators {
  // RFC 5322 & OWASP Compliant Email Regular Expression
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
  );

  /// Validates email address for both Sign In and Sign Up according to industry standards.
  ///
  /// Criteria:
  /// 1. Cannot be null or whitespace only
  /// 2. Total length must not exceed 254 characters (RFC 5321 standard)
  /// 3. Must match RFC 5322 / HTML5 email structure with valid username, '@', domain, and TLD (>= 2 chars)
  /// 4. Cannot contain consecutive dots ('..') in username or domain
  static String? validateEmail(String? value, {bool isTamil = false}) {
    if (value == null || value.trim().isEmpty) {
      return isTamil
          ? 'மின்னஞ்சல் முகவரியை உள்ளிடவும்'
          : 'Please enter your email address';
    }

    final trimmed = value.trim();

    if (trimmed.length > 254) {
      return isTamil
          ? 'மின்னஞ்சல் முகவரி மிக நீளமாக உள்ளது (அதிகபட்சம் 254 எழுத்துக்கள்)'
          : 'Email address is too long (maximum 254 characters)';
    }

    if (trimmed.contains('..') || !_emailRegExp.hasMatch(trimmed)) {
      return isTamil
          ? 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும் (எ.கா: devotee@example.com)'
          : 'Please enter a valid email address (e.g. devotee@example.com)';
    }

    return null;
  }

  /// Validates password based on whether the user is signing in or registering.
  ///
  /// - Sign In (Login):
  ///   - Checks non-empty and baseline length (>= 6 characters) so as not to prematurely reject legacy credentials.
  ///
  /// - Sign Up (Registration - Industry Security Standard NIST SP 800-63B / OWASP):
  ///   1. Minimum 8 characters
  ///   2. Maximum 128 characters (to prevent hashing DoS)
  ///   3. At least one uppercase letter (A-Z)
  ///   4. At least one lowercase letter (a-z)
  ///   5. At least one numeric digit (0-9)
  ///   6. At least one special symbol (!@#$%^&*...)
  ///   7. No leading or trailing whitespace
  static String? validatePassword(
    String? value, {
    required bool isRegister,
    bool isTamil = false,
  }) {
    if (value == null || value.isEmpty) {
      return isTamil
          ? 'கடவுச்சொல்லை உள்ளிடவும்'
          : 'Please enter your password';
    }

    if (!isRegister) {
      if (value.length < 6) {
        return isTamil
            ? 'கடவுச்சொல் குறைந்தது 6 எழுத்துக்கள் இருக்க வேண்டும்'
            : 'Password must be at least 6 characters';
      }
      return null;
    }

    // Registration (Sign Up) security standards:
    if (value.trim() != value) {
      return isTamil
          ? 'கடவுச்சொல் இடைவெளியுடன் தொடங்கவோ முடியவோ கூடாது'
          : 'Password cannot start or end with spaces';
    }

    if (value.length < 8) {
      return isTamil
          ? 'கடவுச்சொல் குறைந்தது 8 எழுத்துக்கள் இருக்க வேண்டும்'
          : 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return isTamil
          ? 'கடவுச்சொல் 128 எழுத்துக்களுக்கு மிகாமல் இருக்க வேண்டும்'
          : 'Password cannot exceed 128 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return isTamil
          ? 'குறைந்தது ஒரு பெரிய எழுத்து (A-Z) தேவை'
          : 'Password must include at least one uppercase letter (A-Z)';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return isTamil
          ? 'குறைந்தது ஒரு சிறிய எழுத்து (a-z) தேவை'
          : 'Password must include at least one lowercase letter (a-z)';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return isTamil
          ? 'குறைந்தது ஒரு எண் (0-9) தேவை'
          : 'Password must include at least one number (0-9)';
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\\\/~`]').hasMatch(value)) {
      return isTamil
          ? 'குறைந்தது ஒரு சிறப்புக்குறி (!@#\$%^&*...) தேவை'
          : 'Password must include at least one special character (!@#\$%^&*...)';
    }

    return null;
  }

  /// Returns structured analysis of password strength for real-time visual feedback.
  static PasswordStrength checkPasswordStrength(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\\\/~`]').hasMatch(password);
    final hasNoTrimSpaces = password.isNotEmpty && password.trim() == password;

    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;

    return PasswordStrength(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigit: hasDigit,
      hasSpecial: hasSpecial,
      hasNoTrimSpaces: hasNoTrimSpaces,
      score: score, // 0 to 5
    );
  }
}

/// Helper model representing the live password requirement checks.
class PasswordStrength {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecial;
  final bool hasNoTrimSpaces;
  final int score;

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecial,
    required this.hasNoTrimSpaces,
    required this.score,
  });

  bool get isFullStrength => score == 5 && hasNoTrimSpaces;
}
