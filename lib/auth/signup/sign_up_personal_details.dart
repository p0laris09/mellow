import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/auth/onboarding/onboarding.dart';
import 'package:mellow/auth/signin/sign_in.dart';
import 'package:mellow/auth/signup/sign_up_college_details.dart';

class SignUpPersonalDetails extends StatefulWidget {
  const SignUpPersonalDetails({super.key});

  @override
  _SignUpPersonalDetailsState createState() => _SignUpPersonalDetailsState();
}

class _SignUpPersonalDetailsState extends State<SignUpPersonalDetails> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime maxDate =
        now.subtract(const Duration(days: 365 * 18)); // 18 years ago
    DateTime minDate =
        now.subtract(const Duration(days: 365 * 50)); // 50 years ago

    DateTime initialDate = now.isAfter(maxDate) ? maxDate : now;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor:
                const Color(0xFF2275AA), // Match the page primary color
            hintColor: const Color(0xFF2275AA), // Match the page accent color
            colorScheme: const ColorScheme.light(primary: Color(0xFF2275AA)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (_isAgeValid(pickedDate)) {
        setState(() {
          _selectedDate = pickedDate;
          _birthdayController.text =
              DateFormat('MM/dd/yyyy').format(pickedDate);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid date.')),
        );
      }
    }
  }

  /// Helper function to validate the age range
  bool _isAgeValid(DateTime date) {
    int age = _calculateAge(date);
    return age >= 18 && age <= 50;
  }

  void _validateAndNavigate() {
    // Check if required fields are empty
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty) {
      _showErrorDialog('Please fill in all required fields!');
      return;
    }

    // Parse the birthday from the controller
    DateTime? birthday;
    try {
      birthday = DateFormat('MM/dd/yyyy').parse(_birthdayController.text);
    } catch (e) {
      _showErrorDialog('Invalid date format! Please use MM/DD/YYYY.');
      return;
    }

    // Validate age
    int age = _calculateAge(birthday);
    if (age < 18 || age > 50) {
      _showErrorDialog('Age must be between 18 and 50 years.');
      return;
    }

    // Navigate to the next page if validation passes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpCollegeDetails(
          firstName: _firstNameController.text,
          middleName: _middleNameController.text,
          lastName: _lastNameController.text,
          birthday: _birthdayController.text,
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title: const Text("Error", style: TextStyle(color: Colors.white)),
          content:
              Text(errorMessage, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper function to calculate the age from a birth date
  int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;

    // Adjust age if the birth date hasn't yet occurred this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const OnboardingPage()), // Navigate to the onboarding page
              (Route<dynamic> route) => false, // Remove all previous routes
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Create your\nAccount",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Start creating your account by\ninputting your personal details.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 615,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(100),
                        ],
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(100),
                        ],
                        controller: _middleNameController,
                        decoration: const InputDecoration(
                          labelText: "Middle Name (Optional)",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(100),
                        ],
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _birthdayController,
                        readOnly: true, // Make the TextField read-only
                        onTap: () => _selectDate(
                            context), // Show the date picker when tapped
                        decoration: InputDecoration(
                          labelText: "Birthday",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(
                                context), // Show the date picker when the icon is pressed
                          ),
                          hintText: 'mm/dd/yyyy',
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: 315,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _validateAndNavigate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF2275AA),
                        ),
                        child: const Text(
                          "NEXT",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignInPage()),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
