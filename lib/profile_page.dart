import 'package:flutter/material.dart';
import 'fitness_app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      appBar: AppBar(
        title: const Text('Profile',style: TextStyle(color: FitnessAppTheme.darkText)),
        backgroundColor: FitnessAppTheme.background,
      ),
      body: Column(
        children: [
          _buildProfileHeader(context),
          Expanded(
            child: ListView(
              children: [
                _buildProfileOption(
                  context,
                  icon: Icons.group,
                  title: 'Friends',
                  onTap: () {
                    // Handle Friends tap
                  },
                ),
                _buildProfileOption(
                  context,
                  icon: Icons.file_download,
                  title: 'Import Data',
                  onTap: () {
                    // Handle Import Data tap
                  },
                ),
                _buildProfileOption(
                  context,
                  icon: Icons.file_upload,
                  title: 'Export Data',
                  onTap: () {
                    // Handle Export Data tap
                  },
                ),
                _buildProfileOption(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    // Handle Notifications tap
                  },
                ),
                _buildProfileOption(
                  context,
                  icon: Icons.group_work,
                  title: 'Groups',
                  onTap: () {
                    // Handle Groups tap
                  },
                ),
                _buildProfileOption(
                  context,
                  icon: Icons.leaderboard,
                  title: 'Leaderboard',
                  onTap: () {
                    // Handle Leaderboard tap
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [

          SizedBox(height: 12),
          Text(
            'Jonathan Baghirov', // Replace with actual user name
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FitnessAppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: FitnessAppTheme.darkText),
      title: Text(
        title,
        style: const TextStyle(color: FitnessAppTheme.darkText),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: FitnessAppTheme.darkText),
      onTap: onTap,
    );
  }
}
