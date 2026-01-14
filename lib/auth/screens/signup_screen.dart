import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = AuthController();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final deviceIdCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool loading = false;

  /// ✅ ONLY ALLOWED EMAIL DOMAINS
  bool isAllowedEmail(String email) {
    final allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
    ];

    if (!email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(domain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(nameCtrl, "Full Name"),
              
              // 🔐 EMAIL FIELD (RESTRICTED)
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (!isAllowedEmail(v)) {
                    return "Only Gmail, Yahoo, Hotmail or Outlook allowed";
                  }
                  return null;
                },
              ),

              _field(phoneCtrl, "Contact Number",
                  keyboard: TextInputType.phone),

              _field(deviceIdCtrl, "Device ID (ESP32 / Sensor ID)"),

              _password(passCtrl, "Password"),
              _password(confirmCtrl, "Confirm Password",
                  confirmWith: passCtrl),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : _signup,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("SIGN UP"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("Already have an account? Login"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _password(
    TextEditingController ctrl,
    String label, {
    TextEditingController? confirmWith,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.length < 6) {
          return "Minimum 6 characters";
        }
        if (confirmWith != null && v != confirmWith.text) {
          return "Password not matched";
        }
        return null;
      },
    );
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final error = await _auth.signup(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      password: passCtrl.text,
      deviceId: deviceIdCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account created.Verification email sent. Please check Inbox or Spam folder.",
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
