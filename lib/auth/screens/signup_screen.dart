import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:email_validator/email_validator.dart';

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
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  String phoneNumber = '';
  bool loading = false;

  PhoneNumber initialNumber = PhoneNumber(isoCode: 'PK');

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
              // 👤 NAME
              _field(nameCtrl, "Full Name"),

              const SizedBox(height: 12),

              // 📧 EMAIL (VALID FORMAT ONLY)
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }
                  if (!EmailValidator.validate(v.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 🌍 INTERNATIONAL PHONE INPUT
              InternationalPhoneNumberInput(
                initialValue: initialNumber,
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  useEmoji: true,
                ),
                inputDecoration: const InputDecoration(
                  labelText: "Contact Number",
                  border: UnderlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                onInputChanged: (PhoneNumber number) {
                  phoneNumber = number.phoneNumber ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Contact number required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 🔑 PASSWORD
              _password(passCtrl, "Password"),
              _password(
                confirmCtrl,
                "Confirm Password",
                confirmWith: passCtrl,
              ),

              const SizedBox(height: 20),

              // ✅ SIGNUP BUTTON
              ElevatedButton(
                onPressed: loading ? null : _signup,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("SIGN UP"),
              ),

              // 🔁 LOGIN
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          v == null || v.trim().isEmpty ? "Required" : null,
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

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid phone number")),
      );
      return;
    }

    setState(() => loading = true);

    final error = await _auth.signup(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneNumber,
      password: passCtrl.text,
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account created. Verification email sent.",
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
