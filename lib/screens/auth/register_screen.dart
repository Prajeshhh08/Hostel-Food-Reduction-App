import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../models/course.dart';
import '../../models/study_year.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Course? _selectedCourse;
  StudyYear? _selectedStudyYear;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _registrationSuccess = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _rollNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourse == null) {
      setState(() {
        _errorMessage = 'Please select a course.';
      });
      return;
    }

    if (_selectedStudyYear == null) {
      setState(() {
        _errorMessage = 'Please select your year of study.';
      });
      return;
    }

    // Roll number and course matching validation
    final courseMatchError = Validators.validateCourseMatch(
      rollNumber: _rollNumberController.text,
      selectedCourseCode: _selectedCourse?.code,
    );
    if (courseMatchError != null) {
      setState(() {
        _errorMessage = courseMatchError;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final response = await ref.read(authNotifierProvider.notifier).signUpStudent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            rollNumber: _rollNumberController.text.trim().toUpperCase(),
            courseId: _selectedCourse!.id,
            studyYearId: _selectedStudyYear!.id,
          );

      if (mounted) {
        // If session is null (email confirmation required) or signup completed
        if (response?.session == null) {
          setState(() {
            _registrationSuccess = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final coursesAsync = ref.watch(coursesListProvider);
    final studyYearsAsync = ref.watch(studyYearsListProvider);
    final isLoading = authState.isLoading;

    if (_registrationSuccess) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Color(0xFF15803D),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Account created',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please check your college email and confirm your account before logging in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Student Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 16),

                    // Roll Number
                    TextFormField(
                      controller: _rollNumberController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Roll Number (e.g. 25BCM539)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: '25BCM539',
                      ),
                      validator: Validators.validateRollNumber,
                    ),
                    const SizedBox(height: 16),

                    // Course Dropdown (Dynamic from courses table)
                    coursesAsync.when(
                      data: (courses) {
                        if (courses.isEmpty) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Course',
                              prefixIcon: const Icon(Icons.school_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Retry',
                                onPressed: () =>
                                    ref.invalidate(coursesListProvider),
                              ),
                            ),
                            child: const Text('No courses found in database'),
                          );
                        }
                        return DropdownButtonFormField<Course>(
                          initialValue: _selectedCourse,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          hint: const Text('Select Course'),
                          items: courses.map((course) {
                            return DropdownMenuItem<Course>(
                              value: course,
                              child: Text('${course.code} - ${course.name}'),
                            );
                          }).toList(),
                          onChanged: (course) {
                            setState(() {
                              _selectedCourse = course;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a course' : null,
                        );
                      },
                      loading: () => const InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Loading courses from database...'),
                          ],
                        ),
                      ),
                      error: (err, _) => InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Course',
                          prefixIcon: const Icon(Icons.school_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            tooltip: 'Retry',
                            onPressed: () => ref.invalidate(coursesListProvider),
                          ),
                        ),
                        child: Text(
                          'Failed: ${ErrorHandler.getFriendlyErrorMessage(err)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Year of Study Dropdown (Dynamic from study_years table)
                    studyYearsAsync.when(
                      data: (years) {
                        if (years.isEmpty) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Year of Study',
                              prefixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Retry',
                                onPressed: () =>
                                    ref.invalidate(studyYearsListProvider),
                              ),
                            ),
                            child: const Text('No study years found in database'),
                          );
                        }
                        return DropdownButtonFormField<StudyYear>(
                          initialValue: _selectedStudyYear,
                          decoration: const InputDecoration(
                            labelText: 'Year of Study',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          hint: const Text('Select Year'),
                          items: years.map((year) {
                            return DropdownMenuItem<StudyYear>(
                              value: year,
                              child: Text(year.label),
                            );
                          }).toList(),
                          onChanged: (year) {
                            setState(() {
                              _selectedStudyYear = year;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select your study year' : null,
                        );
                      },
                      loading: () => const InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Year of Study',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Loading study years...'),
                          ],
                        ),
                      ),
                      error: (err, _) => InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Year of Study',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            tooltip: 'Retry',
                            onPressed: () =>
                                ref.invalidate(studyYearsListProvider),
                          ),
                        ),
                        child: Text(
                          'Failed: ${ErrorHandler.getFriendlyErrorMessage(err)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'College Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) => Validators.validateConfirmPassword(
                        val,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Create Account Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 20),

                    // Already have account
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
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
        ),
      ),
    );
  }
}
