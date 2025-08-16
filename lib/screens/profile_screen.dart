import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../global/global.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();

  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");

  Future<void> showUpdateDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required String field,
    required String currentValue,
  }) async {
    controller.text = currentValue;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update $title"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Enter $title",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  Fluttertoast.showToast(msg: "$title cannot be empty.");
                  return;
                }

                try {
                  await userRef
                      .child(firebaseAuth.currentUser!.uid)
                      .update({field: controller.text.trim()});
                  Fluttertoast.showToast(
                      msg: "Updated Successfully. Reload the app to see the change.");
                } catch (error) {
                  Fluttertoast.showToast(msg: "Error Occurred: $error");
                }
                controller.clear();
                Navigator.pop(context);
              },
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
          title: const Text(
            "Profile Screen",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(50),
                  decoration: const BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 30),
                buildEditableRow(
                  context: context,
                  title: "Name",
                  value: userModelCurrentInfo?.name ?? "Guest",
                  controller: nameTextEditingController,
                  field: "name",
                ),
                const Divider(thickness: 1),
                buildEditableRow(
                  context: context,
                  title: "Phone",
                  value: userModelCurrentInfo?.phone ?? "Phone",
                  controller: phoneTextEditingController,
                  field: "phone",
                ),
                const Divider(thickness: 1),
                buildEditableRow(
                  context: context,
                  title: "Address",
                  value: userModelCurrentInfo?.address ?? "Address",
                  controller: addressTextEditingController,
                  field: "address",
                ),
                const Divider(thickness: 1),
                Text(
                  userModelCurrentInfo?.email ?? "GuestMail",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEditableRow({
    required BuildContext context,
    required String title,
    required String value,
    required TextEditingController controller,
    required String field,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            showUpdateDialog(
              context: context,
              title: title,
              controller: controller,
              field: field,
              currentValue: value,
            );
          },
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }
}