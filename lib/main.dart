import 'package:flutter/material.dart';

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Logger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color.fromARGB(255, 33, 34, 45),
          secondary: const Color.fromARGB(255, 57, 57, 62),
          surface: Color.fromARGB(255, 23, 24, 33),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Workout Logger Home Page'),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? const TextStyle(color: Colors.white54)
                : const TextStyle(color: Colors.white54),
          ),
        ),
        child: NavigationBar(
          indicatorColor:Color.fromARGB(255, 44, 46, 70),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)
          ),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: Theme.of(context).colorScheme.primary,
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.history, color: Colors.white),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center, color: Colors.white),
              label: 'Workout',
            ),
            NavigationDestination(
              icon: Icon(Icons.list, color: Colors.white),
              label: 'Exercises',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment, color: Colors.white),
              label: 'Benchmark',
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current page index: $currentPageIndex',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
