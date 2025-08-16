import 'package:driver_app/screens/main_screen.dart';
import 'package:driver_app/splashScreen/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../global/global.dart';
import 'login_screen.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({super.key});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {

  final carModelTextEditingController = TextEditingController();
  final carNumberTextEditingController = TextEditingController();
  final carColorTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> carTypes = ["Car","CNG","Bike"];
  String? selectedCarType;
  _submit() async
  {
    if(_formKey.currentState!.validate()){
      Map driverCarInfoMap = {
        "car_model": carModelTextEditingController.text.trim(),
        "car_number": carNumberTextEditingController.text.trim(),
        "car_color": carColorTextEditingController.text.trim(),
      };
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("drivers");
      userRef.child(currentUser!.uid).set(driverCarInfoMap);

      await Fluttertoast.showToast(msg: "Successfully Registered");
      Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
    }
  }
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset(darkTheme ? 'images/city_dark.png' : 'images/city.png'),

                SizedBox(height: 20,),

                Text(
                    "Add Car Details",
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15,20,15,50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50)
                      ],
                      decoration: InputDecoration(
                        hintText: "Car Model",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        prefixIcon: Icon(Icons.person,color: darkTheme ? Colors.amber.shade400:Colors.grey,),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (text){
                        if(text == null || text.isEmpty){
                          return 'Name can\'t be empty';
                        }
                        if(text.length<2){
                          return'Please enter a valid name';
                        }
                        if(text.length>50){
                          return'Name can\'t be more than 50';
                        }
                      },
                      onChanged: (text) => setState(() {
                        carModelTextEditingController.text = text;
                      }),
                    ),

                    SizedBox(height: 10,),

                    TextFormField(
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50)
                      ],
                      decoration: InputDecoration(
                        hintText: "Car Number",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        prefixIcon: Icon(Icons.person,color: darkTheme ? Colors.amber.shade400:Colors.grey,),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (text){
                        if(text == null || text.isEmpty){
                          return 'Name can\'t be empty';
                        }
                        if(text.length<2){
                          return'Please enter a valid name';
                        }
                        if(text.length>50){
                          return'Name can\'t be more than 50';
                        }
                      },
                      onChanged: (text) => setState(() {
                        carNumberTextEditingController.text = text;
                      }),
                    ),

                    SizedBox(height: 10,),

                    TextFormField(
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50)
                      ],
                      decoration: InputDecoration(
                        hintText: "Car Color",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        prefixIcon: Icon(Icons.person,color: darkTheme ? Colors.amber.shade400:Colors.grey,),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (text){
                        if(text == null || text.isEmpty){
                          return 'Name can\'t be empty';
                        }
                        if(text.length<2){
                          return'Please enter a valid name';
                        }
                        if(text.length>50){
                          return'Name can\'t be more than 50';
                        }
                      },
                      onChanged: (text) => setState(() {
                        carColorTextEditingController.text = text;
                      }),
                    ),

                    SizedBox(height: 20,),

                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        hintText: "Please Choose Car Type",
                        prefixIcon: Icon(Icons.car_crash, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                        filled: true,
                        fillColor: darkTheme ? Colors.black54 : Colors.grey.shade400,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          )
                        )
                      ),
                        items: carTypes.map((car){
                          return DropdownMenuItem(
                              child: Text(
                                car,
                                style: TextStyle(

                                  color: Colors.grey
                                ),
                              ),
                            value: car,
                          );
                        }).toList(),
                        onChanged: (newValue) {
                        setState(() {
                          selectedCarType = newValue.toString();
                        });
                        }
                    ),

                    SizedBox(height: 20,),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: darkTheme ? Colors.black : Colors.white, backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        minimumSize: Size(double.infinity,50),
                      ),
                      onPressed:(){
                       _submit();
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 20
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),

                    GestureDetector(
                      onTap: (){},
                      child: Text(
                        'Forgot Pasword',
                        style: TextStyle(
                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Have an Account?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 5,),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                          },
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 15,
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
