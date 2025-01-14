import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/main.dart';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/websocket_manager.dart';

/// Data model to pass the user's choices across screens.
class ProfileData {
  String? username;
  int? bodyColorIndex; // Store the index of the selected body color
  int? eyeColorIndex;  // Store the index of the selected eye color
}

/// SCREEN 1: User enters their username 
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({Key? key}) : super(key: key);

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isChecking = false;
  String? _errorMessage;

  Future<bool> _checkUsernameExists(String username) async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final String apiUrl = APIConstants.userExists;
      final response = await http.get(
        Uri.parse('$apiUrl$username'),
      );

      if (response.statusCode == 200) {
        final exists = jsonDecode(response.body)['exists'] as bool;
        if (exists) {
          setState(() {
            _errorMessage = 'Username already taken';
          });
        }
        return exists;
      } else {
        throw Exception('Failed to check username');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking username';
      });
      return false;
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Choose Username', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.yellow),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Enter a username:',
                style: TextStyle(color: Colors.yellow, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'e.g. DarkKnight92',
                  hintStyle: const TextStyle(color: Colors.grey),
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isChecking ? null : () async {
                  final username = _usernameController.text.trim();
                  if (username.isEmpty) {
                    setState(() {
                      _errorMessage = 'Please enter a username';
                    });
                    return;
                  }

                  final exists = await _checkUsernameExists(username);
                  if (!exists) {
                    final data = ProfileData();
                    data.username = username;

                    // Navigate to the body color screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BodyColorScreen(profileData: data),
                      ),
                    );
                  }
                },
                child: _isChecking 
                  ? const CircularProgressIndicator()
                  : const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SCREEN 2: User picks a body color.
/// Shows 1 large body preview + a row of 5 colored squares.
class BodyColorScreen extends StatefulWidget {
  final ProfileData profileData;
  const BodyColorScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<BodyColorScreen> createState() => _BodyColorScreenState();
}

class _BodyColorScreenState extends State<BodyColorScreen> {
  final List<Color> _colorSwatches = [
    const Color.fromARGB(255, 244, 226, 255),
    const Color.fromARGB(255, 232, 166, 136),
    const Color.fromARGB(255, 196, 150, 129),
    const Color.fromARGB(255, 126, 87, 75),
    const Color.fromARGB(255, 126, 87, 75),
  ];

  final List<String> _bodyColorImages = [
    'assets/character/base_body_1.png',
    'assets/character/base_body_2.png',
    'assets/character/base_body_3.png',
    'assets/character/base_body_4.png',
    'assets/character/base_body_5.png',
  ];

  int _selectedBodyIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedBodyImage = _bodyColorImages[_selectedBodyIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Choose Body Color', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.yellow),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Customize your character:',
                style: TextStyle(color: Colors.yellow, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Large preview
              Expanded(
                child: Center(
                  child: Image.asset(selectedBodyImage, width: 400),
                ),
              ),
              const SizedBox(height: 16),

              // Row of color squares
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_colorSwatches.length, (index) {
                  final isSelected = index == _selectedBodyIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBodyIndex = index);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _colorSwatches[index],
                        border: Border.all(
                          color: isSelected ? Colors.yellow : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Next button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  widget.profileData.bodyColorIndex = _selectedBodyIndex;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EyeColorScreen(profileData: widget.profileData),
                    ),
                  );
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SCREEN 3: User picks eye color (zoomed in on the face).
class EyeColorScreen extends StatefulWidget {
  final ProfileData profileData;
  const EyeColorScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EyeColorScreen> createState() => _EyeColorScreenState();
}

class _EyeColorScreenState extends State<EyeColorScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _eyeColorOptions = [
    'assets/character/eye_color_1.png',
    'assets/character/eye_color_2.png',
    'assets/character/eye_color_3.png',
    'assets/character/eye_color_4.png',
    'assets/character/eye_color_5.png',
  ];

  final List<Color> _eyeColorBackgrounds = [
    const Color.fromARGB(255, 136, 84, 20),
    const Color.fromARGB(255, 73, 46, 4),
    const Color.fromARGB(255, 75, 82, 66),
    const Color.fromARGB(255, 41, 60, 82),
    const Color.fromARGB(255, 145, 0, 2)
  ];

  int _selectedEyeIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;
  bool _isSubmitting = false;
  final String _completeProfileUrl = APIConstants.saveUserPreferences;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    setState(() => _isSubmitting = true);
    try {
      final username = widget.profileData.username ?? '';
      final bodyColorIndex = widget.profileData.bodyColorIndex ?? -1; 
      final eyeColorIndex = widget.profileData.eyeColorIndex ?? -1;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');
      await prefs.clear();
      await prefs.setString('username', username);
      await prefs.setString('authToken', authToken!);
      await prefs.setString('bodyColorIndex', bodyColorIndex.toString());
      await prefs.setString('eyeColorIndex', eyeColorIndex.toString());


      final response = await http.post(
        Uri.parse(_completeProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'username': username,
          'body_color_index': bodyColorIndex,
          'eye_color_index': eyeColorIndex,
        }),
      );

      if (response.statusCode == 200) {
        await WebSocketManager().connectWebSocket();
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile update failed: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing profile: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? bodyColorIndex = widget.profileData.bodyColorIndex;
    final String? chosenBodyImage =
        bodyColorIndex != null ? 'assets/character/base_body_${bodyColorIndex + 1}.png' : null;

    final String selectedEyeImage = _eyeColorOptions[_selectedEyeIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Choose Eye Color', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.yellow),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Select an Eye Color:',
                style: TextStyle(color: Colors.yellow, fontSize: 18),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _zoomAnimation,
                    alignment: const Alignment(0.1, -0.8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (chosenBodyImage != null && chosenBodyImage.isNotEmpty)
                          Image.asset(
                            chosenBodyImage,
                            width: 200,
                          ),
                        Image.asset(
                          selectedEyeImage,
                          width: 200,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                color: Colors.black.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _eyeColorOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    final isSelected = index == _selectedEyeIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEyeIndex = index;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: _eyeColorBackgrounds[index],
                          border: Border.all(
                            color: isSelected ? Colors.yellow : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(path, fit: BoxFit.contain),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        widget.profileData.eyeColorIndex = _selectedEyeIndex;
                        await _submitProfile();
                      },
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
