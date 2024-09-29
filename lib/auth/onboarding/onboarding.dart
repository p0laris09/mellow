import 'package:flutter/material.dart';


class OnboardingPage extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Column(
       children: <Widget>[
         // Top image placeholder
         Expanded(
           child: Container(
             color: Colors.grey[200], // Placeholder for the top image
           ),
         ),
         // Bottom section with title, description, and buttons
         Container(
           padding: EdgeInsets.all(20),
           color: Color(0xFF2C3C3C), // Dark background color for the bottom section
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: <Widget>[
               // Title Text
               Text(
                 "Mellow",
                 style: TextStyle(
                   fontSize: 36,
                   fontWeight: FontWeight.bold,
                   color: Colors.white,
                 ),
               ),
               SizedBox(height: 10),
               // Subtitle Text
               Text(
                 "The new Task Manager App that will help students handle their tasks and manage their time better.",
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[300],
                 ),
               ),
               SizedBox(height: 30),
               // SIGN IN Button
               ElevatedButton(
                 onPressed: () {
                   Navigator.pushNamed(context, '/signin');
                 },
                 style: ElevatedButton.styleFrom(
                   foregroundColor: Color(0xFF2C3C3C),
                   backgroundColor: Colors.grey[200], // Text color
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(30), // Rounded edges
                   ),
                   padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                 ),
                 child: Text(
                   "SIGN IN",
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
               SizedBox(height: 20),
               // SIGN UP Button
               OutlinedButton(
                 onPressed: () {
                   Navigator.pushNamed(context, '/signup');
                 },
                 style: OutlinedButton.styleFrom(
                   side: BorderSide(color: Colors.white),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(30), // Rounded edges
                   ),
                   padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                 ),
                 child: Text(
                   "SIGN UP",
                   style: TextStyle(
                     fontSize: 16,
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }
}



