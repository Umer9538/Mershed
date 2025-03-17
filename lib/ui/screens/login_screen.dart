import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/signup_screen.dart';
import 'package:mershed/ui/widgets/custom_button.dart';
import 'package:mershed/utils/validator.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/ui/screens/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); // Added for 2FA
  final _otpController = TextEditingController(); // Added for 2FA
  String? _errorMessage;
  bool _show2FAStep = false;
  bool _isLoading = false;

  void _loginWithEmail(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final auth = Provider.of<MershadAuthProvider>(context, listen: false);
      try {
        bool success = await auth.signInWithEmail(_emailController.text, _passwordController.text);
        if (success) {
          // Initiate email-based 2FA
          await FirebaseAuth.instance.currentUser!.sendEmailVerification();
          setState(() {
            _show2FAStep = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          // Safely handle error message
          String errorMsg = e.toString();
          _errorMessage = errorMsg.contains(']') && errorMsg.split('] ').length > 1
              ? errorMsg.split('] ')[1]
              : errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  void _verifyEmail(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        setState(() {
          _errorMessage = 'Please verify your email by clicking the link sent to ${_emailController.text}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying email: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFB94A2F);
    final backgroundColor = Color(0xFFF7EFE4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
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
                          _show2FAStep ? 'Verify Your Identity' : 'Welcome Back!',
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
                          SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_show2FAStep) ...[
                                  // Email/Password Login
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    icon: Icons.email,
                                    validator: Validator.validateEmail,
                                  ),
                                  SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    icon: Icons.lock,
                                    isPassword: true,
                                    validator: Validator.validatePassword,
                                  ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ),
                                  if (_errorMessage != null) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  SizedBox(height: 24),
                                  _buildLoginButton(
                                    text: _isLoading ? 'LOADING...' : 'SIGN IN',
                                    onPressed: _isLoading ? null : () => _loginWithEmail(context),
                                    backgroundColor: Colors.white,
                                    textColor: primaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  _buildLoginButton(
                                    text: 'CONTINUE AS GUEST',
                                    onPressed: () {
                                      Provider.of<MershadAuthProvider>(context, listen: false).setGuestMode(true);
                                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                                    },
                                    backgroundColor: Colors.white.withOpacity(0.8),
                                    textColor: primaryColor,
                                  ),
                                ] else ...[

                                  Text(
                                    'We’ve sent a verification link to ${_emailController.text}. Please check your email and click the link to verify.',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_errorMessage != null) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  SizedBox(height: 24),
                                  _buildLoginButton(
                                    text: _isLoading ? 'LOADING...' : 'I HAVE VERIFIED MY EMAIL',
                                    onPressed: _isLoading ? null : () => _verifyEmail(context),
                                    backgroundColor: Colors.white,
                                    textColor: primaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  _buildLoginButton(text:'RESEND VERIFICATION EMAIL',
                                      onPressed: _isLoading? null
                                      :() async {
                                    setState(()=>_isLoading = true); try {
                                      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
                                      setState(() {
                                        _errorMessage = 'Verification email sent to ${_emailController.text}';
                                        _isLoading = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        _errorMessage = 'Error sending verification email: ${e.toString()}';
                                        _isLoading = false;

                                    });
                                      }
                                  },
                                    backgroundColor: Colors.white.withOpacity(0.8),
                                    textColor: primaryColor,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Spacer(),
                          if (!_show2FAStep) ...[
                            Padding(
                              padding: EdgeInsets.only(bottom: 24.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                                    ),
                                    child: Text(
                                      "Create an account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(bottom: 0, left: 0, child: _buildCloud(40, 20)),
                Positioned(bottom: 0, right: 0, child: _buildCloud(40, 20)),
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
    bool isPassword = false,
    bool enabled = true,
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
        enabled: enabled,
        obscureText: isPassword,
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

  Widget _buildLoginButton({
    required String text,
    required VoidCallback? onPressed,
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



















/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/signup_screen.dart';
import 'package:mershed/ui/widgets/custom_button.dart';
import 'package:mershed/utils/validator.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/ui/screens/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _show2FAStep = false;
  bool _isLoading = false;


  void _loginWithEmail(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<MershadAuthProvider>(context, listen: false);
      try {
        bool success = await auth.signInWithEmail(_emailController.text, _passwordController.text);
        if (success) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
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
                          'Welcome Back!',
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
                          SizedBox(height: 40),
                          // Email Login Form
                          Form(
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
                                _buildTextField(
                                  controller: _passwordController,
                                  hintText: "Password",
                                  icon: Icons.lock,
                                  isPassword: true,
                                  validator: Validator.validatePassword,
                                ),
                                SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                                    },
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                                if (_errorMessage != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                SizedBox(height: 24),
                                _buildLoginButton(
                                  text: 'SIGN IN',
                                  onPressed: () => _loginWithEmail(context),
                                  backgroundColor: Colors.white,
                                  textColor: primaryColor,
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                                  ),
                                  child: Text(
                                    "Create an account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
    bool isPassword = false,
    bool enabled = true,
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
        enabled: enabled,
        obscureText: isPassword,
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

  Widget _buildLoginButton({
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
}*/
