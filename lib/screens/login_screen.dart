import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../styles/styles.dart';
import 'signup_screen.dart';
import 'choice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      final success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
              authController.errorMessage ?? 'Erreur lors de la connexion',
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

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: Styles.defaultBorderRadius,
          ),
          title: Text(
            'Réinitialiser le mot de passe',
            style: TextStyle(
              color: isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'exemple@email.com',
              labelStyle: TextStyle(
                color: isDark
                    ? Styles.darkDefaultGreyColor
                    : Styles.defaultGreyColor,
              ),
              hintStyle: TextStyle(
                color: isDark
                    ? Styles.darkDefaultGreyColor
                    : Styles.defaultGreyColor,
              ),
              border: OutlineInputBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  final authController = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );
                  final success = await authController.resetPassword(
                    emailController.text,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Email de réinitialisation envoyé'
                            : authController.errorMessage ??
                                  'Erreur lors de l\'envoi',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: Styles.defaultBorderRadius,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.defaultBlueColor,
              ),
              child: const Text(
                'Envoyer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
                  const SizedBox(height: 60),
                  // Logo or Icon
                  Icon(
                    Icons.car_rental,
                    size: 100,
                    color: isDark
                        ? Styles.darkDefaultBlueColor
                        : Styles.defaultBlueColor,
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Bienvenue!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Styles.darkDefaultLightWhiteColor
                          : Styles.defaultRedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'exemple@email.com',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val!.isEmpty) return 'Entrez votre email';
                      if (!val.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: 'Entrez votre mot de passe',
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
                    validator: (val) =>
                        val!.isEmpty ? 'Entrez votre mot de passe' : null,
                  ),
                  const SizedBox(height: 16),
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _showForgotPasswordDialog,
                      child: Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          color: isDark
                              ? Styles.darkDefaultBlueColor
                              : Styles.defaultBlueColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Button
                  ElevatedButton(
                    onPressed: authController.isLoading ? null : _submitLogin,
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
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  // Signup Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte? ',
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
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'S\'inscrire',
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
