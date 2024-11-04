import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

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
                  color: Colors.black),
            ),
            Text(
              'Introduction\nMellow ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application, Mellow. By using Mellow, you agree to the practices described in this policy.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '1. Information We Collect',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Personal Information: When you sign up, we may collect information such as your email address and profile details to create and manage your account.\n\n'
              'Profile Images: If you choose to upload a profile image, it is stored securely in Firebase Storage and viewable only by you.\n\n'
              'Usage Information: We collect information on how you interact with Mellow, including task creation, management, and other app features.\n\n'
              'Device Information: We may automatically collect information about your device, such as your device type, operating system, and unique device identifiers, to help improve our app\'s performance.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'We use the information we collect to:\n\n'
              '- Provide and improve the app’s functionalities, including task management and profile customization.\n'
              '- Respond to user inquiries, support requests, or technical issues.\n'
              '- Protect our app and users from misuse or unauthorized access.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '3. Information Sharing and Disclosure',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Mellow does not sell, trade, or otherwise transfer your personal information to outside parties. Your information is only shared:\n\n'
              '- With Service Providers: We may share your information with third-party providers, such as Firebase, for essential functionalities (authentication, data storage). These providers are required to follow our data protection standards.\n\n'
              '- Legal Compliance and Protection: We may disclose your information if required by law or to protect our rights, enforce our terms, or comply with law enforcement requests.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '4. Security of Your Information',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'We implement reasonable security measures to protect your personal information. However, no system is entirely secure, and we cannot guarantee complete security. You are responsible for maintaining the confidentiality of your account credentials.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '5. Data Retention and Deletion',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Data Retention: We retain your information only as long as it is necessary for the purposes outlined in this policy. Once your data is no longer needed, it will be securely deleted or anonymized.\n\n'
              'Data Deletion: You have the right to request the deletion of your personal information at any time. To request data deletion, please contact us at aramos.k11940859@umak.edu.ph.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '6. Your Rights and Choices',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'You have the right to:\n\n'
              '- Access and Update: Access, correct, or update your personal information by contacting our support team.\n\n'
              '- Opt-Out: Opt-out of data collection by discontinuing use of the app.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              '7. Changes to This Privacy Policy',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'We may update this Privacy Policy periodically. When we do, we will revise the "Effective Date" at the top. Continued use of Mellow after changes signifies your acceptance of the updated policy.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Contact Us\n'
              'If you have any questions regarding this Privacy Policy, please contact us at aramos.k11940859@umak.edu.ph.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
