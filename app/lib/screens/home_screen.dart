import 'package:flutter/material.dart';
import 'itinerary_screen.dart';
import 'receipt_screen.dart';
import 'place_screen.dart';
import 'route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [ItineraryScreen(), ReceiptScreen(), PlaceScreen(), RouteScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('여행 올인원 매니저')),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '일정표'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '가계부'),
          NavigationDestination(icon: Icon(Icons.map), label: '추천'),
          NavigationDestination(icon: Icon(Icons.alt_route), label: '경로'),
        ],
      ),
    );
  }
}
