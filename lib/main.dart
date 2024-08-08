import 'package:flutter/material.dart';
import 'home_body.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  runApp(const NavigationBarApp());
}
class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromARGB(255, 0, 0, 0),
          secondary: const Color.fromARGB(255, 255, 255, 255),
          surface: const Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Workout Logger'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color.fromARGB(255, 179, 177, 177),  // Border color
              width: 0.5,  // Border width
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
              (Set<MaterialState> states) => states.contains(MaterialState.selected)
                  ? const TextStyle(color: Colors.white54)
                  : const TextStyle(color: Colors.white54),
            ),
          ),
          child: NavigationBar(
            indicatorColor: const Color.fromARGB(255, 255, 255, 255),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            backgroundColor: Theme.of(context).colorScheme.primary,
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.history, color: Colors.white),
                selectedIcon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                label: 'History',
              ),
              NavigationDestination(
                icon: const Icon(Icons.fitness_center, color: Colors.white),
                selectedIcon: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                label: 'Workout',
              ),
              NavigationDestination(
                icon: const Icon(Icons.list, color: Colors.white),
                selectedIcon: Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                label: 'Exercises',
              ),
            ],
          ),
        ),
      ),
      body: HomeBody(currentPageIndex: currentPageIndex),
    );
  }
}
