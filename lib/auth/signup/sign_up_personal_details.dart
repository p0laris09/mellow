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

  String? _errorMessage;
  DateTime? _selectedDate;

  String? _selectedGender;
  final List<String> _gender = [
    'Male',
    'Female',
  ];

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = _selectedDate ?? currentDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: currentDate,
    );

    if (pickedDate != null && pickedDate != initialDate) {
      setState(() {
        _selectedDate = pickedDate;
        _birthdayController.text = DateFormat('MM/dd/yyyy').format(pickedDate);
      });
    }
  }

  void _validateAndNavigate() {
    setState(() {
      _errorMessage = null; // Clear previous error message
    });

    // Check if required fields are empty
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty ||
        _selectedGender == null) {
      setState(() {
        _errorMessage = 'Please fill in all required fields!';
      });
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
          gender: _selectedGender!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      OnboardingPage()), // Navigate to the onboarding page
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
                    Container(
                      height: 45,
                      margin: const EdgeInsets.only(bottom: 16),
                      alignment: Alignment.center,
                      child: _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : null,
                    ),
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
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                          LengthLimitingTextInputFormatter(10),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            if (text.length == 2 || text.length == 5) {
                              return TextEditingValue(
                                text: '$text/',
                                selection: TextSelection.collapsed(
                                    offset: text.length + 1),
                              );
                            }
                            return newValue;
                          }),
                        ],
                        decoration: InputDecoration(
                          labelText: "Birthday",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                          hintText: 'mm/dd/yyyy',
                        ),
                      ),
                    ),
                    // Dropdown for Year
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: "Gender",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _gender.map((String year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                year,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        menuMaxHeight: 300,
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
                          backgroundColor: const Color(0xFF2C3C3C),
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
                                    builder: (context) => SignInPage()),
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
