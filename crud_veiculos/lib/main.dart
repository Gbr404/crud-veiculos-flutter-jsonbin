import 'package:flutter/material.dart';
import 'screens/vehicle_list_screen.dart';
void main() {
runApp(const MyApp());
}
class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'CRUD Veículos com JSONBin',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
useMaterial3: true,
),
debugShowCheckedModeBanner: false,
home: const VehicleListScreen(),
);
}
}
