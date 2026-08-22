import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../config/app_constants.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _currentHostel;
  bool? _currentAc;
  int? _currentSeater;
  String? _desiredHostel;
  bool? _desiredAc;
  int? _desiredSeater;
  bool _isFlexible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Swap Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Room Section
                  const Text(
                    'Your Current Room',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Current Hostel',
                      border: OutlineInputBorder(),
                    ),
                    value: _currentHostel,
                    items: AppConstants.allHostels.map((hostel) {
                      return DropdownMenuItem(value: hostel, child: Text(hostel));
                    }).toList(),
                    onChanged: (value) => setState(() => _currentHostel = value),
                    validator: (value) => value == null ? 'Select hostel' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Current Room Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _currentAc != null ? (_currentAc! ? 'AC' : 'Non-AC') : null,
                    items: AppConstants.acTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentAc = value == 'AC';
                      });
                    },
                    validator: (value) => value == null ? 'Select room type' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Current Seater Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _currentSeater,
                    items: AppConstants.seaterTypes.map((seater) {
                      return DropdownMenuItem(value: seater, child: Text('$seater-Seater'));
                    }).toList(),
                    onChanged: (value) => setState(() => _currentSeater = value),
                    validator: (value) => value == null ? 'Select seater' : null,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Desired Room Section
                  const Text(
                    'Room You Want',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  SwitchListTile(
                    title: const Text('I\'m flexible (open to any room type)'),
                    value: _isFlexible,
                    onChanged: (value) {
                      setState(() {
                        _isFlexible = value;
                        if (value) {
                          _desiredAc = null;
                          _desiredSeater = null;
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Desired Hostel',
                      border: OutlineInputBorder(),
                    ),
                    value: _desiredHostel,
                    items: AppConstants.allHostels.map((hostel) {
                      return DropdownMenuItem(value: hostel, child: Text(hostel));
                    }).toList(),
                    onChanged: (value) => setState(() => _desiredHostel = value),
                    validator: (value) => value == null ? 'Select desired hostel' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Desired Room Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _desiredAc != null ? (_desiredAc! ? 'AC' : 'Non-AC') : null,
                    items: [
                      if (_isFlexible) const DropdownMenuItem(value: null, child: Text('Flexible')),
                      ...AppConstants.acTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _desiredAc = value == 'AC' ? true : (value == 'Non-AC' ? false : null);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Desired Seater Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _desiredSeater,
                    items: [
                      if (_isFlexible) const DropdownMenuItem(value: null, child: Text('Flexible')),
                      ...AppConstants.seaterTypes.map((seater) {
                        return DropdownMenuItem(value: seater, child: Text('$seater-Seater'));
                      }),
                    ],
                    onChanged: (value) => setState(() => _desiredSeater = value),
                  ),
                  
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
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
                          : const Text('Post Request', style: TextStyle(fontSize: 16)),
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
    );
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authProvider);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final requestData = {
          'user_id': user.collegeId,
          'current_hostel': _currentHostel,
          'current_ac': _currentAc,
          'current_seater': _currentSeater,
          'desired_hostel': _desiredHostel,
          'desired_ac': _desiredAc,
          'desired_seater': _desiredSeater,
          'status': 'active',
        };

        await ref.read(createRequestProvider(requestData).future);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Request posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to post request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() => _isLoading = false);
    }
  }
}