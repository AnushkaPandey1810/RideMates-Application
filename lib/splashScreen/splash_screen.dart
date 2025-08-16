import 'dart:async';

import 'package:flutter/material.dart';
import 'package:user_app/Assistants/assistant_methods.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/screens/login_screen.dart';
import 'package:user_app/screens/main_screen.dart';

import '../screens/register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  startTimer(){
    Timer(Duration(seconds: 3),() async{
      if(await firebaseAuth.currentUser != null){
        firebaseAuth.currentUser != null ? AssistantMethods.readCurrentOnLineUserInfo() :null;
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }
      else{
        Navigator.push(context, MaterialPageRoute(builder: (c) => RegisterScreen()));
      }
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startTimer();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'RideMates',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
