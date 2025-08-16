import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:user_app/Assistants/request_assistant.dart';
import '../global/global.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/direction_details.dart';
import '../models/directions.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
class AssistantMethods {
  static Future<void> readCurrentOnLineUserInfo() async {
    try {
      currentUser = firebaseAuth.currentUser;

      if (currentUser != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(currentUser!.uid);

        DataSnapshot snap = await userRef.get();

        if (snap.value != null) {
          userModelCurrentInfo = UserModel.fromSnapshot(snap);
        }
      }
    } catch (e) {
      debugPrint("Error reading user info: $e");
    }
  }

  static Future<String> searchAddressForGeographicCoordinates(
      Position position, BuildContext context) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    try {
      var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

      if (requestResponse != null &&
          requestResponse["results"] != null &&
          requestResponse["results"].isNotEmpty) {
        humanReadableAddress =
        requestResponse["results"][0]["formatted_address"];

        // Update the Provider with the new address
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = position.latitude;
        userPickUpAddress.locationLongitude = position.longitude;
        userPickUpAddress.locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false)
            .updatePickUpLocationAddress(userPickUpAddress);
      } else {
        debugPrint("No valid address found for the given coordinates.");
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }

    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo?> obtainOriginToDestinationDirectionDetails(
      LatLng originPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    debugPrint("Origin Coordinates: ${originPosition.latitude}, ${originPosition.longitude}");
    debugPrint("Destination Coordinates: ${destinationPosition.latitude}, ${destinationPosition.longitude}");

    try {
      var responseDirectionApi =
      await RequestAssistant.receiveRequest(urlOriginToDestinationDirectionDetails);

      if (responseDirectionApi != null) {
        // Log the response to debug any issues
        debugPrint("Response from Directions API: $responseDirectionApi");

        if (responseDirectionApi["routes"] != null &&
            responseDirectionApi["routes"].isNotEmpty) {
          DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
          directionDetailsInfo.e_points =
          responseDirectionApi["routes"][0]["overview_polyline"]["points"];
          directionDetailsInfo.distance_text =
          responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
          directionDetailsInfo.distance_value =
          responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
          directionDetailsInfo.duration_text =
          responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
          directionDetailsInfo.duration_value =
          responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
          return directionDetailsInfo;
        } else {
          // If routes are not found, log detailed information about the response
          debugPrint("No routes found between the given origin and destination.");
          debugPrint("Routes: ${responseDirectionApi['routes']}");
          return null;
        }
      } else {
        // Handle null or invalid API response
        debugPrint("Invalid response from Directions API.");
        return null;
      }
    } catch (e) {
      // Catch and log any errors encountered during the API call
      debugPrint("Error fetching direction details: $e");
      return null;
    }
  }
  static double calculateFareAmountFromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
    double timeTraveledFareAmountPerMinute = (directionDetailsInfo.duration_value! /60) *0.1;
    double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.duration_value! /1000)* 0.1;

    double totalFareAmount = timeTraveledFareAmountPerMinute + distanceTraveledFareAmountPerKilometer;
    return double.parse(totalFareAmount.toStringAsFixed(1));
  }
  static sendNotificationToDriverNow(String deviceRegistrstionToken, String userRideRequestId, context) async{
    String destinationAddress = userDropOffAddress;

    Map<String, String> headerNotification ={
      'Content-Type':'application/json',
      'Authorization': cloudMessageingServerToken,
    };
    Map bodyNotification = {
      "body":"Destination Address: \n $destinationAddress.",
      "title":"New Trip Request"
    };
    Map dataMap ={
      "click_action":"FLUTTER_NOTIFICATION_CLICK",
      "id":"1",
      "ststus":"done",
      "rideRequestId":userRideRequestId
    };
    Map officialNotificationFormat ={
      "notification": bodyNotification,
      "data":dataMap,
      "priority":"high",
      "to":deviceRegistrstionToken,
    };
    var responseNotification = http.post(
      Uri.parse("https://fcm.googleapis.com/v1/projects/ridemates-application-d6aec/messages:send"),
      headers: headerNotification,
      body: jsonEncode(officialNotificationFormat),
    );
  }
}