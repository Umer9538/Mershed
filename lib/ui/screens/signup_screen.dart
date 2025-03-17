import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/login_screen.dart';
import 'package:mershed/ui/widgets/custom_button.dart';
import 'package:mershed/utils/validator.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  void _signupWithEmail(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<MershadAuthProvider>(context, listen: false);
      try {
        bool success = await auth.signUpWithEmail(_emailController.text, _passwordController.text);
        if (success) {
          /*Navigator.pushReplacementNamed(context, AppRoutes.home);*/
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString().split('] ')[1]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors based on the mushroom design
    final primaryColor = Color(0xFFB94A2F);
    final backgroundColor = Color(0xFFF7EFE4);
    final textColor = Colors.brown.shade800;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                // Back button
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Mushroom header with decorative elements
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'Hi There!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        Image.asset(
                          'assets/images/mershed_logo.png',
                          height: 100,
                          width: 100,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom curved container
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(height: 24),
                          Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 30),
                          // Email Signup Form
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    icon: Icons.email,
                                    validator: Validator.validateEmail,
                                  ),
                                  SizedBox(height: 16),
                                  _buildPasswordField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    icon: Icons.lock,
                                    isObscure: _obscurePassword,
                                    toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                    validator: Validator.validatePassword,
                                  ),
                                  SizedBox(height: 16),
                                  _buildPasswordField(
                                    controller: _confirmPasswordController,
                                    hintText: "Confirm Password",
                                    icon: Icons.lock_outline,
                                    isObscure: _obscureConfirmPassword,
                                    toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    validator: (value) {
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_errorMessage != null) ...[
                                    SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  SizedBox(height: 24),
                                  _buildSignupButton(
                                    text: 'CREATE ACCOUNT',
                                    onPressed: () => _signupWithEmail(context),
                                    backgroundColor: Colors.white,
                                    textColor: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      ),
                                      child: Text(
                                        "Sign in",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Cloud decorations
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCloud(40, 20),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCloud(40, 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70),
          icon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isObscure,
    required VoidCallback toggleObscure,
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isObscure,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70),
          icon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCloud(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    );
  }
}