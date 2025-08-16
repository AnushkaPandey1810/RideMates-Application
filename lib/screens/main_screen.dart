import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:user_app/Assistants/assistant_methods.dart';
import 'package:user_app/Assistants/geofire_assistant.dart';
import 'package:user_app/Widgets/progress_dialog.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/global/map_key.dart';
import 'package:user_app/infoHandler/app_info.dart';
import 'package:user_app/models/active_nearby_available_drivers.dart';
import 'package:user_app/screens/drawer_screen.dart';
import 'package:user_app/screens/precise_pickup_location.dart';
import 'package:user_app/screens/search_places_screen.dart';
import 'package:user_app/splashScreen/splash_screen.dart';
import '../Widgets/pay_fare_amount_dialog.dart';
import '../models/directions.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  LatLng? pickLocation;
  loc.Location location = loc.Location();
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220;
  double waitResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Default location (India's coordinates)
    zoom: 14.4746,
  );

  Position? userCurrentPosition;
  var geoLocation = Geolocator();
  double bottomPaddingOfMap = 0;
  List<LatLng> pLineCoordinatesList = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  String userName = "";
  String userEmail = "";
  bool openNavigationDrawer = true;
  bool activeNearbyDriverKeyLoaded = false;
  BitmapDescriptor? activeNearbyIcon;
  String selectedVehicleType = "";

  DatabaseReference? referenceRideRequest;

  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;

  String userRideRequestStatus = "";

  bool requestPositionInfo = true;

  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];

  double searchingForDriverContainerHeight = 0;
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
    initializeGeoFireListener();
  }

  initializeGeoFireListener(){
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
    .listen((map){
      print(map);

      if(map != null){
        var callBack = map["callBack"];
        switch(callBack){
          case Geofire.onKeyEntered:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            if(activeNearbyDriverKeyLoaded == true){
              displayActiveDriversOnUsersMap();
            }
            break;

          case Geofire.onKeyExited:
           GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
           break;

          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            displayActiveDriversOnUsersMap();
            break;

          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeyLoaded = true;
            displayActiveDriversOnUsersMap();
            break;
        }
      }
      setState(() {

      });
    });
  }

  displayActiveDriversOnUsersMap(){
    setState(() {
      markersSet.clear();
      circlesSet.clear();

      Set<Marker> driversMarkerSet = Set<Marker>();

      for(ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
            markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );
        driversMarkerSet.add(marker);
      }

      setState(() {
        markersSet = driversMarkerSet;
      });

    });
}
void showSuggestedRidesContainer(){
    setState(() {
      suggestedRidesContainerHeight = 450;
      bottomPaddingOfMap = 400;
    });
}
  createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(0.2, 0.2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value){
        activeNearbyIcon = value;
      });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    // Check if either the origin or destination is null
    if (originPosition == null || destinationPosition == null) {
      debugPrint("Origin or destination is null");
      return;
    }

    var originLatLng = LatLng(originPosition.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition.locationLatitude!, destinationPosition.locationLongitude!);

    // Show a loading indicator while fetching direction details
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait..."),
    );

    try {
      // Fetch the direction details from the API
      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

      // Check if no directions were found
      if (directionDetailsInfo == null) {
        Navigator.pop(context);
        debugPrint("No route found between origin and destination.");
        return;
      }

      // Update the state with the direction details
      setState(() {
        tripDirectionDetailsInfo = directionDetailsInfo;
      });

      // Dismiss the loading indicator
      Navigator.pop(context);

      // Decode the polyline points
      PolylinePoints pPoints = PolylinePoints();
      List<PointLatLng> decodePolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);

      print("Encoded Points: ${directionDetailsInfo.e_points}");

      // Clear previous polyline coordinates
      pLineCoordinatesList.clear();

      // Check if the polyline points are decoded correctly
      if (decodePolyLinePointsResultList.isNotEmpty) {
        for (var pointLatLng in decodePolyLinePointsResultList) {
          pLineCoordinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
          print("Decoded Polyline Points: ${decodePolyLinePointsResultList.length}");
        }
      }

      // Clear the previous polyline set
      polylineSet.clear();

      // Add the new polyline to the map
      setState(() {
        Polyline polyline = Polyline(
          color: darkTheme ? Colors.amberAccent : Colors.blue,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinatesList,
          startCap: Cap.roundCap,
          geodesic: true,
          width: 5,
        );
        polylineSet.add(polyline);
      });

      // Set the bounds for the camera to focus on the entire route
      LatLngBounds boundsLatLng;
      if (originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude) {
        boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
      } else if (originLatLng.longitude > destinationLatLng.longitude) {
        boundsLatLng = LatLngBounds(
          southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        );
      } else if (originLatLng.latitude > destinationLatLng.latitude) {
        boundsLatLng = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
          northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        );
      } else {
        boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
      }

      // Animate the camera to show the entire route
      newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
    } catch (e) {
      // Handle any exceptions
      Navigator.pop(context);
      debugPrint("Error while drawing polyline: $e");
    }
    Marker OriginMarker = Marker(
        markerId: MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    Marker DestinationMarker = Marker(
      markerId: MarkerId("DestinationID"),
      infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    setState(() {
      markersSet.add(OriginMarker);
      markersSet.add(DestinationMarker);
    });
    Circle originCircle = Circle(
        circleId: CircleId("origin"),
      fillColor:  Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );
    Circle destinationCircle = Circle(
      circleId: CircleId("destination"),
      fillColor:  Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );
    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }
  void showSearchForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  saveRideRequestInformation(selectedVehicleType){
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();
    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };
    Map userInformationMap = {
      "origin":originLocationMap,
      "destination":destinationLocationMap,
      "time":DateTime.now().toString(),
      "userName":userModelCurrentInfo!.name,
      "userPhone":userModelCurrentInfo!.phone,
      "originAddress":originLocation.locationName,
      "destinationAddress":destinationLocation.locationName,
      "driverId":"waiting",
    };

    referenceRideRequest!.set(userInformationMap);
    tripRidesRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }
      if((eventSnap.snapshot.value as Map)["car_details"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
        double driverCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());
        LatLng driverCurrentPositionLatLng = LatLng(
            driverCurrentPositionLng, driverCurrentPositionLng);

        if (userRideRequestStatus == "accepted") {
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }
        if(userRideRequestStatus == "arrived"){
          setState(() {
            driverRideStatus = "Driver has arrived";
          });
        }
        if (userRideRequestStatus == "ontrip") {
          updateArrivalTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }
        if(userRideRequestStatus == "ended"){
          if((eventSnap.snapshot.value as Map)["fareAmount"] != null){
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var response = await showDialog(context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                  fareAmount: fareAmount,
                )
            );
            if(response == "Cash Paid"){
              if((eventSnap.snapshot.value as Map)["driverId"] != null){
                String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
                //Navigator.push(context, MaterialPageRoute(builder: (c) => RateDriverScreen));

                referenceRideRequest!.onDisconnect();
                tripRidesRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }
    });
  }

  showUIForAssignedDriverInfo(){
    setState(() {
      waitResponsefromDriverContainerHeight = 0;
      searchingForDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
      suggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }
  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async{
    if(requestPositionInfo == true){
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
      driverCurrentPositionLatLng,userPickUpPosition,
      );
      if(directionDetailsInfo == null){
        return ;
      }
      setState(() {
        driverRideStatus = "Driver is coming: " + directionDetailsInfo.distance_text.toString();
      });
      requestPositionInfo = true;
    }
  }
  updateArrivalTimeToUserDropOffLocation(driverCurrentPositionLatLng) async{
    if(requestPositionInfo == true) {
      requestPositionInfo = false;
      var dropOffLocation = Provider.of<AppInfo>(context,listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(dropOffLocation!.locationLatitude!, dropOffLocation!.locationLongitude!);
      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(driverCurrentPositionLatLng, userDestinationPosition);

      if(directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Going Towards Destination: "+ directionDetailsInfo.duration_text.toString();
      });
      requestPositionInfo = true;
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
    createActiveNearByDriverIconMarker();
    return Scaffold(
      key: _scaffoldState,
      drawer: DrawerScreen(),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(top: 50, bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            initialCameraPosition: _kGooglePlex,
            polylines: polylineSet,
             markers: markersSet,
             circles: circlesSet,
            onMapCreated: (GoogleMapController controller) async {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              // Locate and redirect to user's position when the map is created
              await locateUserPosition();
              setState(() {
                bottomPaddingOfMap = 50;
              });
            },
          ),


          Positioned(
            top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  onTap: (){
                    _scaffoldState.currentState!.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: darkTheme ? Colors.black : Colors.lightBlue,
                    ),
                  ),
                ),
              ),
          ),
          Positioned(
            bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                    padding:EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                      SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "From",
                                            style: TextStyle(
                                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Consumer<AppInfo>(
                                                  builder: (context, appInfo, child) {
                                                     return Text(
                                                       appInfo.userPickUpLocation != null
                                                           ? (appInfo.userPickUpLocation!.locationName!.length > 24
                                                           ? "${appInfo.userPickUpLocation!.locationName!.substring(0, 24)}..."
                                                           : appInfo.userPickUpLocation!.locationName!)
                                                           : "Fetching address...",
                                                       overflow: TextOverflow.visible,
                                                       softWrap: true,
                                                       style: TextStyle(color: Colors.grey, fontSize: 14),
                                                     );
                                                   },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5,),

                                Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                ),

                                SizedBox(height: 5,),

                                Padding(
                                    padding: EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        var responsefromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen()));
                                        if(responsefromSearchScreen == "obtainedDropoff"){
                                          setState(() {
                                            openNavigationDrawer = false;
                                          });
                                        }
                                        await drawPolyLineFromOriginToDestination(darkTheme);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "To",
                                                style: TextStyle(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Consumer<AppInfo>(
                                                builder: (context, appInfo, child) {
                                                  return Text(
                                                    appInfo.userDropOffLocation != null
                                                        ? (appInfo.userDropOffLocation!.locationName!.length > 24
                                                        ? "${appInfo.userDropOffLocation!.locationName!.substring(0, 24)}..."
                                                        : appInfo.userDropOffLocation!.locationName!)
                                                        : "Where to?",
                                                    overflow: TextOverflow.visible,
                                                    softWrap: true,
                                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (c) => PrecisePickupLocation()));
                              }, child: Text(
                                "Change Pick up Address.",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                ),
                              ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )
                                ),
                              ),
                              SizedBox(width: 10,),

                              ElevatedButton(onPressed: (){
                                  if(Provider.of<AppInfo>(context, listen: false).userDropOffLocation !=null){
                                    showSuggestedRidesContainer();
                                  }
                                  else{
                                    Fluttertoast.showToast(msg: "Please select destination location");
                                  }
                              },
                                child: Text(
                                "Show Fare",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                ),
                              ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    )
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
          ),
          Positioned(
            left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  )
                ),
                child: Padding(
                    padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10,),

                          Consumer<AppInfo>(
                            builder: (context, appInfo, child) {
                              return Text(
                                appInfo.userPickUpLocation != null
                                    ? (appInfo.userPickUpLocation!.locationName!.length > 24
                                    ? "${appInfo.userPickUpLocation!.locationName!.substring(0, 24)}..."
                                    : appInfo.userPickUpLocation!.locationName!)
                                    : "Fetching address...",
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20,),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10,),

                          Consumer<AppInfo>(
                            builder: (context, appInfo, child) {
                              return Text(
                                appInfo.userDropOffLocation != null
                                    ? (appInfo.userDropOffLocation!.locationName!.length > 24
                                    ? "${appInfo.userDropOffLocation!.locationName!.substring(0, 24)}..."
                                    : appInfo.userDropOffLocation!.locationName!)
                                    : "Where to?",
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20,),

                      Text("SUGGESTED RIDES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: (){
                              setState(() {
                                selectedVehicleType = "Car";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Car" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                  padding: EdgeInsets.all(25.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/Car1.png", scale: 2,
                                      width: 70, // Specify the desired width
                                      height: 70,

                                    ),

                                    SizedBox(height: 5,),

                                    Text(
                                      "Car",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Car" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white :Colors.black),
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!)*2)*50).toStringAsFixed(1)}"
                                      :"null",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 16,
                                      ),

                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: (){
                              setState(() {
                                selectedVehicleType = "CNG";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(25.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/CNG.png", scale: 2,
                                      width: 70, // Specify the desired width                                      height: 70,

                                    ),

                                    SizedBox(height: 5,),

                                    Text(
                                      "CNG",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white :Colors.black),
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!)*1.5)*50).toStringAsFixed(1)}"
                                          :"null",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 16,
                                      ),

                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: (){
                              setState(() {
                                selectedVehicleType = "Bike";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(25.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/bike.png", scale: 2,
                                      width: 70, // Specify the desired width
                                      height: 70,

                                    ),

                                    SizedBox(height: 5,),

                                    Text(
                                      "Bike",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white :Colors.black),
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!)*0.8)*50).toStringAsFixed(1)}"
                                          :"null",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 16,
                                      ),

                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 20,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Show progress dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false, // Prevent dismissing by tapping outside
                                    builder: (BuildContext context) {
                                      return ProgressDialog(message: "Please wait. Ride is getting completed...");
                                    },
                                  );

                                  // Simulate a loading process
                                  await Future.delayed(Duration(seconds: 3));

                                  // Close the progress dialog
                                  Navigator.pop(context);

                                  // Show PayFareAmountDialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return PayFareAmountDialog(
                                        fareAmount: 150.0, // Example fare amount
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  "Request a Ride",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ],
                  ),
        ],
       ),
      ),
      ),
       ),
       ],
      )
    );
  }
}

