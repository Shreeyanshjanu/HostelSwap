import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/app_constants.dart';
import '../utils/responsive_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeIdController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 24.0 : 48.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.house,
                          size: 48,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'HostelSwap',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Find your perfect hostel swap match',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // College ID
                      TextFormField(
                        controller: _collegeIdController,
                        decoration: const InputDecoration(
                          labelText: 'College ID',
                          hintText: 'e.g., 2024CS101',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your College ID';
                          }
                          if (value.length < 5) {
                            return 'Invalid College ID format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: _selectedGender,
                        items: AppConstants.genders.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authNotifier = ref.read(authProvider.notifier);
      final user = await authNotifier.login(
        _collegeIdController.text.trim(),
        _selectedGender!,
      );

      setState(() => _isLoading = false);

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _collegeIdController.dispose();
    super.dispose();
  }
}