import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
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
        centerTitle: true,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service for Mellow\nEffective Date: October 27, 2024\n\n',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'By downloading or using Mellow, you agree to be bound by these Terms of Service ("Terms"). If you do not agree, you may not access or use the app.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '2. Use of the App',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Mellow provides task management and organizational tools to help you manage your tasks and profile. All features are provided free of charge, with no in-app purchases or hidden fees.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '3. User Responsibilities',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'You are responsible for:'
              '- Ensuring that your account information, including your email address and profile details, are accurate and up to date.\n'
              '- Safeguarding your account and passwords.\n'
              '- Complying with all applicable laws and these Terms when using Mellow.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '4. Intellectual Property',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'All content within Mellow is the property of Mellow or its licensors. You may not copy, reproduce, distribute, or create derivative works without our permission.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '5. Limitation of Liability',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Mellow is provided on an "as-is" basis. We are not liable for any damages or losses arising from your use of the app, including any data loss or service interruptions.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '6. Changes to the Terms',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'We may revise these Terms from time to time. Continued use of Mellow after updates constitutes acceptance of the new Terms.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Contact Us\n'
              'For any questions or support requests regarding these Terms, please contact us at aramos.k11940859@umak.edu.ph.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
