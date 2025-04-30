import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:triventiz/homes/permissions/notificationpermission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triventiz/server/getxserver.dart';

import '../homes/attendeehomepage.dart';
import '../homes/creatorhomepage.dart';

class LocationController  extends GetxController{

  final isAcceessingLocation = RxBool(false);
  final Rx<LocationData?> userLocation = Rx<LocationData?>(null);
  final RxString errorDescription = RxString("");
  final RxList<Placemark> placeMarks = RxList([]);
  final RxString liveStateOrCity = RxString("");
  final RxString liveCountry = RxString("");


  void updateIsAccessinglocation(bool b){
    isAcceessingLocation.value =  b;
  }

  void updateUserLocation(LocationData data) async{
    userLocation.value = data;
    placeMarks.value = await placemarkFromCoordinates(userLocation.value?.latitude??37.4219, userLocation.value?.longitude??-122.084);
    liveStateOrCity.value = placeMarks[0].administrativeArea!;
    liveCountry.value = placeMarks[0].country!;
    persistLocation();
    //Get.find<Triventizx>().userLocation = "$liveStateOrCity, $liveCountry";
    // print(liveStateOrCity);
    // print(liveCountry);
  }

  void persistLocation() async{
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("uLocation", "$liveStateOrCity, $liveCountry");
    Get.to(()=>Notificationpermission());
    ///when we were skipping perms
    // if(Platform.isAndroid){
    //   Get.to(()=>Notificationpermission());
    // }
    // else{
    //   Get.find<Triventizx>().userRole=="attendee" ?Get.offAll(()=>Attendeehomepage()):  Get.offAll(()=>CreatorHomepage());
    // }
  }

  void assignDefaultLocation() async{
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
     sharedPreferences.remove("uLocation");
    liveStateOrCity.value = "London";
    liveCountry.value = "United Kingdom";
    Get.to(()=>Notificationpermission());
    ///when we were skipping perms
    // if(Platform.isAndroid){
    //   Get.to(()=>Notificationpermission());
    // }
    // else{
    //   Get.find<Triventizx>().userRole=="attendee" ?Get.offAll(()=>Attendeehomepage()):  Get.offAll(()=>CreatorHomepage());
    // }
  }


}

