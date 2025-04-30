import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:triventiz/homes/creatordashboard/createdevents/creatormyevents.dart';
import 'package:triventiz/homes/creatordashboard/createevent/addticketdetails.dart';
import 'package:triventiz/homes/creatordashboard/createevent/previeweventdetails.dart';
import 'package:triventiz/homes/creatordashboard/createevent/puborprivate.dart';
import 'package:triventiz/homes/creatordashboard/creatornotifications.dart';
import 'package:triventiz/homes/creatorhomepage.dart';
import 'package:triventiz/server/apiclient.dart';
import 'package:triventiz/server/getxserver.dart';

import '../utils/reusables/ticketdetailsfield.dart';
import '../utils/stylings.dart';

import '/models/creatoreventsmodel.dart';

class EditLiveEventController extends GetxController{
  var edIsLoading = false.obs;
  var eStatusCode = 0.obs;
  RxList<String> eEventTypes = RxList(['virtual', 'physical']);
  RxString eEventName = RxString("");
  RxString eEventLocation = RxString("");

  RxDouble eEventLocationLat = RxDouble(51.5074);
  RxDouble eEventLocationLng = RxDouble(-0.1278);

  RxString eEventDescription = RxString("");
  RxString eEventRegistryLink = RxString("");
  RxString eEventStartDate = RxString("");
  RxString eEventStartTime = RxString("");
  RxString eEventEndDate = RxString("");
  RxString eEventEndTime = RxString("");
  RxString eEventType = RxString("physical");
  RxString eEventTags = RxString("");
  RxList eEventTag = RxList();//to server
  formTags(String tags){
    eEventTag.value = tags.split(',');
  }
  RxString eimgUrl = RxString("");
  RxList<Map<String,dynamic>> eEventTickets = RxList([{}]);
  RxString eEventUrl = RxString(""); //nousage
  RxBool eEventInviteOnly = RxBool(false); //nousage
  RxString eEventVisibility = RxString("public");
  RxMap<String,dynamic> eEventPrivateVisibilityOptions = RxMap({
    "linkAccess": false,
    "passwordProtected": false,
    "password": ""});
  RxString eEventPublishType = RxString("now");
  RxString escheduleDate = RxString("${DateFormat.yMd().format(DateTime.now())}");
  RxString escheduleTime = RxString("10:00AM");
  RxMap eEventPublishSchedule =RxMap({});

  RxString ecouponCode = RxString("");
  RxString ecouponDiscount = RxString("");
  RxString ecouponExpDate = RxString("");
  RxString ecouponExpTime = RxString("");
  RxInt ecouponMaxUse = RxInt(0);

  RxBool elinkAccess = RxBool(true);
  RxBool epasswordProtected = RxBool(false);
  RxString epasswordProtectedPassword = RxString("");
//ticket
  RxList<String> eticketTypes = RxList(['Regular', 'General Admission', 'VIP']);
  RxBool eisTicketFree = RxBool(false);//nousage

  ///creating new ticket category
  // List to store our widgets
  RxList<Widget> eticketField = RxList([Ticketdetailsfield(0)]);
  RxInt eticketFieldId =RxInt(0);
  void addNewTicketField() {
    if(eticketField.length>2){
      Get.snackbar("Limit Exceeded", "You can only create a maximum of 3 Ticket categories");
    }
    else{
      eticketFieldId++;
      eEventTickets.add({});
      eticketField.add(Ticketdetailsfield(eticketFieldId.value));
    }
    update();
  }

  //image upload
  //File? _image;
  XFile? _pickedFile;
  XFile? get epickedFile => _pickedFile;
  final _picker = ImagePicker();
  Future<void> pickImage() async{
    _pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if(_pickedFile != null){

    }
  }




  RxMap<String,dynamic> createEventLoad = RxMap(
      {
        "creatorId": "",
        "name": "",
        "location": "",
        "description": "",
        "startDate": "",
        "startTime": "",
        "endDate": "",
        "endTime": "",
        "eventType": "",
        "eventTag": "",
        "tickets": [
          {
            "name": "",
            "quantity": "",
            "price": "number",
            "salesStartDate": "",
            "salesStartTime": "",
            "salesEndDate": "",
            "salesEndTime": "",
            "description": ""
          }
        ],
        "url": "",
        "visibility": "",
        "privateVisibilityOptions": {
          "linkAccess": "",
          "passwordProtected": "",
          "password": ""
        },
        "publish": "",
        "publishSchedule": {
          "startDate": "",
          "startTime": ""
        }
      });

//BASIC INFO
  RxBool eisSameDayEvent = RxBool(false);
  emakeEventSameDay(){
    if(eEventStartDate.value=="YY-MM-DD"){
      Get.snackbar("Start Date", "Kindly choose a start date");
      eisSameDayEvent.value=false;
    }
    else if(eisSameDayEvent.value && eEventStartDate.value!="YY-MM-DD"){
      eEventEndDate.value = eEventStartDate.value;
    }
    else if(!eisSameDayEvent.value && eEventStartDate.value!="YY-MM-DD"){
      eEventEndDate.value = "YY-MM-DD";
    }

  }


//step 1
  ebasicInfoSave(Datum theEvent) {
    edIsLoading.value = true;
    if(_pickedFile==null){
    Map<String, dynamic> payload = {
      // "creatorId": "${Get.find<Triventizx>().userId}",
      // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
      "name": eEventName.value.isEmpty ? "${theEvent.name}" : "${eEventName
          .value}",
      // "eventId": "${theEvent.id}",
      "location": eEventLocation.isEmpty
          ? "${theEvent.location}"
          : "${eEventLocation.value}",
      "description": eEventDescription.value.isEmpty
          ? "${theEvent.description}"
          : "${eEventDescription.value}",
      "startDate": eEventStartDate.value.isEmpty
          ? "${theEvent.startDate}"
          : "${eEventStartDate.value}",
      "startTime": eEventStartTime.value.isEmpty
          ? "${theEvent.startTime}"
          : "${eEventStartTime.value}",
      "endDate": eEventEndDate.value.isEmpty
          ? "${theEvent.endDate}"
          : "${eEventEndDate.value}",
      "endTime": eEventEndTime.value.isEmpty
          ? "${theEvent.endTime}"
          : "${eEventEndTime.value}",
      "eventType": "${eEventType.value}", //chk
      "eventTag": theEvent.eventTag,
      "giftLink": eEventRegistryLink.value.isEmpty
          ? "${theEvent.giftLink}"
          : "${eEventRegistryLink.value}",
      "inviteOnly": theEvent.inviteOnly,
      "tickets": theEvent.tickets,
      "url": theEvent.url, //chk
      "visibility": theEvent.visibility,
      "privateVisibilityOptions": theEvent.privateVisibilityOptions,
      "publish": 'now',
      "publishSchedule": {},
      "coupon": theEvent.coupon,
      "discount": theEvent.discount,
      "expiryDate": theEvent.expiryDate == null ? "" : "${theEvent.expiryDate}",
      "expiryTime": theEvent.expiryTime,
      "maxRedemptions": theEvent.maxRedemptions
    };
    print(payload);
    // print(Get.find<Triventizx>().userAccessToken);
    EventApiClient().makePatchRequest(
        endPoint: "update-event?creatorId=${theEvent
            .creatorId}&eventId=${theEvent.id}", body: payload).then((p) {
      if (
      Get
          .find<Triventizx>()
          .statusCode
          .value == 0) {
        print(p);
        edIsLoading.value = false;
     //   createEventError.value = "";
     //   cBlurUBackground.value = true;
        _pickedFile = null;
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
                Lottie.asset(
                    "assets/animations/check.json", width: Get.height * 0.12,
                    height: Get.height * 0.12,
                    repeat: false,
                    onLoaded: (q) {
                      Future.delayed(Duration(milliseconds: 2500), () {
                       // cBlurUBackground.value = false;
                        Get.offAll(() => CreatorHomepage(),
                            fullscreenDialog: true,
                            transition: Transition.rightToLeftWithFade,
                            duration: const Duration(milliseconds: 1500)
                        );
                      });
                    }),
                Text(
                    "Publishing your event",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  "Hang tight as we finalize the details for your event!",
                  style: Stylings.body, textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
              ],
            )
        );
      }
      else if (Get.find<Triventizx>().statusCode.value == 1) {
       // cBlurUBackground.value = true;
        print(p);
      //  createEventError.value = p["message"];
        edIsLoading.value = false;
        _pickedFile = null;
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
                Icon(Icons.cancel_outlined, size: 40, color: Colors.red,),
                SizedBox(height: Get.height * 0.01,),
                Text(
                    "An Error Occurred",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  "${p["message"]}",
                  style: Stylings.body, textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: () {
                    //cBlurUBackground.value = false;
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text("Try again",
                      style: Stylings.body.copyWith(color: Colors.white),),
                  ),
                )
              ],
            )
        );
      }
      else {
       // cBlurUBackground.value = true;
       // createEventError.value = "An error occurred";
        edIsLoading.value = false;
        _pickedFile = null;
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
                Icon(Icons.cancel_outlined, size: 40, color: Colors.red,),
                SizedBox(height: Get.height * 0.01,),
                Text(
                    "An Error Occurred",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  "Please try again",
                  style: Stylings.body, textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: () {
                    //cBlurUBackground.value = false;
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text("Try again",
                      style: Stylings.body.copyWith(color: Colors.white),),
                  ),
                )
              ],
            )
        );
      }
    });
  }
  else{
    EventApiClient().uploadImage(_pickedFile!, eimgUrl).then((w){
      if(w==0){
        //edIsLoading.value = false;
        //print(theEvent.url[0].link);
        theEvent.url[0]=Url(id: theEvent.url[0].id, link: "$eimgUrl");
        //print(theEvent.url[0].link);
        Map<String, dynamic> payload = {
          // "creatorId": "${Get.find<Triventizx>().userId}",
          // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
          "name": eEventName.value.isEmpty ? "${theEvent.name}" : "${eEventName
              .value}",
          // "eventId": "${theEvent.id}",
          "location": eEventLocation.isEmpty
              ? "${theEvent.location}"
              : "${eEventLocation.value}",
          "description": eEventDescription.value.isEmpty
              ? "${theEvent.description}"
              : "${eEventDescription.value}",
          "startDate": eEventStartDate.value.isEmpty
              ? "${theEvent.startDate}"
              : "${eEventStartDate.value}",
          "startTime": eEventStartTime.value.isEmpty
              ? "${theEvent.startTime}"
              : "${eEventStartTime.value}",
          "endDate": eEventEndDate.value.isEmpty
              ? "${theEvent.endDate}"
              : "${eEventEndDate.value}",
          "endTime": eEventEndTime.value.isEmpty
              ? "${theEvent.endTime}"
              : "${eEventEndTime.value}",
          "eventType": "${eEventType.value}", //chk
          "eventTag": theEvent.eventTag,
          "giftLink": eEventRegistryLink.value.isEmpty
              ? "${theEvent.giftLink}"
              : "${eEventRegistryLink.value}",
          "inviteOnly": theEvent.inviteOnly,
          "tickets": theEvent.tickets,
          "url": theEvent.url, //chk
          "visibility": theEvent.visibility,
          "privateVisibilityOptions": theEvent.privateVisibilityOptions,
          "publish": 'now',
          "publishSchedule": {},
          "coupon": theEvent.coupon,
          "discount": theEvent.discount,
          "expiryDate": theEvent.expiryDate == null ? "" : "${theEvent.expiryDate}",
          "expiryTime": theEvent.expiryTime,
          "maxRedemptions": theEvent.maxRedemptions
        };
        EventApiClient().makePatchRequest(
            endPoint: "update-event?creatorId=${theEvent
                .creatorId}&eventId=${theEvent.id}", body: payload).then((p) {
          if (
          Get
              .find<Triventizx>()
              .statusCode
              .value == 0) {
            print(p);
            edIsLoading.value = false;
            //   createEventError.value = "";
            //   cBlurUBackground.value = true;
            _pickedFile = null;
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
                    Lottie.asset(
                        "assets/animations/check.json", width: Get.height * 0.12,
                        height: Get.height * 0.12,
                        repeat: false,
                        onLoaded: (q) {
                          Future.delayed(Duration(milliseconds: 2500), () {
                            // cBlurUBackground.value = false;
                            Get.offAll(() => CreatorHomepage(),
                                fullscreenDialog: true,
                                transition: Transition.rightToLeftWithFade,
                                duration: const Duration(milliseconds: 1500)
                            );
                          });
                        }),
                    Text(
                        "Publishing your event",
                        style: Stylings.thicSubtitle
                    ),
                    const SizedBox(height: 5,),
                    Text(
                      "Hang tight as we finalize the details for your event!",
                      style: Stylings.body, textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15,),
                  ],
                )
            );
          }
          else if (Get.find<Triventizx>().statusCode.value == 1) {
            // cBlurUBackground.value = true;
            print(p);
            //  createEventError.value = p["message"];
            edIsLoading.value = false;
            _pickedFile = null;
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
                    Icon(Icons.cancel_outlined, size: 40, color: Colors.red,),
                    SizedBox(height: Get.height * 0.01,),
                    Text(
                        "An Error Occurred",
                        style: Stylings.thicSubtitle
                    ),
                    const SizedBox(height: 5,),
                    Text(
                      "${p["message"]}",
                      style: Stylings.body, textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15,),
                    GestureDetector(
                      onTap: () {
                        //cBlurUBackground.value = false;
                        Get.back();
                      },
                      child: Container(
                        alignment: const Alignment(0, 0),
                        width: Get.width,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Stylings.blue,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text("Try again",
                          style: Stylings.body.copyWith(color: Colors.white),),
                      ),
                    )
                  ],
                )
            );
          }
          else {
            // cBlurUBackground.value = true;
            // createEventError.value = "An error occurred";
            edIsLoading.value = false;
            _pickedFile = null;
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
                    Icon(Icons.cancel_outlined, size: 40, color: Colors.red,),
                    SizedBox(height: Get.height * 0.01,),
                    Text(
                        "An Error Occurred",
                        style: Stylings.thicSubtitle
                    ),
                    const SizedBox(height: 5,),
                    Text(
                      "Please try again",
                      style: Stylings.body, textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15,),
                    GestureDetector(
                      onTap: () {
                        //cBlurUBackground.value = false;
                        Get.back();
                      },
                      child: Container(
                        alignment: const Alignment(0, 0),
                        width: Get.width,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Stylings.blue,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text("Try again",
                          style: Stylings.body.copyWith(color: Colors.white),),
                      ),
                    )
                  ],
                )
            );
          }
        });
      }
      else
        {
          // cBlurUBackground.value = true;
          // createEventError.value = "An error occurred";
          edIsLoading.value = false;
          _pickedFile = null;
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
                  Icon(Icons.cancel_outlined, size: 40, color: Colors.red,),
                  SizedBox(height: Get.height * 0.01,),
                  Text(
                      "An Error Occurred",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    "Event banner upload failed",
                    style: Stylings.body, textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15,),
                  GestureDetector(
                    onTap: () {
                      //cBlurUBackground.value = false;
                      Get.back();
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Stylings.blue,
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text("Try again",
                        style: Stylings.body.copyWith(color: Colors.white),),
                    ),
                  )
                ],
              )
          );
      }
    });
    }
    ///if image
    // if(_pickedFile==null){
    //   Map<String,dynamic> payload =  {
    //     // "creatorId": "${Get.find<Triventizx>().userId}",
    //     // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
    //     "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
    //     // "eventId": "${theEvent.id}",
    //     "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
    //     "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
    //     "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
    //     "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
    //     "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
    //     "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
    //     "eventType": "${eEventType.value}",//chk
    //     "eventTag": theEvent.eventTag,
    //     "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
    //     "inviteOnly": theEvent.inviteOnly,
    //     "tickets": theEvent.tickets,
    //     "url": "${theEvent.url}",//chk
    //     "visibility": theEvent.visibility,
    //     "privateVisibilityOptions": theEvent.privateVisibilityOptions,
    //     "publish": 'now',
    //     "publishSchedule": {},
    //     "coupon":theEvent.coupon,
    //     "discount":theEvent.discount,
    //     "expiryDate":theEvent.expiryDate==null?"":"${theEvent.expiryDate}",
    //     "expiryTime":theEvent.expiryTime,
    //     "maxRedemptions": theEvent.maxRedemptions
    //   };
    //   print(payload);
    //   // print(Get.find<Triventizx>().userAccessToken);
    //   EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
    //     if (Get.find<Triventizx>().statusCode.value == 0) {
    //       print(p);
    //       edIsLoading.value = false;
    //       createEventError.value = "";
    //       cBlurUBackground.value=true;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
    //                   onLoaded: (q){
    //                     Future.delayed(Duration(milliseconds: 2500),(){
    //                       cBlurUBackground.value=false;
    //                       Get.offAll(()=>CreatorHomepage(),
    //                           fullscreenDialog: true,
    //                           transition: Transition.rightToLeftWithFade,
    //                           duration: const Duration(milliseconds: 1500)
    //                       );
    //                     });
    //                   }),
    //               Text(
    //                   "Publishing your event",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Hang tight as we finalize the details for your event!",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //             ],
    //           )
    //       );
    //     }
    //     else if(Get.find<Triventizx>().statusCode.value == 1){
    //       cBlurUBackground.value=true;
    //       print(p);
    //       createEventError.value  = p["message"];
    //       edIsLoading.value = false;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 createEventError.value,
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   cBlurUBackground.value=false;
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //     else{
    //       cBlurUBackground.value=true;
    //       createEventError.value  = "An error occurred";
    //       edIsLoading.value = false;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   cBlurUBackground.value=false;
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //   });
    // }
    // else{
    //   EventApiClient().uploadImage(_pickedFile!,eimgUrl).then((i){
    //     if (i == 0) {
    //       print(eimgUrl);
    //       Map<String,dynamic> payload =  {
    //         // "creatorId": "${Get.find<Triventizx>().userId}",
    //         // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
    //         "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
    //         // "eventId": "${theEvent.id}",
    //         "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
    //         "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
    //         "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
    //         "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
    //         "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
    //         "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
    //         "eventType": "${eEventType.value}",//chk
    //         "eventTag": theEvent.eventTag,
    //         "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
    //         "inviteOnly": theEvent.inviteOnly,
    //         "tickets": theEvent.tickets,
    //         "url": "${eimgUrl.value}",//chk
    //         "visibility": theEvent.visibility,
    //         "privateVisibilityOptions": theEvent.privateVisibilityOptions,
    //         "publish": 'now',
    //         "publishSchedule": {},
    //         "coupon":theEvent.coupon,
    //         "discount":theEvent.discount,
    //         "expiryDate":theEvent.expiryDate==null?"":"${theEvent.expiryDate}",  //chk when pages increase
    //         "expiryTime":theEvent.expiryTime,
    //         "maxRedemptions": theEvent.maxRedemptions
    //       };
    //       print(payload);
    //       // print(Get.find<Triventizx>().userAccessToken);
    //       EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
    //         if (Get.find<Triventizx>().statusCode.value == 0) {
    //           print(p);
    //           edIsLoading.value = false;
    //           createEventError.value = "";
    //           cBlurUBackground.value=true;
    //          _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
    //                       onLoaded: (q){
    //                         Future.delayed(Duration(milliseconds: 2500),(){
    //                           cBlurUBackground.value=false;
    //                           Get.offAll(()=>CreatorHomepage(),
    //                               fullscreenDialog: true,
    //                               transition: Transition.rightToLeftWithFade,
    //                               duration: const Duration(milliseconds: 1500)
    //                           );
    //                         });
    //                       }),
    //                   Text(
    //                       "Publishing your event",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     "Hang tight as we finalize the details for your event!",
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                 ],
    //               )
    //           );
    //         }
    //         else if(Get.find<Triventizx>().statusCode.value == 1){
    //           cBlurUBackground.value=true;
    //           print(p);
    //           createEventError.value  = p["message"];
    //           edIsLoading.value = false;
    //           _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //                   SizedBox(height: Get.height*0.01,),
    //                   Text(
    //                       "An Error Occurred",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     createEventError.value,
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                   GestureDetector(
    //                     onTap: (){
    //                       cBlurUBackground.value=false;
    //                       Get.back();
    //                     },
    //                     child: Container(
    //                       alignment: const Alignment(0, 0),
    //                       width: Get.width,
    //                       height: 44,
    //                       decoration:BoxDecoration(
    //                           color: Stylings.blue,
    //                           borderRadius: BorderRadius.circular(8)
    //                       ),
    //                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                     ),
    //                   )
    //                 ],
    //               )
    //           );
    //         }
    //         else{
    //           cBlurUBackground.value=true;
    //           createEventError.value  = "An error occurred";
    //           edIsLoading.value = false;
    //           _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //                   SizedBox(height: Get.height*0.01,),
    //                   Text(
    //                       "An Error Occurred",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     "Please try again",
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                   GestureDetector(
    //                     onTap: (){
    //                       cBlurUBackground.value=false;
    //                       Get.back();
    //                     },
    //                     child: Container(
    //                       alignment: const Alignment(0, 0),
    //                       width: Get.width,
    //                       height: 44,
    //                       decoration:BoxDecoration(
    //                           color: Stylings.blue,
    //                           borderRadius: BorderRadius.circular(8)
    //                       ),
    //                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                     ),
    //                   )
    //                 ],
    //               )
    //           );
    //         }
    //       });
    //     }
    //     else if(i == 1){
    //       edIsLoading.value=false;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "Upload Failed",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //     else{
    //       edIsLoading.value=false;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //   });
    // }
  }



  var otherEventImages = [].obs; //to temporarily hold existing other event images list

  //pick otherImages
  var hasPicked = false.obs; //to ascertain if images have been picked
  RxList<XFile> eimageFileLists = RxList();
  RxList<Map> eImgsBiodata = RxList([]);  //not in use since we are displaying the bio data
  Future<void> ePickMoreImages() async{
    int limit = 5-(otherEventImages.length+eimageFileLists.length);
    hasPicked.value = false;
   if(limit==0){
     Get.snackbar("Limit Exceeded", "You can only have 5 event images");
   }
   else{
     final List<XFile> _theSelected = await _picker.pickMultiImage();
     if(_theSelected.length>limit){
       Get.snackbar("Limit Exceeded", "You can only select up to $limit more event image(s)");
       return;
     }
     else{
       hasPicked.value = true;
      // eimageFileLists.value = _theSelected;
       eimageFileLists.addAll(_theSelected);
       print(eimageFileLists);
     }
   }



    // for(XFile? image in _imageFileLists.take(5)) {
    //   final img = image;
    //   final imgPath = image!.path;
    //   final imgSize = await File(image.path).length()/(1024);
    //   final imgName =  image.name.toUpperCase();
    //   final data = {
    //     "img":img,
    //     "imgPath":imgPath,
    //     "imgSize":imgSize,
    //     "imgName":imgName,
    //   };
    //   imgsBiodata.add(data);
    // }
  }


//to form the imgUrl payload
  List<Url> eimgUrlsMap = [];
  eFormImgUrlMap(List<String> theReturnedUrls){
    eimgUrlsMap=[];
    for(String url in theReturnedUrls){
      final id = theReturnedUrls.indexOf(url)+1;
      final link = url;
      final data = Url(id: id, link: link);
      eimgUrlsMap.add(data);
    }
  }


  //step 2
  eStepTwoSave(Datum theEvent){
   if(ecouponCode.isNotEmpty&&(ecouponMaxUse.value==0||ecouponDiscount.isEmpty||ecouponExpTime.isEmpty||ecouponExpDate.isEmpty)){
    Get.snackbar("Incomplete Details", "Kindly complete the coupon requirements");
    }
    else{
     edIsLoading.value=true;
     if(eimageFileLists.isNotEmpty){
      EventApiClient().uploadMultipleImages(eimageFileLists).then((i){
        if (i.length == eimageFileLists.length) {
          eFormImgUrlMap(i);
          final List<Url> newImgList = [theEvent.url[0],...eimgUrlsMap];
          Map<String,dynamic> payload =  {
            // "creatorId": "${Get.find<Triventizx>().userId}",
            // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
            "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
            // "eventId": "${theEvent.id}",
            "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
            "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
            "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
            "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
            "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
            "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
            "eventType": "${eEventType.value}",//chk
            "eventTag": theEvent.eventTag,
            "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
            "inviteOnly": theEvent.inviteOnly,
            "tickets": theEvent.tickets,
            "url": newImgList,//chk
            "visibility": theEvent.visibility,
            "privateVisibilityOptions": theEvent.privateVisibilityOptions,
            "publish": 'now',
            "publishSchedule": {},
            "coupon": ecouponCode.value.isEmpty?theEvent.coupon:ecouponCode.value,
            "discount":ecouponDiscount.value.isEmpty?theEvent.discount:ecouponDiscount.value,
            "expiryDate":ecouponExpDate.value.isEmpty?"":ecouponExpDate.value,
            "expiryTime":ecouponExpTime.value.isEmpty?theEvent.expiryTime:ecouponExpTime.value,
            "maxRedemptions": ecouponMaxUse.value==0?theEvent.maxRedemptions:ecouponMaxUse.value
          };
          print(payload);

          EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
            if (Get.find<Triventizx>().statusCode.value == 0) {
              print(p);
              edIsLoading.value = false;
              _pickedFile=null;
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
                      Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
                          onLoaded: (q){
                            Future.delayed(Duration(milliseconds: 2500),(){
                              //cBlurUBackground.value=false;
                              Get.offAll(()=>CreatorHomepage(),
                                  fullscreenDialog: true,
                                  transition: Transition.rightToLeftWithFade,
                                  duration: const Duration(milliseconds: 1500)
                              );
                            });
                          }),
                      Text(
                          "Publishing your event",
                          style: Stylings.thicSubtitle
                      ),
                      const SizedBox(height: 5,),
                      Text(
                        "Hang tight as we finalize the details for your event!",
                        style: Stylings.body,textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15,),
                    ],
                  )
              );
            }
            else if(Get.find<Triventizx>().statusCode.value == 1){
              //   cBlurUBackground.value=true;
              print(p);
              //  createEventError.value  = p["message"];
              edIsLoading.value = false;
              _pickedFile=null;
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
                        "${p["message"]}",
                        style: Stylings.body,textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15,),
                      GestureDetector(
                        onTap: (){
                          //   cBlurUBackground.value=false;
                          Get.back();
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
              // cBlurUBackground.value=true;
              // createEventError.value  = "An error occurred";
              edIsLoading.value = false;
              _pickedFile=null;
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
                          //  cBlurUBackground.value=false;
                          Get.back();
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
        else if(i.length<eimageFileLists.length){
          edIsLoading.value=false;
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
                      "Upload Failed",
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
          edIsLoading.value=false;
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

     //no images
     else{
       Map<String,dynamic> payload =  {
         // "creatorId": "${Get.find<Triventizx>().userId}",
         // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
         "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
         // "eventId": "${theEvent.id}",
         "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
         "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
         "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
         "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
         "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
         "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
         "eventType": "${eEventType.value}",//chk
         "eventTag": theEvent.eventTag,
         "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
         "inviteOnly": theEvent.inviteOnly,
         "tickets": theEvent.tickets,
         "url": [theEvent.url[0],...otherEventImages], //chk
         "visibility": theEvent.visibility,
         "privateVisibilityOptions": theEvent.privateVisibilityOptions,
         "publish": 'now',
         "publishSchedule": {},
         "coupon": ecouponCode.value.isEmpty?theEvent.coupon:ecouponCode.value,
         "discount":ecouponDiscount.value.isEmpty?theEvent.discount:ecouponDiscount.value,
         "expiryDate":ecouponExpDate.value.isEmpty?"":ecouponExpDate.value,
         "expiryTime":ecouponExpTime.value.isEmpty?theEvent.expiryTime:ecouponExpTime.value,
         "maxRedemptions": ecouponMaxUse.value==0?theEvent.maxRedemptions:ecouponMaxUse.value
       };
       //print(payload);
       // print(Get.find<Triventizx>().userAccessToken);
       EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
         if (Get.find<Triventizx>().statusCode.value == 0) {
           print(p);
           edIsLoading.value = false;
           //createEventError.value = "";
           // cBlurUBackground.value=true;
           _pickedFile=null;
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
                   Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
                       onLoaded: (q){
                         Future.delayed(Duration(milliseconds: 2500),(){
                           //cBlurUBackground.value=false;
                           Get.offAll(()=>CreatorHomepage(),
                               fullscreenDialog: true,
                               transition: Transition.rightToLeftWithFade,
                               duration: const Duration(milliseconds: 1500)
                           );
                         });
                       }),
                   Text(
                       "Publishing your event",
                       style: Stylings.thicSubtitle
                   ),
                   const SizedBox(height: 5,),
                   Text(
                     "Hang tight as we finalize the details for your event!",
                     style: Stylings.body,textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 15,),
                 ],
               )
           );
         }
         else if(Get.find<Triventizx>().statusCode.value == 1){
           //   cBlurUBackground.value=true;
           print(p);
           //  createEventError.value  = p["message"];
           edIsLoading.value = false;
           _pickedFile=null;
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
                     "${p["message"]}",
                     style: Stylings.body,textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 15,),
                   GestureDetector(
                     onTap: (){
                       //   cBlurUBackground.value=false;
                       Get.back();
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
           // cBlurUBackground.value=true;
           // createEventError.value  = "An error occurred";
           edIsLoading.value = false;
           _pickedFile=null;
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
                       //  cBlurUBackground.value=false;
                       Get.back();
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

   }

    ///if image
    // if(_pickedFile==null){
    //   Map<String,dynamic> payload =  {
    //     // "creatorId": "${Get.find<Triventizx>().userId}",
    //     // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
    //     "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
    //     // "eventId": "${theEvent.id}",
    //     "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
    //     "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
    //     "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
    //     "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
    //     "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
    //     "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
    //     "eventType": "${eEventType.value}",//chk
    //     "eventTag": theEvent.eventTag,
    //     "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
    //     "inviteOnly": theEvent.inviteOnly,
    //     "tickets": theEvent.tickets,
    //     "url": "${theEvent.url}",//chk
    //     "visibility": theEvent.visibility,
    //     "privateVisibilityOptions": theEvent.privateVisibilityOptions,
    //     "publish": 'now',
    //     "publishSchedule": {},
    //     "coupon":theEvent.coupon,
    //     "discount":theEvent.discount,
    //     "expiryDate":theEvent.expiryDate==null?"":"${theEvent.expiryDate}",
    //     "expiryTime":theEvent.expiryTime,
    //     "maxRedemptions": theEvent.maxRedemptions
    //   };
    //   print(payload);
    //   // print(Get.find<Triventizx>().userAccessToken);
    //   EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
    //     if (Get.find<Triventizx>().statusCode.value == 0) {
    //       print(p);
    //       edIsLoading.value = false;
    //       createEventError.value = "";
    //       cBlurUBackground.value=true;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
    //                   onLoaded: (q){
    //                     Future.delayed(Duration(milliseconds: 2500),(){
    //                       cBlurUBackground.value=false;
    //                       Get.offAll(()=>CreatorHomepage(),
    //                           fullscreenDialog: true,
    //                           transition: Transition.rightToLeftWithFade,
    //                           duration: const Duration(milliseconds: 1500)
    //                       );
    //                     });
    //                   }),
    //               Text(
    //                   "Publishing your event",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Hang tight as we finalize the details for your event!",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //             ],
    //           )
    //       );
    //     }
    //     else if(Get.find<Triventizx>().statusCode.value == 1){
    //       cBlurUBackground.value=true;
    //       print(p);
    //       createEventError.value  = p["message"];
    //       edIsLoading.value = false;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 createEventError.value,
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   cBlurUBackground.value=false;
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //     else{
    //       cBlurUBackground.value=true;
    //       createEventError.value  = "An error occurred";
    //       edIsLoading.value = false;
    //       _pickedFile=null;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   cBlurUBackground.value=false;
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //   });
    // }
    // else{
    //   EventApiClient().uploadImage(_pickedFile!,eimgUrl).then((i){
    //     if (i == 0) {
    //       print(eimgUrl);
    //       Map<String,dynamic> payload =  {
    //         // "creatorId": "${Get.find<Triventizx>().userId}",
    //         // "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
    //         "name": eEventName.value.isEmpty?"${theEvent.name}":"${eEventName.value}",
    //         // "eventId": "${theEvent.id}",
    //         "location":eEventLocation.isEmpty? "${theEvent.location}": "${eEventLocation.value}",
    //         "description":eEventDescription.value.isEmpty?"${theEvent.description}":"${eEventDescription.value}",
    //         "startDate": eEventStartDate.value.isEmpty?"${theEvent.startDate}":"${eEventStartDate.value}",
    //         "startTime": eEventStartTime.value.isEmpty?"${theEvent.startTime}": "${eEventStartTime.value}",
    //         "endDate": eEventEndDate.value.isEmpty?"${theEvent.endDate}":"${eEventEndDate.value}",
    //         "endTime": eEventEndTime.value.isEmpty?"${theEvent.endTime}":"${eEventEndTime.value}",
    //         "eventType": "${eEventType.value}",//chk
    //         "eventTag": theEvent.eventTag,
    //         "giftLink":eEventRegistryLink.value.isEmpty?"${theEvent.giftLink}": "${eEventRegistryLink.value}",
    //         "inviteOnly": theEvent.inviteOnly,
    //         "tickets": theEvent.tickets,
    //         "url": "${eimgUrl.value}",//chk
    //         "visibility": theEvent.visibility,
    //         "privateVisibilityOptions": theEvent.privateVisibilityOptions,
    //         "publish": 'now',
    //         "publishSchedule": {},
    //         "coupon":theEvent.coupon,
    //         "discount":theEvent.discount,
    //         "expiryDate":theEvent.expiryDate==null?"":"${theEvent.expiryDate}",  //chk when pages increase
    //         "expiryTime":theEvent.expiryTime,
    //         "maxRedemptions": theEvent.maxRedemptions
    //       };
    //       print(payload);
    //       // print(Get.find<Triventizx>().userAccessToken);
    //       EventApiClient().makePatchRequest(endPoint: "update-event?creatorId=${theEvent.creatorId}&eventId=${theEvent.id}", body:payload).then((p){
    //         if (Get.find<Triventizx>().statusCode.value == 0) {
    //           print(p);
    //           edIsLoading.value = false;
    //           createEventError.value = "";
    //           cBlurUBackground.value=true;
    //          _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
    //                       onLoaded: (q){
    //                         Future.delayed(Duration(milliseconds: 2500),(){
    //                           cBlurUBackground.value=false;
    //                           Get.offAll(()=>CreatorHomepage(),
    //                               fullscreenDialog: true,
    //                               transition: Transition.rightToLeftWithFade,
    //                               duration: const Duration(milliseconds: 1500)
    //                           );
    //                         });
    //                       }),
    //                   Text(
    //                       "Publishing your event",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     "Hang tight as we finalize the details for your event!",
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                 ],
    //               )
    //           );
    //         }
    //         else if(Get.find<Triventizx>().statusCode.value == 1){
    //           cBlurUBackground.value=true;
    //           print(p);
    //           createEventError.value  = p["message"];
    //           edIsLoading.value = false;
    //           _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //                   SizedBox(height: Get.height*0.01,),
    //                   Text(
    //                       "An Error Occurred",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     createEventError.value,
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                   GestureDetector(
    //                     onTap: (){
    //                       cBlurUBackground.value=false;
    //                       Get.back();
    //                     },
    //                     child: Container(
    //                       alignment: const Alignment(0, 0),
    //                       width: Get.width,
    //                       height: 44,
    //                       decoration:BoxDecoration(
    //                           color: Stylings.blue,
    //                           borderRadius: BorderRadius.circular(8)
    //                       ),
    //                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                     ),
    //                   )
    //                 ],
    //               )
    //           );
    //         }
    //         else{
    //           cBlurUBackground.value=true;
    //           createEventError.value  = "An error occurred";
    //           edIsLoading.value = false;
    //           _pickedFile=null;
    //           Get.defaultDialog(
    //               barrierDismissible: true,
    //               title: "",
    //               radius: 12,
    //               backgroundColor: Colors.white,
    //               titlePadding: EdgeInsets.zero,
    //               content: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //                   SizedBox(height: Get.height*0.01,),
    //                   Text(
    //                       "An Error Occurred",
    //                       style: Stylings.thicSubtitle
    //                   ),
    //                   const SizedBox(height: 5,),
    //                   Text(
    //                     "Please try again",
    //                     style: Stylings.body,textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 15,),
    //                   GestureDetector(
    //                     onTap: (){
    //                       cBlurUBackground.value=false;
    //                       Get.back();
    //                     },
    //                     child: Container(
    //                       alignment: const Alignment(0, 0),
    //                       width: Get.width,
    //                       height: 44,
    //                       decoration:BoxDecoration(
    //                           color: Stylings.blue,
    //                           borderRadius: BorderRadius.circular(8)
    //                       ),
    //                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                     ),
    //                   )
    //                 ],
    //               )
    //           );
    //         }
    //       });
    //     }
    //     else if(i == 1){
    //       edIsLoading.value=false;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "Upload Failed",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //     else{
    //       edIsLoading.value=false;
    //       Get.defaultDialog(
    //           barrierDismissible: true,
    //           title: "",
    //           radius: 12,
    //           backgroundColor: Colors.white,
    //           titlePadding: EdgeInsets.zero,
    //           content: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
    //               SizedBox(height: Get.height*0.01,),
    //               Text(
    //                   "An Error Occurred",
    //                   style: Stylings.thicSubtitle
    //               ),
    //               const SizedBox(height: 5,),
    //               Text(
    //                 "Please try again",
    //                 style: Stylings.body,textAlign: TextAlign.center,
    //               ),
    //               const SizedBox(height: 15,),
    //               GestureDetector(
    //                 onTap: (){
    //                   Get.back();
    //                 },
    //                 child: Container(
    //                   alignment: const Alignment(0, 0),
    //                   width: Get.width,
    //                   height: 44,
    //                   decoration:BoxDecoration(
    //                       color: Stylings.blue,
    //                       borderRadius: BorderRadius.circular(8)
    //                   ),
    //                   child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
    //                 ),
    //               )
    //             ],
    //           )
    //       );
    //     }
    //   });
    // }
  }




  //reset  values
resetEValues(){
    _pickedFile = null;
    eimgUrl.value = "";
    eEventName.value="";
    eEventLocation.value="";
    eEventDescription.value="";
    eEventRegistryLink.value="";
    eEventStartDate.value = "";
    eEventStartTime.value = "";
    eEventEndDate.value = "";
    eEventEndTime.value = "";
    eimageFileLists.value = [];
    hasPicked.value = false;
    ecouponCode.value = "";
    ecouponDiscount.value = "";
    ecouponExpDate.value = "";
    ecouponExpTime.value = "";
        ecouponMaxUse.value = 0;
}
  ///step 2 ///THE IMAGEEURLHHASNTBBECHANGEDTOLIST
//   ticketDetailsSave(){
//     //do empty checks
//     if(eEventTickets.first.isEmpty){
//       Get.snackbar("Incomplete Details", "Kindly complete the ticket details");
//     }
//     else {
//       // createEventLoad.value = {
//       //   "creatorId": Get.find<Triventizx>().userId,
//       //   "name": eventName.value,
//       //   "location": eventLocation.value,
//       //   "description": eventDescription.value,
//       //   "startDate": eventStartDate.value,
//       //   "startTime": eventStartTime.value,
//       //   "endDate": eventEndDate.value,
//       //   "endTime": eventEndTime.value,
//       //   "eventType": eventType.value,
//       //   "eventTag": eventTags.value,
//       //   "tickets": eventTickets,
//       //   "url": "",
//       //   "visibility": "",
//       //   "privateVisibilityOptions": {
//       //     "linkAccess": "",
//       //     "passwordProtected": "",
//       //     "password": ""
//       //   },
//       //   "publish": "",
//       //   "publishSchedule": {
//       //     "startDate": "",
//       //     "startTime": ""
//       //   }
//       // };
//       Get.to(()=>Previeweventdetails());
//       print(eEventTickets);
//       //print(createEventLoad);
//     }
//   }
//   var cBlurUBackground = false.obs;
//   var createEventError = "".obs;
// //step 3
//   publishEvent(){
//     print(eEventPrivateVisibilityOptions['password']);
//     print(eEventTag);
//     print(Get.find<Triventizx>().userEmail);
//     //do empty checks
//     if(eEventVisibility.value=='private'&&eEventPrivateVisibilityOptions['passwordProtected']==true&&eEventPrivateVisibilityOptions['password']==''){
//       Get.snackbar("Incomplete Details", "Please enter a password");
//     }
//     else  if(eEventPublishType.value=="schedule"&&escheduleDate.value=='YY-MM-DD'){
//       Get.snackbar("Incomplete Details", "Please choose a schedule date");
//     }
//     else if(ecouponCode.isNotEmpty&&(ecouponMaxUse.value==0||ecouponDiscount.isEmpty||ecouponExpTime.isEmpty||ecouponExpDate.isEmpty)){
//       Get.snackbar("Incomplete Details", "Kindly complete the coupon requirements");
//     }
//     else{
//       edIsLoading.value = true;
//       Map<String,dynamic> payload =  {
//         "creatorId": "${Get.find<Triventizx>().userId}",
//         "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
//         "name": "${eEventName.value}",
//         "location": "${eEventLocation.value}",
//         "description": "${eEventDescription.value}",
//         "startDate": "${eEventStartDate.value}",
//         "startTime": "${eEventStartTime.value}",
//         "endDate": "${eEventEndDate.value}",
//         "endTime": "${eEventEndTime.value}",
//         "eventType": "${eEventType.value}",
//         "eventTag": eEventTag,
//         "giftLink": "${eEventRegistryLink.value}",
//         "inviteOnly": eEventInviteOnly.value,
//         "tickets": eEventTickets,
//         "url": "${eimgUrl.value}",
//         "visibility": "${eEventVisibility.value}",
//         "privateVisibilityOptions": eEventPrivateVisibilityOptions,
//         "publish": "${eEventPublishType}",
//         "publishSchedule": eEventPublishSchedule,
//         "coupon":"${ecouponCode.value}",
//         "discount":"${ecouponDiscount.value}",
//         "expiryDate":"${ecouponExpDate.value}",
//         "expiryTime":"${ecouponExpTime.value}",
//         "maxRedemptions": ecouponMaxUse.value,
//       };
//       print(payload);
//       print(Get.find<Triventizx>().userAccessToken);
//       EventApiClient().makePostRequest(endPoint: "edi-event", body:payload).then((p){
//         if (Get.find<Triventizx>().statusCode.value == 0) {
//           print(p);
//           edIsLoading.value = false;
//           createEventError.value = "";
//           cBlurUBackground.value=true;
//           //  print("yes");
//           Get.defaultDialog(
//               barrierDismissible: true,
//               title: "",
//               radius: 12,
//               backgroundColor: Colors.white,
//               titlePadding: EdgeInsets.zero,
//               content: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Lottie.asset("assets/animations/check.json",width: Get.height*0.12,height: Get.height*0.12,repeat: false,
//                       onLoaded: (q){
//                         Future.delayed(Duration(milliseconds: 2500),(){
//                           cBlurUBackground.value=false;
//                           Get.offAll(()=>CreatorHomepage(),
//                               fullscreenDialog: true,
//                               transition: Transition.rightToLeftWithFade,
//                               duration: const Duration(milliseconds: 1500)
//                           );
//                         });
//                       }),
//                   Text(
//                       "Publishing your event",
//                       style: Stylings.thicSubtitle
//                   ),
//                   const SizedBox(height: 5,),
//                   Text(
//                     "Hang tight as we finalize the details for your event!",
//                     style: Stylings.body,textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 15,),
//                 ],
//               )
//           );
//         }
//         else if(Get.find<Triventizx>().statusCode.value == 1){
//           cBlurUBackground.value=true;
//           print(p);
//           createEventError.value  = p["message"];
//           edIsLoading.value = false;
//           Get.defaultDialog(
//               barrierDismissible: true,
//               title: "",
//               radius: 12,
//               backgroundColor: Colors.white,
//               titlePadding: EdgeInsets.zero,
//               content: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
//                   SizedBox(height: Get.height*0.01,),
//                   Text(
//                       "An Error Occurred",
//                       style: Stylings.thicSubtitle
//                   ),
//                   const SizedBox(height: 5,),
//                   Text(
//                     createEventError.value,
//                     style: Stylings.body,textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 15,),
//                   GestureDetector(
//                     onTap: (){
//                       cBlurUBackground.value=false;
//                       Get.back();
//                     },
//                     child: Container(
//                       alignment: const Alignment(0, 0),
//                       width: Get.width,
//                       height: 44,
//                       decoration:BoxDecoration(
//                           color: Stylings.blue,
//                           borderRadius: BorderRadius.circular(8)
//                       ),
//                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
//                     ),
//                   )
//                 ],
//               )
//           );
//         }
//         else{
//           cBlurUBackground.value=true;
//           createEventError.value  = "An error occurred";
//           edIsLoading.value = false;
//           Get.defaultDialog(
//               barrierDismissible: true,
//               title: "",
//               radius: 12,
//               backgroundColor: Colors.white,
//               titlePadding: EdgeInsets.zero,
//               content: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Icon(Icons.cancel_outlined,size: 40,color: Colors.red,),
//                   SizedBox(height: Get.height*0.01,),
//                   Text(
//                       "An Error Occurred",
//                       style: Stylings.thicSubtitle
//                   ),
//                   const SizedBox(height: 5,),
//                   Text(
//                     "Please try again",
//                     style: Stylings.body,textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 15,),
//                   GestureDetector(
//                     onTap: (){
//                       cBlurUBackground.value=false;
//                       Get.back();
//                     },
//                     child: Container(
//                       alignment: const Alignment(0, 0),
//                       width: Get.width,
//                       height: 44,
//                       decoration:BoxDecoration(
//                           color: Stylings.blue,
//                           borderRadius: BorderRadius.circular(8)
//                       ),
//                       child: Text("Try again",style: Stylings.body.copyWith(color: Colors.white),),
//                     ),
//                   )
//                 ],
//               )
//           );
//         }
//       });
//
//     }
//   }






}