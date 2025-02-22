import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateAccountInfo/update_college_info.dart';

class UpdatePersonalInfo extends StatefulWidget {
  const UpdatePersonalInfo({super.key});

  @override
  _UpdatePersonalInfoState createState() => _UpdatePersonalInfoState();
}

class _UpdatePersonalInfoState extends State<UpdatePersonalInfo> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: '+63 9');

  String? _selectedGender;
  final List<String> _gender = [
    'Male',
    'Female',
  ];

  // Phone number validation starts with +63 9 and follows by 9 digits
  bool isValidPhilippinePhoneNumber(String phoneNumber) {
    return RegExp(r'^\+63 9\d{9}$').hasMatch(phoneNumber);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        // Populate each text field with data from Firestore
        _firstNameController.text = userDoc['firstName'] ?? '';
        _middleNameController.text = userDoc['middleName'] ?? '';
        _lastNameController.text = userDoc['lastName'] ?? '';
        _birthdayController.text = userDoc['birthday'] ?? '';
        _phoneController.text = userDoc['phoneNumber'] ?? '+63 9';

        // Set initial gender dropdown value
        setState(() {
          _selectedGender = userDoc['gender'];
        });

        // Parse birthday string into DateTime if available
        if (userDoc['birthday'] != null) {
          _selectedDate = DateFormat('MM/dd/yyyy').parse(userDoc['birthday']);
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load data: $error';
      });
    }
  }

  String? _errorMessage;
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime maxDate = now.subtract(Duration(days: 365 * 18)); // 18 years ago
    DateTime minDate = now.subtract(Duration(days: 365 * 50)); // 50 years ago

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
            colorScheme: ColorScheme.light(primary: const Color(0xFF2275AA)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
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

    // Check if fields are empty
    if (_phoneController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty ||
        _selectedGender == null) {
      setState(() {
        _errorMessage = 'Please fill in all fields!';
      });
      return;
    }

    // Navigate to the next page if validation passes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCollegeInfo(
          firstName: _firstNameController.text,
          middleName: _middleNameController.text,
          lastName: _lastNameController.text,
          birthday: _birthdayController.text,
          gender: _selectedGender!,
          phoneNumber: _phoneController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
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
                    "Update your\nAccount",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Update your account by\ninputting your personal details.",
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
              height: 597,
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
                      height: 30,
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
                          FilteringTextInputFormatter.allow(RegExp(
                              r'[a-zA-Z\s]')), // Allow alphabetic characters and spaces
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
                          FilteringTextInputFormatter.allow(RegExp(
                              r'[a-zA-Z\s]')), // Allow alphabetic characters and spaces
                          LengthLimitingTextInputFormatter(100),
                        ],
                        controller: _middleNameController,
                        decoration: const InputDecoration(
                          labelText: "Middle Name",
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
                          FilteringTextInputFormatter.allow(RegExp(
                              r'[a-zA-Z\s]')), // Allow alphabetic characters and spaces
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

                    // Phone Number
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [LengthLimitingTextInputFormatter(14)],
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
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        items: _gender.map((String gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newGender) {
                          setState(() {
                            _selectedGender = newGender;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Gender",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
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
