import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        centerTitle: true,
        title: const Text(
          'Privacy Policy',
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
              'Privacy Policy for Mellow\nEffective Date: October 27, 2024\n\n',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Divider(color: Colors.black),
            SizedBox(height: 8),
            Text(
              'Introduction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Mellow ("we," "our," or "us") values your privacy and is dedicated to maintaining the confidentiality and security of your personal information. This Privacy Policy outlines how we collect, use, disclose, and protect your information when you use our mobile application, Mellow. By accessing or using Mellow, you consent to the data practices described in this policy.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '1. Information We Collect',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Personal Information: When you register an account, we collect personal details such as your name, email address, and any additional information you voluntarily provide to facilitate your account creation and service personalization.\n\n'
              'Profile Images: If you upload a profile image, it will be securely stored in Firebase Storage and accessible only to you unless you choose to share it with others.\n\n'
              'Usage Data: We gather data regarding your app interactions, including task creation, management, and usage frequency, to optimize our services and enhance user experience.\n\n'
              'Device Information: Automatically collected information such as device type, operating system, IP address, and unique device identifiers helps us diagnose issues and improve performance.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We use your information to:\n'
              '- Provide, operate, and improve app functionalities.\n'
              '- Personalize your app experience and deliver content relevant to your preferences.\n'
              '- Respond to inquiries, troubleshoot technical issues, and offer customer support.\n'
              '- Ensure the security, integrity, and proper functioning of our app.\n'
              '- Analyze usage trends and app performance to refine user experience.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '3. Information Sharing and Disclosure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We do not sell, rent, or trade your personal information. However, your information may be disclosed in the following circumstances:\n'
              '- Service Providers: We may share your data with third-party providers such as Firebase to facilitate authentication, data storage, and performance optimization. These providers are contractually bound to maintain confidentiality and data protection standards.\n'
              '- Legal Compliance: We may disclose your information to comply with legal obligations, enforce our terms, or protect the rights, safety, and property of our users or others.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '4. Security of Your Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We implement robust security measures, including encryption, secure servers, and access controls, to protect your personal information. Despite these measures, no system is entirely secure. You are responsible for safeguarding your account credentials and notifying us of any unauthorized access.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '5. Data Retention and Deletion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Retention: Your data is retained only as long as necessary to fulfill the purposes outlined in this policy or comply with legal requirements. Once no longer needed, your information will be securely deleted or anonymized.\n\n'
              'Deletion: You may request the deletion of your personal data at any time by contacting us at mellow.taskmanager@gmail.com. Upon verification, we will delete your information in accordance with applicable laws.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '6. Your Rights and Choices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'You have the right to:\n'
              '- Access and Update: Access and update your personal information through your account settings or by contacting us.\n'
              '- Data Portability: Request a copy of your personal data in a machine-readable format.\n'
              '- Withdraw Consent: Withdraw your consent to data processing at any time, subject to legal obligations.\n'
              '- Opt-Out: Discontinue app usage to cease further data collection.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '7. Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We reserve the right to update this Privacy Policy at our discretion. Any changes will be posted with the updated effective date. Continued use of Mellow constitutes your acceptance of the revised terms.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'For questions, concerns, or data-related requests, please contact us at mellow.taskmanager@gmail.com.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
