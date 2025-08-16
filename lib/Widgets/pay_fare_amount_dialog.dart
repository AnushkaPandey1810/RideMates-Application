import 'package:flutter/material.dart';
import 'package:user_app/Widgets/progress_dialog.dart';
import 'package:user_app/splashScreen/splash_screen.dart';

class PayFareAmountDialog extends StatefulWidget {
  final double? fareAmount;
  PayFareAmountDialog({this.fareAmount});

  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            SizedBox(height: 50),

            Text(
              "Fare Amount".toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.white,
              ),
            ),
            SizedBox(height: 20),

            Divider(
              thickness: 2,
              color: darkTheme ? Colors.amber.shade400 : Colors.white,
            ),
            SizedBox(height: 10),

            Text(
              "Ride Finished",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.white,
                fontSize: 50,
              ),
            ),
            SizedBox(height: 10),

            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "The trip fare amount. Please pay it to the driver",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(height: 10),

            Padding(
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
                ),
                onPressed: () async {
                  // Show progress dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ProgressDialog(message: "Please wait. Ride is completed...");
                    },
                  );

                  // Simulate a delay for loading
                  await Future.delayed(Duration(seconds: 3));

                  // Close the progress dialog
                  Navigator.pop(context);

                  // Navigate to the splash screen after payment
                  Navigator.pop(context, "Cash Paid");
                  Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pay Cash",
                      style: TextStyle(
                        fontSize: 20,
                        color: darkTheme ? Colors.black : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "in Rupees",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkTheme ? Colors.black : Colors.blue,
                        fontSize: 20,
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
