import 'package:firebase_database/firebase_database.dart';

class UserModel{
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  UserModel({
   this.name,
   this.phone,
   this.email,
   this.id,
   this.address
});

  // UserModel.fromSnapshot(DataSnapshot snap){
  //   phone = (snap.value as dynamic)["phone"];
  //   name = (snap.value as dynamic)["name"];
  //   id = snap.key;
  //   email = (snap.value as dynamic)["email"];
  //   address = (snap.value as dynamic)["address"];
  // }
  UserModel.fromSnapshot(DataSnapshot snap) {
    if (snap.value != null) {
      var data = snap.value as Map<dynamic, dynamic>;
      phone = data["phone"];
      name = data["name"];
      id = snap.key;
      email = data["email"];
      address = data["address"];
    } else {
      throw Exception("Snapshot is empty or null.");
    }
  }
}