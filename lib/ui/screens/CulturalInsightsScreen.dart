import 'package:flutter/material.dart';

class CulturalInsightsScreen extends StatefulWidget {
  const CulturalInsightsScreen({super.key});

  @override
  State<CulturalInsightsScreen> createState() => _CulturalInsightsScreenState();
}

class _CulturalInsightsScreenState extends State<CulturalInsightsScreen> {
  String _selectedNationality = 'Select Nationality';
  String _selectedPurpose = 'Select Purpose of Visit';

  // Expanded list of nationalities
  final List<String> _nationalities = [
    'Select Nationality',
    'Afghanistan', 'Algeria', 'Argentina', 'Australia', 'Bangladesh',
    'Brazil', 'Canada', 'China', 'Egypt', 'France', 'Germany',
    'India', 'Indonesia', 'Iran', 'Iraq', 'Italy', 'Japan',
    'Jordan', 'Kuwait', 'Lebanon', 'Malaysia', 'Mexico',
    'Morocco', 'Nigeria', 'Oman', 'Pakistan', 'Philippines',
    'Qatar', 'Russia', 'Singapore', 'South Africa', 'South Korea',
    'Spain', 'Sweden', 'Switzerland', 'Thailand', 'Turkey',
    'United Arab Emirates', 'United Kingdom', 'United States', 'Yemen',
    'Other'
  ];

  final List<String> _purposes = [
    'Select Purpose of Visit',
    'Tourism',
    'Business',
    'Religious (Hajj/Umrah)',
    'Family Visit',
    'Education',
    'Medical Treatment',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF1F4E5F); // Deep teal
    final accentColor = Color(0xFFE8B04B);  // Golden accent
    final backgroundColor = Color(0xFFF7F9FB); // Light off-white background
    final cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFFB94A2F),
        elevation: 0,
        title: const Text(
          'Cultural Insights & Compliance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Cultural Insights'),
                  content: Text('This feature provides cultural guidance, safety information, and personalized travel tips for visitors to Saudi Arabia.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.05), backgroundColor],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: accentColor.withOpacity(0.2),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.travel_explore,
                            size: 100,
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  primaryColor.withOpacity(0.0),
                                ],
                              ),
                            ),
                            child: Text(
                              'Welcome to Saudi Arabia',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // FR19: Custom travel tips based on nationality and purpose of visit
                _buildCustomTravelTipsSection(accentColor, cardColor, primaryColor),
                const SizedBox(height: 24),

                // FR17: Real-time cultural and legal guidelines
                _buildCulturalGuidelinesSection(accentColor, cardColor, primaryColor),
                const SizedBox(height: 24),

                // FR18: Safety alerts, emergency contacts, and local regulations
                _buildSafetyAndRegulationsSection(accentColor, cardColor, primaryColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCulturalGuidelinesSection(Color accentColor, Color cardColor, Color primaryColor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Cultural & Legal Guidelines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Divider(color: accentColor.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 10),
            _buildGuidelineItem(
              'Dress Code',
              'Dress modestly in public. Women should wear an abaya, and men should avoid shorts. During Ramadan, ensure clothing is even more conservative.',
              Icons.checkroom,
              primaryColor,
            ),
            _buildGuidelineItem(
              'Public Behavior',
              'Public displays of affection are prohibited. Respect prayer times—shops may close during Salah.',
              Icons.people,
              primaryColor,
            ),
            _buildGuidelineItem(
              'Photography',
              'Do not photograph government buildings, military sites, or locals (especially women) without permission.',
              Icons.camera_alt,
              primaryColor,
            ),
            _buildGuidelineItem(
              'Alcohol & Drugs',
              'Alcohol and drugs are strictly prohibited. Penalties for possession are severe, including imprisonment.',
              Icons.no_drinks,
              primaryColor,
            ),
            _buildGuidelineItem(
              'Ramadan Etiquette',
              'During Ramadan, eating, drinking, or smoking in public during fasting hours is not allowed.',
              Icons.calendar_month,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyAndRegulationsSection(Color accentColor, Color cardColor, Color primaryColor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Safety Alerts & Local Regulations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Divider(color: accentColor.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 10),
            _buildSafetyItem(
              'Emergency Contacts',
              'Police: 999\nAmbulance: 997\nFire: 998\nTourist Helpline: 930',
              Icons.emergency,
              primaryColor,
            ),
            _buildSafetyItem(
              'Safety Alert',
              'Heat Advisory: Temperatures can exceed 45°C in summer. Stay hydrated and avoid outdoor activities during peak heat.',
              Icons.warning_amber,
              Colors.red,
              isAlert: true,
            ),
            _buildSafetyItem(
              'Local Regulations',
              'Follow traffic rules strictly. Women can drive, but ensure you have a valid license. Respect religious sites—non-Muslims are not allowed in Mecca and Madinas holy areas.',
              Icons.gavel,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTravelTipsSection(Color accentColor, Color cardColor, Color primaryColor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Custom Travel Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Divider(color: accentColor.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 16),
            Text(
              'Personalize your experience by selecting your nationality and purpose of visit.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedNationality,
              decoration: InputDecoration(
                labelText: 'Nationality',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor),
                ),
                prefixIcon: Icon(Icons.flag, color: primaryColor),
              ),
              items: _nationalities.map((nationality) {
                return DropdownMenuItem<String>(
                  value: nationality,
                  child: Text(nationality),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNationality = value!;
                });
              },
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              dropdownColor: cardColor,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPurpose,
              decoration: InputDecoration(
                labelText: 'Purpose of Visit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor),
                ),
                prefixIcon: Icon(Icons.travel_explore, color: primaryColor),
              ),
              items: _purposes.map((purpose) {
                return DropdownMenuItem<String>(
                  value: purpose,
                  child: Text(purpose),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPurpose = value!;
                });
              },
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              dropdownColor: cardColor,
            ),
            const SizedBox(height: 20),
            if (_selectedNationality != 'Select Nationality' &&
                _selectedPurpose != 'Select Purpose of Visit')
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 500),
                child: _buildTravelTips(primaryColor, accentColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description, IconData icon, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyItem(String title, String description, IconData icon, Color iconColor, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAlert ? Colors.red.withOpacity(0.1) : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isAlert ? Colors.red : iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? Colors.red : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTips(Color primaryColor, Color accentColor) {
    String tips = '';
    IconData tipIcon = Icons.info;

    if (_selectedPurpose == 'Religious (Hajj/Umrah)') {
      tips = 'Ensure you have a valid Hajj/Umrah visa. Follow Ihram rules and respect the sanctity of the holy sites. Book accommodations in advance, as Mecca and Medina get crowded.';
      tipIcon = Icons.mosque;
    } else if (_selectedPurpose == 'Tourism') {
      tips = 'Visit historical sites like Al Rajhi Grand Mosque, Diriyah, and the Red Sea coast. Dress modestly and respect local customs. Try traditional Saudi dishes like Kabsa.';
      tipIcon = Icons.camera_alt;
    } else if (_selectedPurpose == 'Business') {
      tips = 'Business meetings may start with coffee and dates—accept them as a sign of hospitality. Punctuality is important, but meetings may start late. Dress in formal attire.';
      tipIcon = Icons.business;
    } else if (_selectedPurpose == 'Family Visit') {
      tips = 'Bring small gifts for your hosts as a gesture of appreciation. Respect family traditions and privacy. Be prepared for large family gatherings and meals.';
      tipIcon = Icons.family_restroom;
    } else if (_selectedPurpose == 'Education') {
      tips = 'University campuses may have specific rules for foreign students. Prepare for gender-segregated classes in some institutions. Verify your education visa requirements with your institution.';
      tipIcon = Icons.school;
    } else if (_selectedPurpose == 'Medical Treatment') {
      tips = 'Ensure all medical documentation is translated to Arabic. Check healthcare facilities that accept your insurance. Bring a companion if possible for assistance with language and logistics.';
      tipIcon = Icons.medical_services;
    } else {
      tips = 'Respect local customs and traditions. Learn a few Arabic phrases to communicate with locals. Always carry your passport or Iqama for identification.';
      tipIcon = Icons.info;
    }

    // Add nationality-specific tips
    if (['Pakistan', 'India', 'Bangladesh'].contains(_selectedNationality)) {
      tips += '\n\nNote for South Asians: You may find cultural similarities, but avoid discussing politics or sectarian issues. Halal food is widely available. Urdu/Hindi speakers may find some Arabic words familiar.';
    } else if (['United States', 'United Kingdom', 'Canada', 'Australia', 'France', 'Germany', 'Italy', 'Spain', 'Sweden', 'Switzerland'].contains(_selectedNationality)) {
      tips += '\n\nNote for Western Visitors: Public behavior is more conservative than in Western countries. Avoid wearing revealing clothing and be mindful of gender segregation in some public spaces. Credit cards are widely accepted in urban areas.';
    } else if (['Egypt', 'Jordan', 'Lebanon', 'Morocco', 'Algeria'].contains(_selectedNationality)) {
      tips += '\n\nNote for Arab Visitors: While culturally similar, be aware of different interpretations of Islamic practices. Saudi dialect may differ from your native Arabic dialect. Respect the local customs which may be more conservative.';
    } else if (['Japan', 'China', 'South Korea', 'Singapore', 'Thailand', 'Malaysia', 'Indonesia', 'Philippines'].contains(_selectedNationality)) {
      tips += '\n\nNote for Asian Visitors: Some Western-style greetings like handshakes are acceptable, but avoid physical contact with the opposite gender. Language barriers may exist, so consider using translation apps. Many restaurants offer Asian cuisine in major cities.';
    } else if (['Nigeria', 'South Africa'].contains(_selectedNationality)) {
      tips += '\n\nNote for African Visitors: You will find communities from your region in major cities. Cultural norms about time may differ. Carry appropriate identification at all times as random checks are common.';
    } else if (['Iran', 'Iraq', 'Afghanistan', 'Yemen'].contains(_selectedNationality)) {
    tips += '\n\nNote for Regional Visitors: Be mindful of geopolitical sensitivities. Avoid political discussions in public. Extra security screening may apply, so allow additional time for travel procedures.';
    }

    return Container(
    decoration: BoxDecoration(
    color: primaryColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: accentColor.withOpacity(0.3)),
    ),
    padding: EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(tipIcon, color: primaryColor),
    const SizedBox(width: 8),
    Text(
    'Travel Tips for You:',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    ),
    ),
    ],
    ),
    const SizedBox(height: 12),
    Text(
    tips,
    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
    ),
    ],
    ),
    );
  }
}