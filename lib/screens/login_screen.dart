// Suggested code may be subject to a license. Learn more: ~LicenseLog:1932360343.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1809838855.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3301251150.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:101135344.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4282322555.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:650661724.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:79205282.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4085271459.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3641845852.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:982294048.
import 'package:flutter/material.dart';

import 'signup_screen.dart';
import 'chat_screen.dart';
import 'forget_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Handle login logic here
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return ChatScreen();
                  }),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgetPasswordScreen()),
                    );
              },
              child: const Text("Forgot Password?"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have account"),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                      
                    );
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
