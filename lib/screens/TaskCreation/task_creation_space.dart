import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/TaskModel/task_model_space.dart';

class TaskCreationSpace extends StatefulWidget {
  const TaskCreationSpace({
    super.key,
  });

  @override
  State<TaskCreationSpace> createState() => _TaskCreationSpaceState();
}

class _TaskCreationSpaceState extends State<TaskCreationSpace> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String taskType = 'space'; // Default task type is space
  List<String> selectedMembers = [];
  Map<String, String> memberNamesMap = {}; // Map UID to name
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _complexity = 1;

  String? _selectedSpace; // Add a variable to hold the selected space
  List<Map<String, String>> _spaces =
      []; // Add a list to hold the available spaces

  // Initialize TaskManager
  late TaskManager taskManager;

  @override
  void initState() {
    super.initState();

    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });

    _loadSpaces(); // Load the available spaces

    // Initialize TaskManager with the current user ID
    taskManager = TaskManager(currentUserId: _auth.currentUser?.uid ?? '');
  }

  Future<void> _loadSpaces() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members', arrayContains: user.uid)
          .get();

      setState(() {
        _spaces = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id as String,
            'name': doc['name'] as String,
          };
        }).toList();
      });

      if (_spaces.isNotEmpty) {
        _selectedSpace =
            _spaces.first['id']; // Set the first space ID as selected
      }
    } catch (e) {
      print('Error loading spaces: $e');
    }
  }

  Future<void> showAssignedMembersDialog(BuildContext context) async {
    if (_selectedSpace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a space first')),
      );
      return;
    }

    try {
      // Fetch the space document using the space ID
      final spaceDoc = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(_selectedSpace)
          .get();
      if (!spaceDoc.exists) {
        print('Space not found');
        return;
      }

      final spaceData = spaceDoc.data()!;

      // Get members from the space document
      List<String> memberUids = List<String>.from(spaceData['members'] ?? []);
      if (memberUids.isEmpty) {
        print('No members found in this space');
        return;
      }

      // Fetch user details (name) for each member from the users collection
      final userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberUids)
          .get();

      // Create a map of UID to name
      final uidNameMap = <String, String>{};
      for (var userDoc in userDocs.docs) {
        uidNameMap[userDoc.id] = '${userDoc['firstName'] ?? ''} '
                '${userDoc['middleName']?.isNotEmpty == true ? userDoc['middleName'] + ' ' : ''}'
                '${userDoc['lastName'] ?? ''}'
            .trim();
      }

      // Now we will show the dialog with the list of members
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2275AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Select Members',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Center(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Members',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        memberUids.isEmpty
                            ? const Text(
                                'No members in this space.',
                                style: TextStyle(color: Colors.red),
                              )
                            : Wrap(
                                spacing: 8,
                                children: memberUids.map((uid) {
                                  bool isSelected =
                                      selectedMembers.contains(uid);
                                  return ChoiceChip(
                                    label: Text(uidNameMap[uid] ?? 'Unknown'),
                                    selected: isSelected,
                                    selectedColor: Colors.green,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedMembers.add(uid); // Add UID
                                        } else {
                                          selectedMembers
                                              .remove(uid); // Remove UID
                                        }
                                      });
                                    },
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    backgroundColor: Colors.white,
                                    selectedShadowColor: Colors.green,
                                    shadowColor: Colors.grey,
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Select'),
                    onPressed: () {
                      Navigator.of(context).pop(selectedMembers);
                      // Update the member names map with selected UIDs
                      setState(() {
                        memberNamesMap = uidNameMap;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((selectedMembers) {
        if (selectedMembers != null) {
          setState(() {
            this.selectedMembers = List<String>.from(selectedMembers);
          });
        }
      });
    } catch (e) {
      print("Error fetching members: $e");
    }
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevent picking past dates
      lastDate: DateTime(2101),
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
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (combinedDateTime.isAfter(now)) {
          // Only allow future times
          String formattedDateTime =
              DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
          controller.text = formattedDateTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a future time.')),
          );
        }
      }
    }
  }

  Future<void> _createTaskInFirestore() async {
    String taskName = _taskNameController.text;
    String dueDateString = _dueDateController.text;
    String startTimeString = _startTimeController.text;
    String endTimeString = _endTimeController.text;
    String description = _descriptionController.text;
    String? userId = FirebaseAuth
        .instance.currentUser?.uid; // This is the user creating the task
    String? spaceId = _selectedSpace; // Use the selected space ID
    List<String> assignedTo =
        selectedMembers; // Use the local selectedMembers list

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    if (assignedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please assign the task to at least one member')),
      );
      return;
    }

    DateTime? dueDate = dueDateString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(dueDateString)
        : null;
    DateTime? startTime = startTimeString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(startTimeString)
        : null;
    DateTime? endTime = endTimeString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(endTimeString)
        : null;

    if (taskName.isNotEmpty &&
        dueDate != null &&
        startTime != null &&
        endTime != null &&
        spaceId != null) {
      // Determine the task type
      String taskType = 'space'; // Assuming this is a space task

      // Create a new Task object with both userId and spaceId
      Task newTask = Task(
        userId: userId, // Store userId (creator's ID)
        spaceId: spaceId, // Store spaceId
        taskName: taskName,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        description: description,
        priority: _priority,
        urgency: _urgency,
        complexity: _complexity,
        assignedTo: assignedTo,
      );

      // Calculate the weight of the task
      newTask.updateWeight(taskManager.criteriaWeights);

      // Add the task to TaskManager
      taskManager.addTask(newTask);

      // Apply Eisenhower Matrix
      taskManager.applyEisenhowerMatrix();

      // Debugging: Print task details
      print('Task created: ${newTask.toString()}');

      try {
        // Add the task to Firestore
        final taskDocRef =
            await FirebaseFirestore.instance.collection('tasks').add({
          'userId': userId,
          'spaceId': spaceId,
          'taskName': taskName,
          'dueDate': dueDate,
          'startTime': startTime,
          'endTime': endTime,
          'description': description,
          'priority': _priority,
          'urgency': _urgency,
          'complexity': _complexity,
          'weight': newTask.weight, // Include the weight field
          'assignedTo': assignedTo,
          'taskType': taskType, // Include the taskType field
          'createdAt': FieldValue.serverTimestamp(), // Add createdAt field
        });

        // Create activity for the task creation
        final activityData = {
          'spaceId': spaceId,
          'createdBy': userId,
          'taskName': taskName,
          'assignedTo': assignedTo,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'task_created',
        };

        await FirebaseFirestore.instance
            .collection('activities')
            .add(activityData);

        // Show success message and close the screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        // Log the error and show an error message
        print('Error creating task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  Widget _buildSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black), // Set header text color to black
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Very Low',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Low',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Medium',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('High',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Very High',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
          ],
        ),
        Slider(
          value: value,
          min: 1, // Start at 1
          max: 5, // End at 5
          divisions: 4, // Only 5 values: 1, 2, 3, 4, 5
          onChanged: onChanged,
          activeColor: const Color(0xFF2275AA), // Set active color to blue
          inactiveColor:
              const Color(0xFFB0C4DE), // Set inactive color to light blue
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create a Task',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _taskNameController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Task Name",
                        labelStyle: TextStyle(
                          color: Colors.white,
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
                      value: _selectedSpace,
                      items: _spaces.map((space) {
                        return DropdownMenuItem<String>(
                          value: space['id'],
                          child: Text(
                            space['name']!,
                            style: const TextStyle(
                              color: Colors
                                  .black, // Set text color to black when choosing
                              fontSize: 16, // Set font size
                            ),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _spaces.map((space) {
                          return Text(
                            space['name']!,
                            style: const TextStyle(
                              color: Colors
                                  .white, // Set text color to white when selected
                              fontSize: 16, // Set font size
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedSpace = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Space",
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Set font size
                        ),
                        border: UnderlineInputBorder(),
                      ),
                      style: const TextStyle(
                        color: Colors.white, // Set text color to white
                        fontSize: 16, // Set font size
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            SizedBox(
              height: 1200,
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
                    const SizedBox(height: 16),
                    // Update the TextField widgets for due date, start time, and end time
                    SizedBox(
                      width: 325,
                      child: TextField(
                        controller: _dueDateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Due Date",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.black),
                            onPressed: () {
                              _selectDateTime(context, _dueDateController);
                            },
                          ),
                          hintText: 'yyyy-mm-dd hh:mm',
                        ),
                        onTap: () {
                          _selectDateTime(context, _dueDateController);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _startTimeController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: "Start Time",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              border: const UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time,
                                    color: Colors.black),
                                onPressed: () {
                                  _selectDateTime(
                                      context, _startTimeController);
                                },
                              ),
                              hintText: 'hh:mm',
                            ),
                            onTap: () {
                              _selectDateTime(context, _startTimeController);
                            },
                          ),
                        ),
                        const SizedBox(width: 25),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _endTimeController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: "End Time",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              border: const UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time,
                                    color: Colors.black),
                                onPressed: () {
                                  _selectDateTime(context, _endTimeController);
                                },
                              ),
                              hintText: 'hh:mm',
                            ),
                            onTap: () {
                              _selectDateTime(context, _endTimeController);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 325,
                      child: TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.black),
                        maxLines: 4,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(250)
                        ],
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixText: "$_descriptionCharCount/250",
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    _buildSlider("Priority", _priority, (value) {
                      setState(() {
                        _priority = value;
                      });
                    }),
                    const SizedBox(height: 15),
                    _buildSlider("Urgency", _urgency, (value) {
                      setState(() {
                        _urgency = value;
                      });
                    }),
                    const SizedBox(height: 15),
                    _buildSlider("Complexity", _complexity, (value) {
                      setState(() {
                        _complexity = value;
                      });
                    }),
                    const SizedBox(height: 45),
                    SizedBox(
                      width: 325,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text(
                                'Assigned to:',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    showAssignedMembersDialog(context),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF2275AA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Add Members'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: selectedMembers
                                .map((memberUid) => Chip(
                                      label: Text(memberNamesMap[memberUid] ??
                                          'Unknown'),
                                      deleteIcon: const Icon(Icons.close),
                                      onDeleted: () {
                                        setState(() {
                                          selectedMembers.remove(memberUid);
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: ElevatedButton(
                        onPressed: _createTaskInFirestore,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF2275AA),
                        ),
                        child: const Text('Create Task'),
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
