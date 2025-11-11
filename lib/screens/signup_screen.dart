import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/auth_controller.dart';
import '../styles/styles.dart';
import '../utils/validators.dart';
import 'login_screen.dart';
import 'choice_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      final success = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Erreur lors de l\'inscription',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: Styles.defaultBorderRadius,
            ),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    final success = await authController.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'Erreur de connexion Google',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: Styles.defaultBorderRadius,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Styles.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo or Icon
                  Icon(
                    Icons.car_rental,
                    size: 80,
                    color: isDark
                        ? Styles.darkDefaultBlueColor
                        : Styles.defaultBlueColor,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Styles.darkDefaultLightWhiteColor
                          : Styles.defaultRedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez notre communauté de covoiturage',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Name Field
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom complet',
                    hint: 'Entrez votre nom',
                    icon: Icons.person,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 20),
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'exemple@email.com',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 20),
                  // Phone Field
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    hint: '29843160 (8 chiffres)',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: 'Min 6 caractères (lettres + chiffres)',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark
                            ? Styles.darkDefaultGreyColor
                            : Styles.defaultGreyColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
                    hint: 'Retapez votre mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark
                            ? Styles.darkDefaultGreyColor
                            : Styles.defaultGreyColor,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (val) => Validators.validateConfirmPassword(
                      val,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Signup Button
                  ElevatedButton(
                    onPressed: authController.isLoading ? null : _submitSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Styles.defaultBlueColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: Styles.defaultBorderRadius,
                      ),
                    ),
                    child: authController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Divider OR
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: isDark
                                ? Styles.darkDefaultGreyColor
                                : Styles.defaultGreyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: authController.isLoading
                        ? null
                        : _signInWithGoogle,
                    icon: SvgPicture.asset(
                      'assets/google_logo.svg',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      'Continuer avec Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark
                            ? Styles.darkDefaultGreyColor
                            : Styles.defaultGreyColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: Styles.defaultBorderRadius,
                      ),
                      foregroundColor: isDark
                          ? Styles.darkDefaultLightWhiteColor
                          : Styles.defaultRedColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous avez déjà un compte? ',
                        style: TextStyle(
                          color: isDark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            color: isDark
                                ? Styles.darkDefaultBlueColor
                                : Styles.defaultBlueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: isDark
              ? Styles.darkDefaultLightWhiteColor
              : Styles.defaultRedColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: isDark
                ? Styles.darkDefaultYellowColor
                : Styles.defaultYellowColor,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Styles.defaultPadding),
          labelStyle: TextStyle(
            color: isDark
                ? Styles.darkDefaultGreyColor
                : Styles.defaultGreyColor,
          ),
          hintStyle: TextStyle(
            color: isDark
                ? Styles.darkDefaultGreyColor.withOpacity(0.6)
                : Styles.defaultGreyColor.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
