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

  // ============================================================
  // DESIGN SETTINGS
  // Change these values to adjust the layout easily
  // ============================================================

  // Maximum width of the login section
  static const double maxContentWidth = 400;

  // 3D illustration height
  static const double imageHeightDesktop = 280;
  static const double imageHeightMobile = 210;

  // Space between illustration and login card
  static const double imageCardSpacing = 5;

  // Login card padding
  static const double cardPadding = 32;

  // Space between form fields
  static const double fieldSpacing = 16;

  // Space before login button
  static const double buttonSpacing = 24;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: isMobile ? 20 : 30,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // 3D HOSTEL SWAP ILLUSTRATION
                  // ==================================================
                  SizedBox(
                    height: isMobile ? imageHeightMobile : imageHeightDesktop,
                    width: double.infinity,

                    child: Image.asset(
                      'assets/images/hostel_swap_login.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Space between image and card
                  const SizedBox(height: imageCardSpacing),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(cardPadding),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            // ==================================================
                            // TITLE
                            // ==================================================
                            Text(
                              'HostelSwap',
                              style: TextStyle(
                                fontSize: isMobile ? 28 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Find your perfect hostel swap match',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 28),

                            // ==================================================
                            // COLLEGE ID
                            // ==================================================
                            TextFormField(
                              controller: _collegeIdController,

                              decoration: const InputDecoration(
                                labelText: 'College ID',
                                hintText: 'e.g., 12419027',

                                border: OutlineInputBorder(),

                                prefixIcon: Icon(Icons.badge_outlined),
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your College ID';
                                }

                                if (value.trim().length < 5) {
                                  return 'Invalid College ID format';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: fieldSpacing),

                            // ==================================================
                            // GENDER
                            // ==================================================
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Gender',

                                border: OutlineInputBorder(),

                                prefixIcon: Icon(Icons.person_outline),
                              ),

                              value: _selectedGender,

                              items: AppConstants.genders.map((gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender.toUpperCase()),
                                );
                              }).toList(),

                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },

                              validator: (value) {
                                if (value == null) {
                                  return 'Please select your gender';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: buttonSpacing),

                            // ==================================================
                            // LOGIN BUTTON
                            // ==================================================
                            SizedBox(
                              height: 52,

                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);

      final user = await authNotifier.login(
        _collegeIdController.text.trim(),
        _selectedGender!,
      );

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _collegeIdController.dispose();
    super.dispose();
  }
}
