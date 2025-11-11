/// Classe utilitaire pour les validations de formulaires
class Validators {
  // Expression régulière pour email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Expression régulière pour téléphone tunisien (8 chiffres commençant par 2, 4, 5, 7, ou 9)
  static final RegExp _phoneRegex = RegExp(r'^[24579]\d{7}$');

  // Expression régulière pour nom (lettres, espaces, tirets, apostrophes)
  static final RegExp _nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");

  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }

    final trimmedValue = value.trim();

    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'Entrez un email valide (ex: nom@exemple.com)';
    }

    if (trimmedValue.length > 254) {
      return 'Email trop long (max 254 caractères)';
    }

    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < minLength) {
      return 'Minimum $minLength caractères requis';
    }

    if (value.length > 128) {
      return 'Mot de passe trop long (max 128 caractères)';
    }

    // Vérifier qu'il contient au moins une lettre et un chiffre pour plus de sécurité
    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Le mot de passe doit contenir au moins une lettre';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe';
    }

    if (value != originalPassword) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Valide un nom
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return 'Le nom doit contenir au moins $minLength caractères';
    }

    if (trimmedValue.length > 100) {
      return 'Le nom est trop long (max 100 caractères)';
    }

    if (!_nameRegex.hasMatch(trimmedValue)) {
      return 'Le nom ne peut contenir que des lettres';
    }

    // Vérifier qu'il n'y a pas d'espaces multiples consécutifs
    if (trimmedValue.contains(RegExp(r'\s{2,}'))) {
      return 'Le nom ne peut pas contenir d\'espaces multiples';
    }

    return null;
  }

  /// Valide un numéro de téléphone tunisien
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    final trimmedValue = value.trim();

    // Retirer les espaces et les caractères spéciaux
    final cleanedValue = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(cleanedValue)) {
      return 'Numéro invalide (8 chiffres: 2X, 4X, 5X, 7X, 9X)';
    }

    return null;
  }

  /// Valide un champ requis générique
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide une URL
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final trimmedValue = value.trim();

    try {
      final uri = Uri.parse(trimmedValue);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'URL invalide';
      }
    } catch (e) {
      return 'URL invalide';
    }

    return null;
  }

  /// Valide un nombre entier
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }

    if (int.tryParse(value.trim()) == null) {
      return '$fieldName doit être un nombre entier';
    }

    return null;
  }

  /// Valide un nombre décimal
  static String? validateDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }

    if (double.tryParse(value.trim()) == null) {
      return '$fieldName doit être un nombre';
    }

    return null;
  }

  /// Valide une plage de nombres
  static String? validateRange(
    String? value,
    String fieldName,
    double min,
    double max,
  ) {
    final doubleError = validateDouble(value, fieldName);
    if (doubleError != null) return doubleError;

    final numValue = double.parse(value!.trim());

    if (numValue < min || numValue > max) {
      return '$fieldName doit être entre $min et $max';
    }

    return null;
  }

  /// Valide une longueur minimale
  static String? validateMinLength(
    String? value,
    String fieldName,
    int minLength,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }

    if (value.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractères';
    }

    return null;
  }

  /// Valide une longueur maximale
  static String? validateMaxLength(
    String? value,
    String fieldName,
    int maxLength,
  ) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName ne peut pas dépasser $maxLength caractères';
    }

    return null;
  }
}
