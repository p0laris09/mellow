import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellow/auth/signup/sign_up_contact_details.dart';

class SignUpCollegeDetails extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;

  SignUpCollegeDetails({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
  });

  @override
  _SignUpCollegeDetailsState createState() => _SignUpCollegeDetailsState();
}

class _SignUpCollegeDetailsState extends State<SignUpCollegeDetails> {
  final TextEditingController _universityController =
      TextEditingController(text: "University of Makati");
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _programController = TextEditingController();

  // For dropdown
  String? _selectedYear;
  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year'
  ]; // List of years

  String? _errorMessage;

  void _validateAndNavigate() {
    setState(() {
      _errorMessage = null; // Clear previous error message
    });

    // Check if fields are empty
    if (_collegeController.text.isEmpty ||
        _programController.text.isEmpty ||
        _selectedYear == null) {
      setState(() {
        _errorMessage = 'Please fill in all required fields!';
      });
      return;
    }

    // Navigate to the next page if validation passes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpContactDetails(
          firstName: widget.firstName,
          middleName: widget.middleName,
          lastName: widget.lastName,
          birthday: widget.birthday,
          university: _universityController.text,
          college: _collegeController.text,
          program: _programController.text,
          year: _selectedYear!,
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
                    "Input the necessary details\nabout your university.",
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
                    // University
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _universityController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "University",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // College TextField
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(200),
                        ],
                        controller: _collegeController,
                        decoration: const InputDecoration(
                          labelText: "College",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Program
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(200),
                        ],
                        controller: _programController,
                        decoration: const InputDecoration(
                          labelText: "Program",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Dropdown for Year
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: "Year",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _years.map((String year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 250),
                              child: Text(
                                year,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedYear = newValue;
                          });
                        },
                        menuMaxHeight: 300, // Adjust the height as needed
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Next Page button
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
