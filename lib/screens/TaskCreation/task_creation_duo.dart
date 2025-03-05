import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TaskCreationDuo extends StatefulWidget {
  const TaskCreationDuo({super.key});

  @override
  State<TaskCreationDuo> createState() => _TaskCreationDuoState();
}

class _TaskCreationDuoState extends State<TaskCreationDuo> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String taskType = 'duo';
  String? _selectedFriends;

  final List<String> _friends = [
    // Add friends here
  ];

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _complexity = 1;

  @override
  void initState() {
    super.initState();

    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });
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

  void _createTask() {
    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty.')),
      );
      return;
    }

    if (_selectedFriends == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a friend to share the task with.')),
      );
      return;
    }

    // Implement task creation logic here
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
          'Create a Shared Task',
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
                    child: _friends.isEmpty
                        ? const Text(
                            "No friends to share task",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedFriends,
                            dropdownColor: Colors.blueGrey,
                            decoration: const InputDecoration(
                              labelText: "Share with",
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            items: _friends.map((String friends) {
                              return DropdownMenuItem<String>(
                                value: friends,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 250),
                                  child: Text(
                                    friends,
                                    overflow: TextOverflow.visible,
                                    maxLines: null,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedFriends = newValue;
                              });
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return _friends.map((String friends) {
                                return ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 250),
                                  child: Text(
                                    friends,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList();
                            },
                            menuMaxHeight: 300,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: 16,
              ),
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
                  SizedBox(
                    width: 325,
                    child: GestureDetector(
                      onTap: () {
                        // Open the date picker when the field is tapped
                        _selectDateTime(context, _dueDateController);
                      },
                      child: AbsorbPointer(
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
                            hintStyle: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        child: GestureDetector(
                          onTap: () {
                            // Open the time picker when the field is tapped
                            _selectDateTime(context, _startTimeController);
                          },
                          child: AbsorbPointer(
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      SizedBox(
                        width: 150,
                        child: GestureDetector(
                          onTap: () {
                            // Open the time picker when the field is tapped
                            _selectDateTime(context, _endTimeController);
                          },
                          child: AbsorbPointer(
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
                                    _selectDateTime(
                                        context, _endTimeController);
                                  },
                                ),
                                hintText: 'hh:mm',
                              ),
                            ),
                          ),
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
                      inputFormatters: [LengthLimitingTextInputFormatter(250)],
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
                  Center(
                    child: ElevatedButton(
                      onPressed: _createTask,
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
          ],
        ),
      ),
    );
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
          ],
        ),
        Slider(
          value: value,
          min: 1, // Start at 1
          max: 3, // End at 3
          divisions: 2, // Only 3 values: 1, 2, 3
          label: value == 1
              ? 'Low'
              : value == 2
                  ? 'Medium'
                  : 'High',
          onChanged: onChanged,
          activeColor: const Color(0xFF2275AA), // Set active color to blue
          inactiveColor:
              const Color(0xFFB0C4DE), // Set inactive color to light blue
        ),
      ],
    );
  }
}
