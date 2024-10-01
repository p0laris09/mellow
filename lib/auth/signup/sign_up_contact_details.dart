import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellow/auth/signup/sign_up_review_details.dart';

class SignUpContactDetails extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String university;
  final String college;
  final String program;
  final String year;

  SignUpContactDetails({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.university,
    required this.college,
    required this.program,
    required this.year,
  });

  @override
  _SignUpContactDetailsState createState() => _SignUpContactDetailsState();
}

class _SignUpContactDetailsState extends State<SignUpContactDetails> {
  final TextEditingController _phoneController = TextEditingController(text: '+63 9');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _errorMessage;

  // Regex for email validation
  final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  // Updated Regex for password validation (min 8 characters, 1 upper, 1 lower, 1 special character)
  final RegExp passwordRegExp = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$");

  // Phone number validation starts with +63 9 and follows by 9 digits
  bool isValidPhilippinePhoneNumber(String phoneNumber) {
    return RegExp(r'^\+63 9\d{9}$').hasMatch(phoneNumber);
  }

  void _validateAndNavigate() {
    setState(() {
      _errorMessage = null; // Clear previous error message
    });

    // Check if fields are empty
    if (_phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields!';
      });
      return;
    }

    // Validate phone number
    if (!isValidPhilippinePhoneNumber(_phoneController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid Philippine phone number starting with +63 9XXXXXXXXX.';
      });
      return;
    }

    // Validate email
    if (!emailRegExp.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    // Validate password (min 8 chars, upper and lowercase letter, and special character)
    if (!passwordRegExp.hasMatch(_passwordController.text)) {
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters, include an uppercase letter,\na lowercase letter, a digit, and a special character.';
      });
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match!';
      });
      return;
    }

    // Navigate to the next page if validation passes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountReviewScreen(
          firstName: widget.firstName,
          middleName: widget.middleName,
          lastName: widget.lastName,
          birthday: widget.birthday,
          university: widget.university,
          college: widget.college,
          program: widget.program,
          year: widget.year,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  // Ensure that the first 5 characters cannot be edited (i.e., "+63 9")
  void _onPhoneChanged(String value) {
    if (value.length < 5) {
      _phoneController.text = '+63 9';
      _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneController.text.length));
    }
  }

  @override
  void initState() {
    super.initState();

    // Attach a listener to the phone controller to handle custom behavior
    _phoneController.addListener(() {
      _onPhoneChanged(_phoneController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
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
                    "Input your contact and\naccount details.",
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
              height: 590,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Error message container
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
                    // Phone Number
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(14)
                        ],
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Email
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30)
                        ],
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Password
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Confirm Password
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible = !_confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Continue Button
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
