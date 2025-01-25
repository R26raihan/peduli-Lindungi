import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Import provider
import './Auth/loginpage.dart';
import './Auth/registerpage.dart';
import './provider.dart';  // Import CacheProvider

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CacheProvider()),  // Daftarkan CacheProvider
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Eye',
      debugShowCheckedModeBanner: false, // Menghilangkan tulisan "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Menetapkan halaman pertama yang ditampilkan
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
