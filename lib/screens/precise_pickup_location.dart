import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/directions.dart';

class PrecisePickupLocation extends StatefulWidget {
  const PrecisePickupLocation({super.key});

  @override
  State<PrecisePickupLocation> createState() => _PrecisePickupLocationState();
}

class _PrecisePickupLocationState extends State<PrecisePickupLocation> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  LatLng? pickLocation;
  loc.Location location = loc.Location();
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  String? _address = "Set your pick-up location";
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Default location (India's coordinates)
    zoom: 14.4746,
  );
  Position? userCurrentPosition;
  double bottomPaddingOfMap = 0;

  Future<void> locateUserPosition() async {
    try {
      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception("Location permissions are permanently denied.");
        }
      }

      // Get the user's current position
      userCurrentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng userLatLng = LatLng(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
      );

      // Update the map's camera position
      CameraPosition cameraPosition = CameraPosition(
        target: userLatLng,
        zoom: 15,
      );

      newGoogleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );

      // Get the address of the current location
      getAddressFromLatLng(userLatLng);
    } catch (e) {
      debugPrint("Error locating user position: $e");
    }
  }

  Future<void> getAddressFromLatLng(LatLng position) async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        googleMapApiKey: mapKey, // Ensure your mapKey is valid
      );

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = data.address;

      // Update AppInfo with the new address
      Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);

      print("Address: ${data.address}");
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(top: 100, bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) async {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              // Locate and redirect to user's position when the map is created
              await locateUserPosition();
              setState(() {
                bottomPaddingOfMap = 50;
              });
            },
            onCameraMove: (CameraPosition position) {
              pickLocation = position.target; // Update the pick location
            },
            onCameraIdle: () {
              if (pickLocation != null) {
                getAddressFromLatLng(pickLocation!);
              }
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: 60,bottom: bottomPaddingOfMap),
              child: Image.asset(
                "images/pick.png",
                height: 45,
                width: 45,
              ),
            ),
          ),
       Positioned(
        top: 40,
        right: 20,
        left: 20,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(20),
          child: Consumer<AppInfo>(
            builder: (context, appInfo, child) {
              return Text(
                appInfo.userPickUpLocation != null
                    ? (appInfo.userPickUpLocation!.locationName!.length > 24
                    ? "${appInfo.userPickUpLocation!.locationName!.substring(0, 24)}..."
                    : appInfo.userPickUpLocation!.locationName!)
                    : "Fetching address...",
                overflow: TextOverflow.visible,
                softWrap: true,
              );
            },
          ),
        ),
       ),
          Positioned(
            bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                  padding: EdgeInsets.all(12),
                child: ElevatedButton(onPressed: (){
                  Navigator.pop(context);
                },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(
                        "Set Current Location",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                ),
              ),
          ),
        ],
      ),
    );
  }
}
