import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateAccountInfo/review_update_details.dart';

class UpdateCollegeInfo extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String gender;
  final String phoneNumber;

  const UpdateCollegeInfo({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.gender,
    required this.phoneNumber,
  });

  @override
  _UpdateCollegeInfoState createState() => _UpdateCollegeInfoState();
}

class _UpdateCollegeInfoState extends State<UpdateCollegeInfo> {
  final TextEditingController _universityController =
      TextEditingController(text: "University of Makati");
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  String? _selectedYear;
  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year'
  ];

  String? _errorMessage;

  String? _selectedCollege;
  final List<String> _colleges = [
    'College of Liberal Arts and Science',
    'College of Human Kinetics',
    'College of Business and Financial Sciences',
    'College of Computing and Information Sciences',
    'College of Innovative Teacher Education',
    'College of Governance and Public Policy',
    'College of Construction Science and Engineering',
    'College of Technology Management',
    'College of Tourism and Hospitality Management',
    'College of Continuing, Advance and Professional Studies',
  ];

  String? _selectedProgram;
  final List<String> _clasPrograms = [];
  final List<String> _chkPrograms = [
    'Bachelor of Science in Exercise and Sports Science Major in Sports and Fitness Management',
  ];
  final List<String> _cbfsPrograms = [
    'Bachelor of Science in Office Administration',
    'Bachelor of Science in Entrepreneurial Management',
    'Bachelor of Science in Financial Management',
    'Bachelor of Science in Business Administration major in Marketing Management',
    'Bachelor of Science in Business Administration major in Human Resource Development Management',
    'Bachelor of Science in Business Administration major in Supply Management',
    'Bachelor of Science in Business Administration major in Building and Property Management',
    'Associate in Sales Management',
    'Associate in Office Management Technology',
    'Associate in Entrepreneurship',
    'Associate in Supply Management',
    'Associate in Building and Property Management',
  ];
  final List<String> _ccisPrograms = [
    'Bachelor of Science in Information Technology (Information and Network Security Elective Track)',
    'Bachelor of Science in Computer Science (Computational and Data Sciences Elective Track)',
    'Bachelor of Science in Computer Science (Application Development Elective Track)',
    'Diploma in Application Development',
    'Diploma in Computer Network Administration',
  ];
  final List<String> _citePrograms = [
    'Bachelor of Secondary Education Major in English',
    'Bachelor of Secondary Education Major in Mathematics',
    'Bachelor of Secondary Education Major in Social Studies',
    'Bachelor of Elementary Education',
  ];
  final List<String> _cgppPrograms = [
    'Bachelor of Arts in Political Science major in Paralegal Studies',
    'Bachelor of Arts in Political Science major in Policy Management',
    'Bachelor of Arts in Political Science major in Local Government Administration',
  ];
  final List<String> _ccsePrograms = [
    'B.S. in Civil Engineering In Construction Engineering and Management',
  ];
  final List<String> _ctmPrograms = [
    'Bachelor of Science in Building Technology Management',
    'Bachelor of Science in Electrical Technology',
    'Bachelor of Science in Electronics and Telecommunication Technology',
    'Bachelor in Automotive Technology',
    'Diploma in Electrical Technology',
    'Diploma in Industrial Facilities Technology',
    'Diploma in Industrial Facilities Technology Major in Service Mechanics',
    'Associate in Electronics Technology',
    'Certificate in Building Technology Management',
  ];
  final List<String> _cthmPrograms = [
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Science in Tourism Management',
    'Associate in Hospitality Management',
  ];
  final List<String> _ccapsPrograms = [];

  List<String> _getPrograms() {
    switch (_selectedCollege) {
      case 'College of Liberal Arts and Science':
        return _clasPrograms;
      case 'College of Human Kinetics':
        return _chkPrograms;
      case 'College of Business and Financial Sciences':
        return _cbfsPrograms;
      case 'College of Computing and Information Sciences':
        return _ccisPrograms;
      case 'College of Innovative Teacher Education':
        return _citePrograms;
      case 'College of Governance and Public Policy':
        return _cgppPrograms;
      case 'College of Construction Science and Engineering':
        return _ccsePrograms;
      case 'College of Technology Management':
        return _ctmPrograms;
      case 'College of Tourism and Hospitality Management':
        return _cthmPrograms;
      case 'College of Continuing, Advance and Professional Studies':
        return _ccapsPrograms;
      default:
        return [];
    }
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

        if (userDoc.exists) {
          setState(() {
            _universityController.text =
                userDoc['university'] ?? 'University of Makati';
            _selectedCollege = userDoc['college'] ?? ''; // Set selected college

            // Ensure the selected program exists in the current college's programs
            final loadedProgram = userDoc['program'] ?? '';
            final availablePrograms = _getPrograms();
            _selectedProgram = availablePrograms.contains(loadedProgram)
                ? loadedProgram
                : null;

            _selectedYear = userDoc['year'] ?? _years.first;
            _sectionController.text = userDoc['section'] ?? '';
          });
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load data: $error';
      });
    }
  }

  void _validateAndNavigate() {
    setState(() {
      _errorMessage = null; // Clear previous error message
    });

    // Check if fields are empty
    if (_selectedCollege == null ||
        _selectedProgram == null ||
        _selectedYear == null ||
        _sectionController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields!';
      });
      return;
    }

    // Navigate to the AccountUpdateScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountUpdateScreen(
          firstName: widget.firstName,
          middleName: widget.middleName,
          lastName: widget.lastName,
          birthday: widget.birthday,
          phoneNumber: widget.phoneNumber,
          gender: widget.gender,
          university: _universityController.text,
          college: _selectedCollege!,
          program: _selectedProgram!,
          year: _selectedYear!,
          section: _sectionController.text,
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
                    // Dropdown for College
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCollege,
                        decoration: const InputDecoration(
                          labelText: "College",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _colleges.map((String college) {
                          return DropdownMenuItem<String>(
                            value: college,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                college,
                                overflow: TextOverflow.visible,
                                maxLines: null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCollege = newValue;
                            // Reset the program whenever the college changes
                            _selectedProgram = null;
                          });
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return _colleges.map((String college) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                college,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        menuMaxHeight: 300,
                      ),
                    ),

                    const SizedBox(height: 9),

                    // Dropdown for Program
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedProgram,
                        decoration: const InputDecoration(
                          labelText: "Program",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _getPrograms().isNotEmpty
                            ? _getPrograms().map((String program) {
                                return DropdownMenuItem<String>(
                                  value: program,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 250),
                                    child: Text(
                                      program,
                                      overflow: TextOverflow
                                          .visible, // Allow wrapping
                                      maxLines: null,
                                    ),
                                  ),
                                );
                              }).toList()
                            : [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("No programs available"),
                                ),
                              ],
                        onChanged: _getPrograms().isNotEmpty
                            ? (String? newValue) {
                                setState(() {
                                  _selectedProgram = newValue;
                                });
                              }
                            : null, // Disable dropdown if no programs are available
                        selectedItemBuilder: (BuildContext context) {
                          return _getPrograms().isNotEmpty
                              ? _getPrograms().map((String program) {
                                  return ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 250),
                                    child: Text(
                                      program,
                                      overflow: TextOverflow
                                          .ellipsis, // Ellipsis for selected item
                                    ),
                                  );
                                }).toList()
                              : [
                                  const Text("No programs available"),
                                ];
                        },
                        menuMaxHeight: 300,
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
                            _selectedYear = newValue;
                          });
                        },
                        menuMaxHeight: 300, // Adjust the height as needed
                      ),
                    ),

                    // Section
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: "Section",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
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
