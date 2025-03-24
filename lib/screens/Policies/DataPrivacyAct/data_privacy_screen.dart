import 'package:flutter/material.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

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
          'Data Privacy',
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
              'The Data Privacy Act of 2012 (Republic Act No. 10173) is a Philippine law that safeguards individuals\' personal information in both government and private sectors. It establishes guidelines for the collection, processing, and storage of personal data to protect privacy rights.\n\n',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Divider(color: Colors.black),
            SizedBox(height: 8),
            Text(
              'Scope and Application',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'The Act applies to all entities involved in processing personal data, whether in the Philippines or abroad, if they handle information about Philippine citizens or residents. This includes entities that:\n\n'
              '- Have a presence in the Philippines.\n'
              '- Process personal data within the Philippines.\n'
              '- Engage in business in the Philippines.\n'
              '- Collect or hold personal data from individuals in the Philippines.\n\n'
              'However, certain situations are exempt, such as information about government employees related to their official duties, personal data processed for journalistic purposes, and data necessary for public authorities to carry out their functions.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Key Principles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Entities must adhere to the following principles when processing personal data:\n\n'
              '- Transparency: Inform data subjects about how their data will be collected, used, and stored.\n'
              '- Legitimate Purpose: Collect data for specific, legitimate purposes relevant to the organization\'s function.\n'
              '- Proportionality: Ensure data collection is adequate and not excessive in relation to its purpose.\n\n'
              'These principles are outlined in the Implementing Rules and Regulations of the Act.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Rights of Data Subjects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Individuals have the following rights under the Act:\n\n'
              '- Right to Be Informed: About the collection and processing of their personal data.\n'
              '- Right to Access: Their personal data held by an entity.\n'
              '- Right to Rectification: Correct inaccuracies in their data.\n'
              '- Right to Erasure or Blocking: Request deletion or blocking of data under certain conditions.\n'
              '- Right to Object: To processing of their data, including for direct marketing.\n'
              '- Right to Data Portability: Obtain a copy of their data in an electronic format.\n\n'
              'These rights empower individuals to control their personal information.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Obligations of Organizations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Organizations must:\n\n'
              '- Obtain Consent: Secure explicit consent from individuals before collecting or processing their data.\n'
              '- Implement Security Measures: Establish organizational, physical, and technical safeguards to protect data.\n'
              '- Notify of Breaches: Inform the National Privacy Commission and affected individuals of data breaches promptly.\n'
              '- Register Data Processing Systems: Register systems with the National Privacy Commission, especially if processing sensitive personal information.\n\n'
              'Compliance with these obligations ensures lawful and secure data processing.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Penalties for Non-Compliance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Violations of the Act can result in:\n\n'
              '- Fines: Monetary penalties for breaches.\n'
              '- Imprisonment: For serious offenses, individuals responsible may face imprisonment.\n'
              '- Civil Liabilities: Organizations may be required to compensate affected individuals.\n\n'
              'Penalties vary depending on the nature and severity of the violation.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'Application in Practice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'For practical application, organizations should:\n\n'
              '- Appoint a Data Protection Officer (DPO): To oversee compliance and data protection strategies.\n'
              '- Conduct Regular Training: Educate employees on data privacy principles and practices.\n'
              '- Perform Data Protection Impact Assessments: Identify and mitigate risks associated with data processing activities.\n'
              '- Develop Privacy Policies: Create clear policies outlining data handling procedures and ensure they are accessible to data subjects.\n\n'
              'Implementing these measures fosters trust and ensures adherence to the Data Privacy Act of 2012.\n\n',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
