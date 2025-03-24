import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/auth/signup/sign_up_contact_details.dart';

class SignUpCollegeDetails extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String gender;

  const SignUpCollegeDetails({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.gender,
  });

  @override
  _SignUpCollegeDetailsState createState() => _SignUpCollegeDetailsState();
}

class _SignUpCollegeDetailsState extends State<SignUpCollegeDetails> {
  String? _selectedUniversity;
  List<String> _universities = [];

  final TextEditingController _sectionController = TextEditingController();

  String? _selectedYear;
  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year'
  ];

  String? _selectedCollege;
  List<String> _colleges = [];

  String? _selectedProgram;
  List<String> _programs = [];

  @override
  void initState() {
    super.initState();
    _fetchUniversities();
  }

  Future<void> _fetchUniversities() async {
    try {
      final universitiesSnapshot =
          await FirebaseFirestore.instance.collection('universities').get();

      final List<String> universities = universitiesSnapshot.docs
          .map((doc) => doc.data()['university'] as String)
          .toList();

      setState(() {
        _universities = universities;
      });
    } catch (e) {
      print("Error fetching universities: $e");
    }
  }

  Future<void> _fetchColleges(String university) async {
    try {
      final universityDoc = await FirebaseFirestore.instance
          .collection('universities')
          .where('university', isEqualTo: university)
          .get();

      if (universityDoc.docs.isNotEmpty) {
        final universityData = universityDoc.docs.first.data();
        final List<dynamic> colleges = universityData['colleges'] ?? [];
        setState(() {
          _colleges = colleges.cast<String>();
        });
      } else {
        print("University document does not exist");
      }
    } catch (e) {
      print("Error fetching colleges: $e");
    }
  }

  Future<void> _fetchPrograms(String college) async {
    try {
      final universityDoc = await FirebaseFirestore.instance
          .collection('universities')
          .where('university', isEqualTo: _selectedUniversity)
          .get();

      if (universityDoc.docs.isNotEmpty) {
        final universityData = universityDoc.docs.first.data();
        final dynamic programsData = universityData[_getProgramField(college)];

        if (programsData != null) {
          if (programsData is List) {
            setState(() {
              _programs = programsData.cast<String>();
            });
          } else if (programsData is String) {
            setState(() {
              _programs = [programsData];
            });
          }
        } else {
          setState(() {
            _programs = [];
          });
        }
      } else {
        print("University document does not exist");
      }
    } catch (e) {
      print("Error fetching programs: $e");
    }
  }

  String _getProgramField(String college) {
    switch (college) {
      case 'College of Business and Financial Sciences (CBFS)':
        return 'cbfs';
      case 'College of Innovative Teacher Education (CITE)':
        return 'cite';
      case 'College of Computing and Information Sciences (CCIS)':
        return 'ccis';
      case 'College of Construction Sciences and Engineering (CCSE)':
        return 'ccse';
      case 'College of Engineering Technology (CET)':
        return 'cet';
      case 'College of Governance and Public Policy (CGPP)':
        return 'cgpp';
      case 'College of Tourism and Hospitality Management (CTHM)':
        return 'cthm';
      case 'College of Human Kinetics (CHK)':
        return 'chk';
      case 'College of Liberal Arts and Sciences (CLAS)':
        return 'clas';
      case 'College of Continuing, Advanced and Professional Studies (CCAPS)':
        return 'ccaps';
      case 'Higher School ng UMak (CITE-HSU)':
        return 'cite';
      case 'School of Law (SOL)':
        return 'sol';
      case 'Institute of Arts and Design (IAD)':
        return 'iad';
      case 'Institute of Accountancy (IOA)':
        return 'ioa';
      case 'Institute of Pharmacy (IOP)':
        return 'iop';
      case 'Institute of Nursing (ION)':
        return 'ion';
      case 'Institute of Imaging Health Sciences (IIHS)':
        return 'iihs';
      case 'Institute of Psychology (IOPsy)':
        return 'iopsy';
      case 'Institute for Social Development and Nation Building (ISDNB)':
        return 'isdnb';
      case 'Institute of Technical Education and Skills Training (ITEST)':
        return 'itest';
      default:
        return '';
    }
  }

  void _validateAndNavigate() {
    // Check if fields are empty
    if (_selectedUniversity == null ||
        _selectedCollege == null ||
        _selectedProgram == null ||
        _selectedYear == null ||
        _sectionController.text.isEmpty) {
      _showErrorDialog('Please fill in all required fields!');
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
          gender: widget.gender,
          university: _selectedUniversity!,
          college: _selectedCollege!,
          program: _selectedProgram!,
          year: _selectedYear!,
          section: _sectionController.text,
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
                    // University Dropdown
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUniversity,
                        decoration: const InputDecoration(
                          labelText: "University",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _universities.map((String university) {
                          return DropdownMenuItem<String>(
                            value: university,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                university,
                                overflow: TextOverflow.visible,
                                maxLines: null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUniversity = newValue;
                            _selectedCollege =
                                null; // Reset college when university changes
                            _selectedProgram =
                                null; // Reset program when university changes
                            _colleges = []; // Clear colleges list
                            _programs = []; // Clear programs list
                          });
                          if (newValue != null) {
                            _fetchColleges(newValue);
                          }
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return _universities.map((String university) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                university,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        menuMaxHeight: 300,
                      ),
                    ),
                    const SizedBox(height: 9),

                    // College Dropdown
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
                                // Allow text to wrap for items in the dropdown menu
                                overflow: TextOverflow.visible,
                                maxLines: null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCollege = newValue;
                            _selectedProgram =
                                null; // Reset program when college changes
                            _programs = []; // Clear programs list
                          });
                          if (newValue != null) {
                            _fetchPrograms(newValue);
                          }
                        },
                        // Custom display for the selected item (using ellipsis)
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

                    // Program Dropdown
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
                        items: _programs.isNotEmpty
                            ? _programs.map((String program) {
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
                        onChanged: _programs.isNotEmpty
                            ? (String? newValue) {
                                setState(() {
                                  _selectedProgram = newValue;
                                });
                              }
                            : null, // Disable dropdown if no programs are available
                        selectedItemBuilder: (BuildContext context) {
                          return _programs.isNotEmpty
                              ? _programs.map((String program) {
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
                        menuMaxHeight: 300,
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Section TextField
                    SizedBox(
                      width: 300,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9\s]')),
                          LengthLimitingTextInputFormatter(50),
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
