import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';

class TaskPreferenceScreen extends StatefulWidget {
  const TaskPreferenceScreen({super.key});

  @override
  _TaskPreferenceScreenState createState() => _TaskPreferenceScreenState();
}

class _TaskPreferenceScreenState extends State<TaskPreferenceScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveTaskPreferences(Map<String, dynamic> preferences) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("User is not logged in.");
        return;
      }

      await FirebaseFirestore.instance
          .collection('task_preference')
          .doc(userId) // Use UID to avoid duplicates
          .set(preferences);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompletionScreen()),
      );
    } catch (e) {
      print("Error saving preferences: $e");
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title: const Text("Error", style: TextStyle(color: Colors.white)),
          content: const Text("Failed to save preferences. Please try again.",
              style: TextStyle(color: Colors.white70)),
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          WelcomeScreen(onStart: _nextPage),
          SinglePreferencePage(
              onSave: _saveTaskPreferences, pageController: _pageController),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(Icons.tune_rounded, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            "Welcome to Your Personalized Task Experience!",
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          const Text(
            "Tell us how you usually manage your tasks so we can optimize Mellow for you!",
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2275AA)),
              child: const Text("Start"),
            ),
          ),
        ],
      ),
    );
  }
}

class SinglePreferencePage extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final PageController pageController;

  const SinglePreferencePage(
      {super.key, required this.onSave, required this.pageController});

  @override
  _SinglePreferencePageState createState() => _SinglePreferencePageState();
}

class _SinglePreferencePageState extends State<SinglePreferencePage> {
  final Map<int, String?> _selectedOptions = {};
  final Map<int, Set<String>> _selectedCheckboxOptions = {};
  String? _selectedDropdownValue;
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;

  final List<String> questions = [
    "What time of day are you most productive?",
    "How do you prefer to complete your tasks?",
    "How do you prioritize your tasks?",
    "Do you prefer strict deadlines or flexible task management?",
    "How many tasks can you realistically complete in a day?",
    "How much time do you usually spend on tasks?",
    "What type of tasks do you commonly have?",
    "How often do you work on long-term projects?",
    "How often do you take breaks between tasks?",
    "What are your biggest distractions while working/studying?",
    "Do you prefer working alone or in groups?",
    "How often do you check notifications about tasks?",
    "How many tasks can you accomplish or accommodate in an hour?"
  ];

  final List<List<String>> options = [
    [
      "Morning (6AM - 12PM)",
      "Afternoon (12PM - 6PM)",
      "Evening (6PM - 12AM)",
      "Late Night (12AM - 6AM)"
    ],
    [
      "One at a time (Focused)",
      "Multitasking (Switching Between Tasks)",
      "Combination of Both"
    ],
    [
      "Deadline Urgency",
      "Importance of Task (Impact on grades/projects)",
      "Difficulty Level",
      "Personal Interest in the Task"
    ],
    ["Strict deadlines", "Flexible schedules", "A mix of both"],
    ["1–3 tasks", "4–6 tasks", "7+ tasks"],
    [
      "Less than 30 minutes",
      "30 minutes – 1 hour",
      "1–2 hours",
      "More than 2 hours"
    ],
    [
      "Assignments",
      "Study Sessions",
      "Research Papers",
      "Group Projects",
      "Work/Internship Tasks",
      "Meetings & Appointments",
      "Extracurricular Activities",
      "Personal Goals (e.g., fitness, hobbies)"
    ],
    ["Daily", "Weekly", "Only close to the deadline"],
    [
      "Every 25–30 minutes",
      "Every 1 hour",
      "Whenever I feel like it",
      "I try to work without breaks"
    ],
    ["Social Media", "Noise/Environment", "Procrastination", "Multitasking"],
    ["Alone", "In a group", "Depends on the task"],
    [
      "Instantly",
      "Every few hours",
      "Once a day",
      "I don’t like notifications"
    ],
    ["1 task", "2 tasks", "3 tasks", "4+ tasks"]
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels != 0) {
          setState(() {
            _isAtBottom = true;
          });
        } else {
          setState(() {
            _isAtBottom = false;
          });
        }
      }
    });
  }

  bool _areAllQuestionsAnswered() {
    for (int i = 0; i < questions.length; i++) {
      if (questions[i] == "What type of tasks do you commonly have?") {
        if (_selectedCheckboxOptions[i] == null ||
            _selectedCheckboxOptions[i]!.isEmpty) {
          return false;
        }
      } else if (questions[i] ==
          "How often do you work on long-term projects?") {
        if (_selectedDropdownValue == null) {
          return false;
        }
      } else if (_selectedOptions[i] == null) {
        return false;
      }
    }
    return true;
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title:
              const Text("Incomplete", style: TextStyle(color: Colors.white)),
          content: const Text("Please answer all questions before proceeding.",
              style: TextStyle(color: Colors.white70)),
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

  void _savePreferences() {
    final preferences = {
      'productiveTime': _selectedOptions[0],
      'taskCompletionStyle': _selectedOptions[1],
      'taskPrioritization': _selectedOptions[2],
      'deadlinePreference': _selectedOptions[3],
      'taskCompletionEstimate': _selectedOptions[4],
      'taskDuration': _selectedOptions[5],
      'taskTypes': _selectedCheckboxOptions[6]?.toList(),
      'longTermProjectFrequency': _selectedDropdownValue,
      'breakFrequency':
          _selectedOptions[8], // Corrected index for breakFrequency
      'biggestDistraction': _selectedOptions[9],
      'collaborationPreference': _selectedOptions[10],
      'notificationCheckFrequency': _selectedOptions[11],
      'tasksPerHour': _selectedOptions[12]
    };

    widget.onSave(preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      body: Column(
        children: [
          const SizedBox(height: 80),
          const Text("Task Preferences",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...List.generate(questions.length, (index) {
                              if (questions[index] ==
                                  "What type of tasks do you commonly have?") {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(questions[index],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    ...options[index].map((option) {
                                      return CheckboxListTile(
                                        title: Text(option),
                                        value: _selectedCheckboxOptions[index]
                                                ?.contains(option) ??
                                            false,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedCheckboxOptions
                                                  .putIfAbsent(index, () => {})
                                                  .add(option);
                                            } else {
                                              _selectedCheckboxOptions[index]
                                                  ?.remove(option);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              } else if (questions[index] ==
                                  "How often do you work on long-term projects?") {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(questions[index],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    DropdownButtonFormField<String>(
                                      value: _selectedDropdownValue,
                                      hint: const Text("Select an option"),
                                      items: options[index]
                                          .map((option) =>
                                              DropdownMenuItem<String>(
                                                value: option,
                                                child: Text(option),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDropdownValue = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(questions[index],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    ...options[index]
                                        .map((option) => RadioListTile<String>(
                                              title: Text(option),
                                              value: option,
                                              groupValue:
                                                  _selectedOptions[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedOptions[index] =
                                                      value;
                                                });
                                              },
                                            ))
                                        .toList(),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF2275AA),
                            backgroundColor: Colors.white,
                            minimumSize: const Size(150, 50),
                            elevation: 0, // Remove shadow
                            shadowColor:
                                Colors.transparent // Ensure no shadow color
                            ),
                        child: const Text("Previous",
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF2275AA))),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_areAllQuestionsAnswered()) {
                            _savePreferences();
                          } else {
                            _showAlertDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 50),
                            backgroundColor: const Color(0xFF2275AA)),
                        child: const Text("Submit",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                  if (_isAtBottom)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "You have reached the bottom",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("Setup Complete!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Your task preferences have been saved.",
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DashboardScreen()),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2275AA)),
              child: const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }
}
