import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/models/MessageModel/message.dart';

class ChatScreen extends StatefulWidget {
  final String userId; // Selected friend's user ID

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  late String chatId;

  @override
  void initState() {
    super.initState();
    _generateChatId();
  }

  // Generate a unique chat ID for the conversation
  void _generateChatId() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, widget.userId];
    ids.sort(); // Ensures a consistent chat ID order
    chatId = ids.join("_");
  }

  // Send Message
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final Timestamp timestamp = Timestamp.now();

    // Create a new message object
    Message newMessage = Message(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? "Unknown",
      receiverId: widget.userId,
      timestamp: timestamp,
      message: message,
    );

    // Add message to Firestore
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());

      _controller.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Retrieve messages in real-time
  Stream<QuerySnapshot> getMessages() {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    bool isMe = message['senderId'] == _auth.currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueGrey.shade300
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['message'], // Ensure correct field name
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blueGrey.shade700,
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
