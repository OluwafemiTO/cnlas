import 'package:cnlas/screens/inputDetails.screen.dart';
import 'package:flutter/material.dart';
import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/models/user.model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final authService = AuthAPI();
  TextEditingController emailController = TextEditingController();
  String? errorMessage;
  //controllers
  TextEditingController nameController = TextEditingController();

  bool obscureText = true;
  TextEditingController passwordController = TextEditingController();
  User? registeredUser;

  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  Future<void> _handleRegister(String name, String email, String password) async {
    try {
      final user = await authService.registerUser(name, email, password);

      if (!mounted) return;  // safeguard

      if (user.role == 'LECTURER') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputDetailsScreen(
              email: email,
              name: name,
            ),
          ),
        );
      } else {
        // maybe navigate somewhere else
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Create Account",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                // Subtitle
                Text(
                  "Start your journey with us",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 32),
            
                Form(
                  key: _signupFormKey,
                  child: Column(
                    children: [  
                      // Input fields
                      TextFormField(
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter FullName";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Full name",
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          } else if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        obscureText: obscureText,
                        controller: passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a password";
                          } else if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: obscureText == false ? IconButton(
                            icon: Icon(
                              Icons.visibility
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ) :
                          IconButton(
                            icon: Icon(
                              Icons.visibility_off
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
            
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_signupFormKey.currentState!.validate()) {
                              // All validations passed
                              _handleRegister(nameController.text.trim(), emailController.text.trim(), passwordController.text.trim());
                            }
                          },
                          child: const Text("Sign Up"),
                        ),
                      ),
                    ],
                  )
                ),
                
            
                const SizedBox(height: 24),
            
                // Don't have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // navigate to login
                        Navigator.pushNamedAndRemoveUntil(context, '/', (routes) => false);
                      },
                      child: Text(
                        "Sign in",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}