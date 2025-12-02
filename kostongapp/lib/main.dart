import 'package:flutter/material.dart';
import 'screens/add_edit_kost_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/pencari_home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/statistic_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kostong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/admin-home': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/owner-home': (context) => OwnerHomeScreen(),
        '/seeker-home': (context) => SeekerHomeScreen(),
        '/add_edit_kost': (context) => AddEditKostScreen(),
        '/statistics': (context) => StatisticsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/booking-detail': (context) => BookingDetailScreen(),
      },
    );
  }
}
