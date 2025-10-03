import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:lottie/lottie.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/repositories/company_repo.dart';
import 'package:smooflow/repositories/project_repo.dart';
import 'package:smooflow/screens/home_screen.dart';
import 'package:smooflow/services/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static final toastFeedbackDuration = Duration(seconds: 3);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isSignIn = true;

  final TextEditingController emailController = TextEditingController(),
      passwordController = TextEditingController(),
      confirmPasswordController = TextEditingController(),
      nameController = TextEditingController();

  bool isAuthenticated = false;

  bool obscurePassword = true;

  bool _isLoading = false;

  void showStyledToast({required bool isSuccess}) {
    showToast(
      isSuccess
          ? (isSignIn ? "Login Successful" : "Registration Successful")
          : "Authentication Failed",
      context: context,
      animation: StyledToastAnimation.fadeScale,
      reverseAnimation: StyledToastAnimation.fade,
      position: StyledToastPosition.top,
      backgroundColor: isSuccess ? Color(0xFF3b72e3) : Color(0xFFE53935),
      textStyle: const TextStyle(color: Colors.white, fontSize: 16),
      duration: LoginScreen.toastFeedbackDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;

    final paddingValue = width / 14.2909;

    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: paddingValue),
          padding: EdgeInsets.all(paddingValue),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.02),
                spreadRadius: 5,
                blurRadius: 10,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo_long.png", height: 27),
              const SizedBox(height: 15),
              Text(
                isSignIn ? "Log in" : "Register",
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your team’s productivity & optimize efficiency',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (!isSignIn) ...[
                TextField(
                  controller: nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 215, 219, 227),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 215, 219, 227),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                enabled: !_isLoading,
                controller: emailController,
                // Might need later on (not of any use as of now)
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!isValidEmail(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                  ),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                enabled: !_isLoading,
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  suffix: IconButton(
                    onPressed: toggleObscurePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 215, 219, 227),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 215, 219, 227),
                    ),
                  ),
                ),
              ),
              if (!isSignIn) ...[
                const SizedBox(height: 20),
                TextField(
                  enabled: !_isLoading,
                  controller: confirmPasswordController,
                  obscureText: obscurePassword,
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 215, 219, 227),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 215, 219, 227),
                      ),
                    ),
                  ),
                ),
              ],
              if (isSignIn)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {},
                    style: TextButton.styleFrom(
                      disabledForegroundColor: Colors.grey,
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),
              SizedBox(height: 20),
              if (_isLoading) ...[
                Lottie.asset(
                  'assets/animations/loading.json',
                  width: 150,
                  height: 150,
                ),
                SizedBox(
                  width: 250.0,
                  height: 20,
                  child: DefaultTextStyle(
                    style: const TextStyle(fontSize: 14, color: colorPrimary),
                    child: Center(
                      child: AnimatedTextKit(
                        totalRepeatCount: 2,
                        pause: Duration(milliseconds: 2000),
                        animatedTexts: [
                          ...List.generate(
                            5,
                            (index) => FadeAnimatedText('Please wait'),
                          ),
                          ...List.generate(
                            9,
                            (index) => FadeAnimatedText('One Moment...'),
                          ),
                          ...List.generate(
                            16,
                            (index) => FadeAnimatedText('Logging you in...'),
                          ),
                        ],
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                  ),
                ),
              ] else
                AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  width: width,
                  child: FilledButton(
                    onPressed: _isLoading ? null : authenticate,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: Text(isSignIn ? "Log in" : "Sign up"),
                  ),
                ),

              // Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignIn ? "Don't have an account?" : "Already registered?",
                    style: textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : toggleAuthMethod,
                    style: TextButton.styleFrom(
                      disabledForegroundColor: Colors.grey,
                    ),
                    child: Text(isSignIn ? "Sign up" : "Sign in"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void authenticate() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    print("email: ${email}, password: ${password}");

    if (!isSignIn) {
      if (name.trim().isEmpty) {
        // showSnackBar("Please enter your Display name", isError: true);
        showStyledToast(isSuccess: false);
        print("W're here 1 signup invalid name");
        return;
      }
      if (password.isEmpty || password != confirmPasswordController.text) {
        // Show interactive feedback
        // showSnackBar("Passwords do not match", isError: true);
        showStyledToast(isSuccess: false);
        print("W're here 2 signup invalid pass fields");
        return;
      }
    }

    if (!isValidEmail(email) || password.isEmpty) {
      showStyledToast(isSuccess: false);
      print("W're here 3 invalid email or empty pass");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    late final bool isLoginSuccess;
    try {
      if (!isSignIn) {
        final User newUser = User.register(
          name: name,
          role: "member",
          email: email,
        );

        await LoginService.register(user: newUser, password: password);
      }
      isLoginSuccess = await LoginService.login(
        email: email,
        password: password,
      );
    } catch (e) {
      print("error: $e");
      isLoginSuccess = false;
    }

    if (isLoginSuccess) {
      showStyledToast(isSuccess: true);
      await Future.delayed(LoginScreen.toastFeedbackDuration);
    } else {
      showStyledToast(isSuccess: false);
    }

    isAuthenticated = isLoginSuccess;

    if (isLoginSuccess) {
      await CompanyRepo.fetchCompanies();
      await ProjectRepo().fetchProjects();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }

    _isLoading = false;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void toggleObscurePassword() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  void toggleAuthMethod() {
    setState(() {
      isSignIn = !isSignIn;
    });
  }
}
