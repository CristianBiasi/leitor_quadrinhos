import 'package:flutter/material.dart';

import 'library_screen.dart';
import 'collections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int index = 0;

  final pages = const [
    LibraryScreen(),
    CollectionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (v) {
          setState(() {
            index = v;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'Coleções',
          ),
        ],
      ),
    );
  }
}