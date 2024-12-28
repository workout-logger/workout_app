import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http; // If you do real HTTP calls
import 'package:workout_logger/main.dart'; // or wherever your HomeScreen is

/// Data model to pass the user's choices across screens.
class ProfileData {
  String? username;
  String? bodyImage;
  String? eyeImage;
}

/// SCREEN 1: User enters their username
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({Key? key}) : super(key: key);

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();

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
                onPressed: () {
                  final data = ProfileData();
                  data.username = _usernameController.text.trim();

                  // Navigate to the body color screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BodyColorScreen(profileData: data),
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

/// SCREEN 2: User picks a body color.
/// Shows 1 large body preview + a row of 5 colored squares.
class BodyColorScreen extends StatefulWidget {
  final ProfileData profileData;
  const BodyColorScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<BodyColorScreen> createState() => _BodyColorScreenState();
}

class _BodyColorScreenState extends State<BodyColorScreen> {
  // Five color swatches (the boxes the user taps)
  final List<Color> _colorSwatches = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
  ];

  // Five corresponding body image paths
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
                'Select a Body Color:',
                style: TextStyle(color: Colors.yellow, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // 1) Large preview
              Expanded(
                child: Center(
                  child: Image.asset(selectedBodyImage, width: 200),
                ),
              ),
              const SizedBox(height: 16),

              // 2) A row of color squares to pick from
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
                  // Store the chosen image path in ProfileData
                  widget.profileData.bodyImage = selectedBodyImage;

                  // Navigate to EyeColorScreen
                  Navigator.push(
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

  int _selectedEyeIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // 1) Create the controller.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // how long the zoom lasts
    );

    // 2) Define the scaling from 1.0 to 1.2
    _zoomAnimation = Tween<double>(begin: 1.0, end: 5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, 
      ),
    );

    // 3) Start the animation as soon as the screen appears.
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The body image chosen in the previous screen
    final String? chosenBodyImage = widget.profileData.bodyImage;
    // The currently selected eye image
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

              // 4) Use ScaleTransition with an alignment that keeps the face near the top.
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _zoomAnimation,
                    // This alignment shifts the "pivot" of the zoom upwards (negative Y).
                    // Adjust the value until the face is where you want it.
                    alignment: const Alignment(0, -0.8), 
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

              // Thumbnails for choosing eye color
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _eyeColorOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  final isSelected = index == _selectedEyeIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEyeIndex = index;
                        // Optional: Reset & replay the zoom each time a color is selected:
                        // _animationController.reset();
                        // _animationController.forward();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.yellow : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(path, width: 50, height: 50),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  // Save the chosen eye image
                  widget.profileData.eyeImage = selectedEyeImage;

                  // Navigate to the final preview or next step
                  // ...
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

/// SCREEN 4: Shows final preview (username + stacked images) and "Complete Profile" button.
class ProfilePreviewScreen extends StatefulWidget {
  final ProfileData profileData;
  const ProfilePreviewScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  bool _isSubmitting = false;
  final String _completeProfileUrl = ''; // put your real endpoint here

  // If doing real HTTP:
  // final http.Client httpClient = http.Client();

  Future<void> _submitProfile() async {
    setState(() => _isSubmitting = true);
    try {
      // In a real app, get your auth token from SharedPreferences, then do a POST:
      // final prefs = await SharedPreferences.getInstance();
      // final authToken = prefs.getString('authToken') ?? '';

      final username = widget.profileData.username ?? 'NoName';
      final bodyImg = widget.profileData.bodyImage ?? '';
      final eyeImg = widget.profileData.eyeImage ?? '';

      /*
      final response = await httpClient.post(
        Uri.parse(_completeProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'username': username,
          'body_image': bodyImg,
          'eye_image': eyeImg,
        }),
      );

      if (response.statusCode == 200) {
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
      */

      // For demo, just pretend success:
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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
    final username = widget.profileData.username ?? 'No username';
    final body = widget.profileData.bodyImage;
    final eyes = widget.profileData.eyeImage;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile Preview', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.yellow),
      ),
      body: SafeArea(
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Stacked images
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (body != null && body.isNotEmpty)
                              Image.asset(body, width: 200),
                            if (eyes != null && eyes.isNotEmpty)
                              Image.asset(eyes, width: 200),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Username: $username',
                      style: const TextStyle(color: Colors.yellow, fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _submitProfile,
                      child: const Text('Complete Profile'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
