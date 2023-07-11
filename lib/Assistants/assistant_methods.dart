import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:user_ride/Assistants/request_assistant.dart';
import 'package:user_ride/global/global.dart';
import 'package:user_ride/global/map_key.dart';
import 'package:user_ride/models/directions.dart';
import 'package:user_ride/models/user_model.dart';
import 'package:http/http.dart' as http;

import '../infoHandler/app_info.dart';
import '../models/direction_details_info.dart';


class AssistantMethods {
    static void readCurrentOnlineUserInfo() async {
      currentUser = firebaseAuth.currentUser;
      DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentUser!.uid);

      userRef.once().then((snap){
        if(snap.snapshot.value != null){
           userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        }
      });
    }

    static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async{
      String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
      String humanReadableAddress = "";

      var requestResponse = await RequestAssistant.recieveRequest(apiUrl);
      if(requestResponse != "failedResponse"){
        humanReadableAddress =  requestResponse["results"][0]["formatted_address"];//fromatted_addresss

        Directions userPickupAddress = Directions();
        userPickupAddress.locationLatitude = position.latitude;
        userPickupAddress.locationLongitude = position.longitude;
        userPickupAddress.locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickupAddress);
      }
      return humanReadableAddress;
    }

    static Future<DirectionDetailsInfo> obtainedOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition) async{
      String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
      var responseDirectionApi = await RequestAssistant.recieveRequest(urlOriginToDestinationDirectionDetails);

      // if(responseDirectionApi == "failedResponse"){
      //   return null;
      // }

      DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
      directionDetailsInfo.e_points = responseDirectionApi["routes"][0]["overview_polyline"]["points"];

      directionDetailsInfo.distance_text = responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
      directionDetailsInfo.distance_value = responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

      directionDetailsInfo.duration_text = responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
      directionDetailsInfo.duration_value = responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
      return directionDetailsInfo;
    }

    static double calculateFareAmountFromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
      double timeTraveledFareAmountPerMinute = (directionDetailsInfo.duration_value! / 60) * 0.1;
      double distanceTraveledFareAmountPerMinute = (directionDetailsInfo.distance_value! / 1000) * 0.1;

      //USD
      double totalFareAmount = timeTraveledFareAmountPerMinute + distanceTraveledFareAmountPerMinute;

      return double.parse(totalFareAmount.toStringAsFixed(1));
    }

    //here deviceRegistrationToken=driversList[i]["token"]  and userRideRequestId=referenceRideRequest!.key!
    static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async{
      String destinationAddress = userDropOffAddress;

      Map<String, String> headerNotification = {
        'Content-Type': 'application/json',
        'Authorization': cloudMessagingServerToken,
      };

      Map bodyNotification = {
        "body": "DestinationAddress: \n$destinationAddress.",
        "title": "New Trip Request",
      };

      Map dataMap = {
        "click_action": "FLUTTER NOTIFICATION CLICK", //use in <intent-filter> in manifestFile of DriverApp
        "id": "1",
        "status": "done",
        "rideRequestId": userRideRequestId, //use as remoteMessage.data["rideRequestId"] in DriverApp
      };

      Map officialNotificationFormat = {
        "notification": bodyNotification,
        "data": dataMap,
        "priority": "high",
        "to": deviceRegistrationToken
      };

      var responseNotification = http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: headerNotification,
        body: jsonEncode(officialNotificationFormat),
      );
    }

}