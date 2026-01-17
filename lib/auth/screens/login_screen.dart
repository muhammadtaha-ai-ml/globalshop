import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = AuthController();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                emailCtrl,
                "Email",
                keyboard: TextInputType.emailAddress,
              ),
              _password(passCtrl, "Password"),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("LOGIN"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
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

  Widget _password(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final error = await _auth.login(
      email: emailCtrl.text.trim(),
      password: passCtrl.text,
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
