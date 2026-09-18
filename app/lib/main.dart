import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/itinerary_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/place_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TravelManagerApp());
}

class TravelManagerApp extends StatelessWidget {
  const TravelManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
      ],
      child: MaterialApp(
        title: '여행 올인원 매니저',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
