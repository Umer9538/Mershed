import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/theme_provider.dart'; // Import ThemeProvider
import 'package:mershed/config/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late bool _notificationsEnabled;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notificationsEnabled = true;
    _loadSettings();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadUserData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _loadUserData() async {
    if (_userId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
        });
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'name': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating name: $e')),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notificationsEnabled', value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB94A2F),
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Name',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _saveName,
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB94A2F)),
                        child: Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                child: SwitchListTile(
                  title: Text('Enable Notifications', style: theme.textTheme.titleMedium),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Color(0xFFB94A2F),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                child: SwitchListTile(
                  title: Text('Dark Mode', style: theme.textTheme.titleMedium),
                  value: themeProvider.isDarkMode, // Use ThemeProvider's value
                  onChanged: (value) {
                    themeProvider.toggleTheme(value); // Toggle via ThemeProvider
                  },
                  activeColor: Color(0xFFB94A2F),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    authProvider.isGuest ? 'Exit Guest Mode' : 'Sign Out',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmSignOut(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(authProvider.isGuest ? 'Exit Guest Mode' : 'Sign Out'),
        content: Text(authProvider.isGuest
            ? 'Are you sure you want to exit guest mode?'
            : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<MershadAuthProvider>().signOut();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
            child: Text(
              authProvider.isGuest ? 'Exit' : 'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}