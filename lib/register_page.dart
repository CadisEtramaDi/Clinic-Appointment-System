import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String? _selectedGender;
  String _selectedRole = 'patient';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Please agree to the terms and conditions'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        print('Creating user account...');

        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        print('✓ User created in Auth: ${userCredential.user!.uid}');

        // Prepare user data
        Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'gender': _selectedGender,
          'birthdate': _selectedDate != null
              ? Timestamp.fromDate(_selectedDate!)
              : null,
          'age': _selectedDate != null ? _calculateAge(_selectedDate!) : null,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add role-specific fields
        if (_selectedRole == 'doctor') {
          userData['specialization'] = _specializationController.text.trim();
          userData['licenseNumber'] = _licenseController.text.trim();
          userData['isVerified'] = false;
          userData['totalPatients'] = 0;
          userData['rating'] = 5.0;
        }

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        print('✓ User document created in Firestore');

        // Update display name
        await userCredential.user!.updateDisplayName(
          _nameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedRole == 'doctor'
                          ? 'Registration successful! Please wait for admin verification.'
                          : 'Registration successful! You can now log in.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          // Sign out the user so they go back to login
          await FirebaseAuth.instance.signOut();
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);

        String errorMessage = 'Error occurred during registration';

        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Use at least 6 characters';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }

        print('✗ Registration error: ${e.code} - $errorMessage');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        print('✗ Unexpected error: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Column(
                  children: const [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 90,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Create Your Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Join us to continue",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: inputDecoration(
                            "Register as",
                            Icons.badge_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'patient',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Patient'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'doctor',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Doctor'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedRole = value!),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        buildInput(
                          label: "Full Name",
                          icon: Icons.person_outline,
                          controller: _nameController,
                          validator: (value) =>
                              value!.isEmpty ? "Enter your full name" : null,
                        ),
                        const SizedBox(height: 16),

                        // Gender
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: inputDecoration("Gender", Icons.person),
                          items: ["Male", "Female", "Other"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedGender = value),
                          validator: (value) =>
                              value == null ? "Select your gender" : null,
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: inputDecoration(
                            "Date of Birth",
                            Icons.calendar_today_outlined,
                            suffix: Icons.calendar_month,
                            onSuffixPressed: () => _selectDate(context),
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) =>
                              value!.isEmpty ? "Select your birth date" : null,
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Age: ${_calculateAge(_selectedDate!)} years old",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Doctor-specific fields
                        if (_selectedRole == 'doctor') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Doctor accounts require admin verification before activation',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildInput(
                            label: "Specialization",
                            icon: Icons.medical_services_outlined,
                            controller: _specializationController,
                            validator: (value) => value!.isEmpty
                                ? "Enter your specialization"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          buildInput(
                            label: "License Number",
                            icon: Icons.card_membership_outlined,
                            controller: _licenseController,
                            validator: (value) => value!.isEmpty
                                ? "Enter your license number"
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        buildInput(
                          label: "Email",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) return "Enter your email";
                            if (!value.contains("@")) return "Invalid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        buildPasswordInput(
                          label: "Password",
                          controller: _passwordController,
                          isVisible: _isPasswordVisible,
                          onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return "Enter a password";
                            if (value.length < 6)
                              return "Password must be at least 6 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        buildPasswordInput(
                          label: "Confirm Password",
                          controller: _confirmPasswordController,
                          isVisible: _isConfirmPasswordVisible,
                          onToggle: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return "Confirm your password";
                            if (value != _passwordController.text)
                              return "Passwords do not match";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Terms Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (val) =>
                                  setState(() => _agreeToTerms = val!),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _agreeToTerms = !_agreeToTerms,
                                ),
                                child: const Text(
                                  "I agree to the Terms and Conditions",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Login Redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(
    String label,
    IconData icon, {
    IconData? suffix,
    VoidCallback? onSuffixPressed,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF1F4F9),
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix != null
          ? IconButton(icon: Icon(suffix), onPressed: onSuffixPressed)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget buildInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildPasswordInput({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
