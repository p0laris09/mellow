import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Terms of Service for Mellow'),
            _sectionText('Effective Date: October 27, 2024'),
            const Divider(color: Colors.black54, thickness: 1),
            const SizedBox(height: 16),
            _buildSection('1. Acceptance of Terms',
                'By accessing, downloading, installing, or using Mellow (the "App"), you acknowledge that you have read, understood, and agree to be legally bound by these Terms of Service ("Terms"). If you do not accept these Terms, you are prohibited from accessing or using the App.'),
            _buildSection('2. Use of the App',
                'Mellow is a task management tool designed to assist users in managing tasks, goals, and profiles. Your use of the App must comply with all applicable laws and these Terms.'),
            _buildSection('3. User Responsibilities',
                'By using Mellow, you agree to provide accurate registration information, maintain the confidentiality of your account credentials, and notify us of unauthorized access.'),
            _buildSection('4. Intellectual Property',
                'All intellectual property rights, including trademarks and software, are the sole property of Mellow or its licensors. Unauthorized use is prohibited.'),
            _buildSection('5. Limitation of Liability',
                'Mellow is provided on an "as-is" basis without warranties of any kind. We disclaim liability for any damages arising from your use of the App.'),
            _buildSection('6. Privacy Policy',
                'Your use of Mellow is governed by our Privacy Policy. By using the App, you consent to our data practices.'),
            _buildSection('7. Modifications to the Terms',
                'Mellow reserves the right to update these Terms at any time. Continued use of the App after modifications constitutes acceptance.'),
            _buildSection('8. Termination',
                'Mellow may suspend or terminate your access to the App at any time without notice for breaches of these Terms.'),
            _buildSection('9. Governing Law',
                'These Terms shall be governed by the laws of the Philippines.'),
            _buildSection('10. Contact Us',
                'If you have any questions, contact us at mellow.taskmanager@gmail.com.'),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2275AA),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2275AA),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style:
              const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
        ),
      ],
    );
  }
}
