import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_ride/infoHandler/app_info.dart';
import 'package:user_ride/screens/login_screen.dart';
import 'package:user_ride/screens/main_screen.dart';
import 'package:user_ride/screens/rate_driver_screen.dart';
import 'package:user_ride/screens/register_screen.dart';
import 'package:user_ride/screens/search_places_screen.dart';
import 'package:user_ride/splashScreen/splash_screen.dart';
import 'package:user_ride/themeProvider/theme_provider.dart';

Future<void> main() async{
  runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child:  MaterialApp(
        title: 'User Ride',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
  }
}




