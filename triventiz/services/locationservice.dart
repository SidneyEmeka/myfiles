import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../utils/stylings.dart';
import 'location_controller.dart';

class LocationService {
  LocationService.init();

  static LocationService instance = LocationService.init();

  Location _location = Location();

  //enabling device location
  Future<bool> checkForServiceAvailability() async{
     bool isEnabled = await _location.serviceEnabled();
    if(isEnabled){
      return Future.value(true);
    }

    isEnabled = await _location.requestService();
    if(isEnabled){
      return Future.value(true);
    }

    return Future.value(false);
  }

  //check permission
  Future<bool> checkForPermision() async{
     PermissionStatus status =await _location.hasPermission();
    if(status == PermissionStatus.denied){
      status = await _location.requestPermission();
      if(status==PermissionStatus.granted){
        //access the  location
        return true;
      }
      return false;
    }
    if(status==PermissionStatus.deniedForever){
      Get.defaultDialog(
          barrierDismissible: true,
          title: "",
          radius: 12,
          backgroundColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  "Permission is Needed",
                  style: Stylings.thicSubtitle
              ),
              const SizedBox(height: 5,),
              Text(
                "3ventiz needs access to your location to give you a tailored experience",
                style: Stylings.body,textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                 handler.openAppSettings();
                },
                child: Container(
                  alignment: const Alignment(0, 0),
                  width: Get.width,
                  height: 44,
                  decoration:BoxDecoration(
                      color: Stylings.blue,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text("Open Settings",style: Stylings.body.copyWith(color: Colors.white),),
                ),
              )
            ],
          )
      );
      return false;
    }

    return Future.value(true);


  }


  //get the location co-ordinates
Future<void> getUserlocation({required LocationController controller}) async{
    controller.updateIsAccessinglocation(true);
    if(!(await checkForServiceAvailability())){
      controller.errorDescription.value ="Service not enabled";
      controller.updateIsAccessinglocation(false);
      Get.snackbar("Permission status", "${controller.errorDescription.value}");
      return;
    }
    if(!(await checkForPermision())){
      controller.errorDescription.value ="Permission not given";
      controller.updateIsAccessinglocation(false);
      Get.snackbar("Permission status", "${controller.errorDescription.value}");
      return;
    }
    final LocationData data = await _location.getLocation();
    controller.updateUserLocation(data);
    controller.updateIsAccessinglocation(false);

}








}