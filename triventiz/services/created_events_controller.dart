import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:triventiz/services/settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../homes/creatorhomepage.dart';
import '../models/creatoreventsmodel.dart';
import '../server/apiclient.dart';
import '../server/getxserver.dart';
import '../utils/stylings.dart';

class CreatedEventsController extends GetxController{
  var dIsLoading = false.obs;

  var allCollectedEvents = [].obs;
  var myUpcomingEvents = [].obs;
  var myPastEvents = [].obs;
//GET ALL CREATOR'S EVENTS
 Future getCreatorsEvents() async{
    dIsLoading.value = true;
  await  EventApiClient().makeGetRequest('creator-events/${Get.find<Triventizx>().userId}').then((e){
      if (Get.find<Triventizx>().statusCode.value == 0) {
       //print(e);
       print(Get.find<Triventizx>().userId);
       // print(Get.find<Triventizx>().userAccessToken);
        final creatorEventsModel = creatorEventsModelFromJson(jsonEncode(e));
        allCollectedEvents.value=creatorEventsModel.data;
        collateEvents();
       //allCollectedEvents.value=e['data'];
        dIsLoading.value = false;
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print(e);
        dIsLoading.value = false;
      }
      else{
        print(e);
        dIsLoading.value = false;
      }
    });

  }

  //SEPERATE INTO PAST AND UPCOMING
  collateEvents(){
   // print(allCollectedEvents.length);
    //resetting
    myUpcomingEvents.value = [];
    myPastEvents.value = [];
   // for(int i=0; i<allCollectedEvents.length; i++){
   //   DateTime eventDate = DateTime.parse("${allCollectedEvents[i].startDate}");
   //   DateTime now = DateTime.now();
   //   eventDate.isAfter(now)?  myUpcomingEvents.add(allCollectedEvents[i]):myPastEvents.add(allCollectedEvents[i]);;
   //   // if(eventDate.isAfter(now)){
   //   //  myUpcomingEvents.add(allCollectedEvents[i]);
   //   // }
   //   // else if (eventDate.isAfter(now)){
   //   //   myPastEvents.add(allCollectedEvents[i]);
   //   // }
   // }
    for(Datum event in allCollectedEvents){
      //dates
      DateTime eventDate = DateTime.parse("${event.startDate}");
      DateTime now = DateTime.now();
     // print(event.endDate);
      eventDate.isAfter(now)?myUpcomingEvents.add(event):eventDate.isBefore(now)?myPastEvents.add(event):();
    }
   //print(myUpcomingEvents);
  }

  var whichTab = 'Upcoming'.obs;

 //attendees
  var allAttendees = [].obs;
  var howManyAttendees = 0.obs;
  Future getAllAttendees(String eventID)async{
    dIsLoading.value = true;
    await  EventApiClient().makeGetRequest('attendees/$eventID').then((e){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(e);
        allAttendees.value = e['data'];
       howManyAttendees.value = allAttendees.length;
        dIsLoading.value = false;
        print(allAttendees);
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print(e);
        dIsLoading.value = false;
      }
      else{
        print(e);
        dIsLoading.value = false;
      }
    });
  }


  //deleteEvent
  // Helper function to encode query parameters
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
  deleteAnEvent({required String creatorName,required String eventName, required String eventId}) async{
    // delIsLoading.value = true;
    // EventApiClient().makeGetRequest("delete-event?creatorId=$creatorId&eventId=$eventId").then((d){
    //   if (Get.find<Triventizx>().statusCode.value == 0) {
    //     print(d);
    //     delIsLoading.value = false;
    //     Get.defaultDialog(
    //         barrierDismissible: true,
    //         title: "",
    //         radius: 12,
    //         backgroundColor: Colors.white,
    //         titlePadding: EdgeInsets.zero,
    //         content: Column(
    //           mainAxisAlignment: MainAxisAlignment.start,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
    //                 onLoaded: (q){
    //                   Future.delayed(Duration(milliseconds: 2500),(){
    //                     Get.offAll(()=>CreatorHomepage(),
    //                         fullscreenDialog: true,
    //                         transition: Transition.rightToLeftWithFade,
    //                         duration: const Duration(milliseconds: 1500)
    //                     );
    //                   });
    //                 }),
    //             Text(
    //                 "Event Deleted",
    //                 style: Stylings.thicSubtitle
    //             ),
    //             const SizedBox(height: 15,),
    //           ],
    //         )
    //     );
    //   }
    //   else if(Get.find<Triventizx>().statusCode.value == 1){
    //     print(d);
    //     delIsLoading.value = false;
    //     Get.defaultDialog(
    //         barrierDismissible: true,
    //         title: "",
    //         radius: 12,
    //         backgroundColor: Colors.white,
    //         titlePadding: EdgeInsets.zero,
    //         content: Column(
    //           mainAxisAlignment: MainAxisAlignment.start,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //             SizedBox(height: Get.height*0.01,),
    //             Text(
    //                 "An Error Occurred",
    //                 style: Stylings.thicSubtitle
    //             ),
    //             const SizedBox(height: 5,),
    //             Text(
    //               d['message'],
    //               style: Stylings.body,textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 15,),
    //             GestureDetector(
    //               onTap: (){
    //                 Get.back();
    //                 delIsLoading.value=false;
    //               },
    //               child: Container(
    //                 alignment: const Alignment(0, 0),
    //                 width: Get.width,
    //                 height: 44,
    //                 decoration:BoxDecoration(
    //                     color: Stylings.blue,
    //                     borderRadius: BorderRadius.circular(8)
    //                 ),
    //                 child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //               ),
    //             )
    //           ],
    //         )
    //     );
    //   }
    //   else{
    //     delIsLoading.value = false;
    //     Get.defaultDialog(
    //         barrierDismissible: true,
    //         title: "",
    //         radius: 12,
    //         backgroundColor: Colors.white,
    //         titlePadding: EdgeInsets.zero,
    //         content: Column(
    //           mainAxisAlignment: MainAxisAlignment.start,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //             SizedBox(height: Get.height*0.01,),
    //             Text(
    //                 "An Error Occurred",
    //                 style: Stylings.thicSubtitle
    //             ),
    //             const SizedBox(height: 5,),
    //             Text(
    //               "Please try again",
    //               style: Stylings.body,textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 15,),
    //             GestureDetector(
    //               onTap: (){
    //                 Get.back();
    //                 delIsLoading.value=false;
    //               },
    //               child: Container(
    //                 alignment: const Alignment(0, 0),
    //                 width: Get.width,
    //                 height: 44,
    //                 decoration:BoxDecoration(
    //                     color: Stylings.blue,
    //                     borderRadius: BorderRadius.circular(8)
    //                 ),
    //                 child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //               ),
    //             )
    //           ],
    //         )
    //     );
    //   }
    // });
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '${Get.find<SettingsController>().contactInfo['email']!.toLowerCase()}',
      query: encodeQueryParameters({
        'subject': 'DELETE EVENT',
        'body':'I $creatorName would like to have my event ${eventName.toUpperCase()} deleted because \n ... \n\n Event Id - $eventId'
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
    } else {
    throw 'Could not launch email app';
    }
  }


  //payout
  var payIsLoading = false.obs;
  checkAnEventPayout(String eventId) async{
    print(eventId);
    payIsLoading.value = true;
    EventApiClient().makeGetRequest("request-payout/$eventId").then((d){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(d);
        payIsLoading.value = false;

      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print(d);
        payIsLoading.value = false;
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
                Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
                SizedBox(height: Get.height*0.01,),
                Text(
                    "An Error Occurred",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  d['message'],
                  style: Stylings.body,textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    Get.back();
                    payIsLoading.value=false;
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration:BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
                  ),
                )
              ],
            )
        );
      }
      else{
        payIsLoading.value = false;
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
                Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
                SizedBox(height: Get.height*0.01,),
                Text(
                    "An Error Occurred",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  "Please try again",
                  style: Stylings.body,textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    Get.back();
                    payIsLoading.value=false;
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration:BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
                  ),
                )
              ],
            )
        );
      }
    });

  }


//END
}