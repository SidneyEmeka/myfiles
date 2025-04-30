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
import 'package:triventiz/services/edit_live_event_controller.dart';

import '../utils/reusables/ticketdetailsfield.dart';
import '../utils/stylings.dart';

class CreateEventController extends GetxController{

  @override
  void onInit() {
    Get.put<EditLiveEventController>(EditLiveEventController());
    super.onInit();
  }
  var cIsLoading = false.obs;
  var cStatusCode = 0.obs;
  RxList<String> eventTypes = RxList(['virtual', 'physical']);
  RxString eventName = RxString("");
  RxString eventLocation = RxString("");

 RxDouble eventLocationLat = RxDouble(51.5074);
 RxDouble eventLocationLng = RxDouble(-0.1278);

  RxString eventDescription = RxString("");
  RxString eventRegistryLink = RxString("");
  RxString eventStartDate = RxString("YY-MM-DD");
  RxString eventStartTime = RxString("10:00AM");
  RxString eventEndDate = RxString("YY-MM-DD");
  RxString eventEndTime = RxString("10:00PM");
  RxString eventType = RxString("physical");
  RxString eventTags = RxString("");
  RxList eventTag = RxList();//to server
  formTags(String tags){
   eventTag.value = tags.split(',');
  }
  RxString imgUrl = RxString("");
  RxList<Map<String,dynamic>> eventTickets = RxList([{}]);
  RxString eventUrl = RxString(""); //nousage
  RxBool eventInviteOnly = RxBool(false); //nousage
  RxString eventVisibility = RxString("public");
  RxMap<String,dynamic> eventPrivateVisibilityOptions = RxMap({
    "linkAccess": false,
    "passwordProtected": false,
    "password": ""});
  RxString eventPublishType = RxString("now");
  RxString scheduleDate = RxString("${DateFormat.yMd().format(DateTime.now())}");
  RxString scheduleTime = RxString("10:00AM");
  RxMap eventPublishSchedule =RxMap({});

  RxString couponCode = RxString("");
  RxString couponDiscount = RxString("");
  RxString couponExpDate = RxString("");
  RxString couponExpTime = RxString("");
  RxInt couponMaxUse = RxInt(0);

  RxBool linkAccess = RxBool(true);
  RxBool passwordProtected = RxBool(false);
  RxString passwordProtectedPassword = RxString("");


//ticket
  RxList<String> ticketTypes = RxList(['Regular', 'General Admission', 'VIP']);//not used anymore
  RxBool isTicketFree = RxBool(false);//no usage



  ///creating new ticket category
  // List to store our widgets
  RxList<Widget> ticketField = RxList([Ticketdetailsfield(0)]);
  RxInt ticketFieldId =RxInt(0);
  void addNewTicketField() {
    ///If it has limit
    // if(ticketField.length>2){
    //   Get.snackbar("Limit Exceeded", "You can only create a maximum of 3 Ticket categories");
    // }
    // else{
    //   ticketFieldId++;
    //   eventTickets.add({});
    //   ticketField.add(Ticketdetailsfield(ticketFieldId.value));
    // }

    ticketFieldId++;
    eventTickets.add({});
    ticketField.add(Ticketdetailsfield(ticketFieldId.value));
    update();
  }





  //image upload
  //File? _image;
  //pick imgBanner
  XFile? _pickedFile;
  XFile? get pickedFile => _pickedFile;
  final _picker = ImagePicker();
  Future<void> pickImage() async{
    _pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if(_pickedFile != null){

    }
  }

  //pick otherImages
  List<XFile?> _imageFileLists = [];
  RxList<Map> imgsBiodata = RxList([]);
  Future<void> pickMoreImages() async{
    _imageFileLists  =  await _picker.pickMultiImage(limit: 5);
    for(XFile? image in _imageFileLists.take(5)) {
      final img = image;
      final imgPath = image!.path;
      final imgSize = await File(image.path).length()/(1024);
      final imgName =  image.name.toUpperCase();
      final data = {
        "img":img,
        "imgPath":imgPath,
        "imgSize":imgSize,
        "imgName":imgName,
      };
      imgsBiodata.add(data);
    }
  }

  //to get the banner and other Images
  List<XFile> _finalImgList = [];
  collateTheFilesTobeSent(){
    _finalImgList = [_pickedFile!];
    for(Map imgData in imgsBiodata){
      _finalImgList.add(imgData['img']);
    }
    //print(_finalImgList);
  }


  ///to server
  //to form the payload
  List<Map<String,dynamic>> imgUrlsMap = [];
  formImgUrlMap(List<String> theReturnedUrls){
    for(String url in theReturnedUrls){
      final id = theReturnedUrls.indexOf(url);
      final link = url;
      final data =  {
        "id":id,
        "link":"$link"
      };
      imgUrlsMap.add(data);
    }
  }
  uploadImagesToCloud(){
    collateTheFilesTobeSent();
    cIsLoading.value=true;
    EventApiClient().uploadMultipleImages(_finalImgList).then((i){
      if (i.length == _finalImgList.length) {
        cIsLoading.value=false;
        formImgUrlMap(i);
       Get.to(()=>Addticketdetails());

      }
      else if(i.length<_finalImgList.length){
        cIsLoading.value=false;
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
        cIsLoading.value=false;
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
  RxBool isSameDayEvent = RxBool(false);
  makeEventSameDay(){
    if(eventStartDate.value=="YY-MM-DD"){
      Get.snackbar("Start Date", "Kindly choose a start date");
      isSameDayEvent.value=false;
    }
    else if(isSameDayEvent.value && eventStartDate.value!="YY-MM-DD"){
      eventEndDate.value = eventStartDate.value;
    }
    else if(!isSameDayEvent.value && eventStartDate.value!="YY-MM-DD"){
      eventEndDate.value = "YY-MM-DD";
    }

  }

//step 1
  basicInfoSave(){
    //do empty checks
    if(eventName.isEmpty||eventLocation.isEmpty||eventDescription.isEmpty||eventStartDate.isEmpty
    ||eventStartTime.isEmpty||eventEndDate.isEmpty||eventEndTime.isEmpty||eventType.isEmpty||eventTags.isEmpty
    ||_pickedFile==null){
      Get.snackbar("Incomplete Details", "Kindly complete the event details");
    }
    else{
      formTags(eventTags.value);
      print(eventTag);
      createEventLoad.value = {
        "creatorId": Get.find<Triventizx>().userId,
        "name": eventName.value,
        "location": eventLocation.value,
        "description": eventDescription.value,
        "startDate": eventStartDate.value,
        "startTime": eventStartTime.value,
        "endDate": eventEndDate.value,
        "endTime": eventEndTime.value,
        "eventType": eventType.value,
        "eventTag": eventTags.value,
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
      };
      uploadImagesToCloud();

    }

  }
  //step 2
ticketDetailsSave(){
    //do empty checks
  if(eventTickets.first.isEmpty){
    Get.snackbar("Incomplete Details", "Kindly complete the ticket details");
  }
  else if(eventTickets.any((aTicket)=>aTicket['description']=='')){
   Get.snackbar("Incomplete Details", "Kindly add ticket description");
  }
  else if(eventTickets.any((aTicket)=>aTicket['quantity']==0)){
    Get.snackbar("Incomplete Details", "Quantity must be at least 1");
  }
  else if(eventTickets.any((aTicket)=>aTicket['quantity']==null)){
    Get.snackbar("Incomplete Details", "Kindly complete the ticket details");
  }
  else {
    createEventLoad.value = {
      "creatorId": Get.find<Triventizx>().userId,
      "name": eventName.value,
      "location": eventLocation.value,
      "description": eventDescription.value,
      "startDate": eventStartDate.value,
      "startTime": eventStartTime.value,
      "endDate": eventEndDate.value,
      "endTime": eventEndTime.value,
      "eventType": eventType.value,
      "eventTag": eventTags.value,
      "tickets": eventTickets,
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
    };
    Get.to(()=>Previeweventdetails());
    //print(eventTickets);
   // print(createEventLoad);
  }
}


  var cBlurUBackground = false.obs;
  var createEventError = "".obs;
//step 3
publishEvent(){
    print(eventPrivateVisibilityOptions['password']);
    print(eventTag);
    print(Get.find<Triventizx>().userEmail);
  //do empty checks
 if(eventVisibility.value=='private'&&eventPrivateVisibilityOptions['passwordProtected']==true&&eventPrivateVisibilityOptions['password']==''){
   Get.snackbar("Incomplete Details", "Please enter a password");
 }
  else  if(eventPublishType.value=="schedule"&&scheduleDate.value=='YY-MM-DD'){
      Get.snackbar("Incomplete Details", "Please choose a schedule date");
    }
  else if(couponCode.isNotEmpty&&(couponMaxUse.value==0||couponDiscount.isEmpty||couponExpTime.isEmpty||couponExpDate.isEmpty)){
    Get.snackbar("Incomplete Details", "Kindly complete the coupon requirements");
 }
  else{
   cIsLoading.value = true;
   Map<String,dynamic> payload =  {
     "creatorId": "${Get.find<Triventizx>().userId}",
     "creatorBusinessName": "${Get.find<Triventizx>().businessName}",
     "name": "${eventName.value}",
     "location": "${eventLocation.value}",
     "description": "${eventDescription.value}",
     "startDate": "${eventStartDate.value}",
     "startTime": "${eventStartTime.value}",
     "endDate": "${eventEndDate.value}",
     "endTime": "${eventEndTime.value}",
     "eventType": "${eventType.value}",
     "eventTag": eventTag,
     "giftLink": "${eventRegistryLink.value}",
     "inviteOnly": eventInviteOnly.value,
     "tickets": eventTickets,
     "url": imgUrlsMap,
     "visibility": "${eventVisibility.value}",
     "privateVisibilityOptions": eventPrivateVisibilityOptions,
     "publish": "${eventPublishType}",
     "publishSchedule": eventPublishSchedule,
     "coupon":"${couponCode.value}",
     "discount":"${couponDiscount.value}",
     "expiryDate":"${couponExpDate.value}",
     "expiryTime":"${couponExpTime.value}",
     "maxRedemptions": couponMaxUse.value,
   };
   print(payload);
   print(Get.find<Triventizx>().userAccessToken);
   EventApiClient().makePostRequest(endPoint: "create-event", body:payload).then((p){
     if (Get.find<Triventizx>().statusCode.value == 0) {
       print(p);
       cIsLoading.value = false;
       createEventError.value = "";
       cBlurUBackground.value=true;
       //  print("yes");
       resetVal();
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
                       cBlurUBackground.value=false;
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
       cBlurUBackground.value=true;
       print(p);
       createEventError.value  = p["message"];
       cIsLoading.value = false;
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
                 createEventError.value,
                 style: Stylings.body,textAlign: TextAlign.center,
               ),
               const SizedBox(height: 15,),
               GestureDetector(
                 onTap: (){
                   cBlurUBackground.value=false;
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
       cBlurUBackground.value=true;
       createEventError.value  = "An error occurred";
       cIsLoading.value = false;
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
                   cBlurUBackground.value=false;
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








resetVal(){
eventTypes = RxList(['virtual', 'physical']);
 eventName = RxString("");
   eventLocation = RxString("");

   eventLocationLat = RxDouble(51.5074);
   eventLocationLng = RxDouble(-0.1278);

   eventDescription = RxString("");
   eventRegistryLink = RxString("");
   eventStartDate = RxString("YY-MM-DD");
   eventStartTime = RxString("10:00AM");
   eventEndDate = RxString("YY-MM-DD");
   eventEndTime = RxString("10:00PM");
   eventType = RxString("physical");
   eventTags = RxString("");
   eventTag = RxList();
   imgUrl = RxString("");
  eventTickets = RxList([{}]);
   eventUrl = RxString(""); //nousage
   eventInviteOnly = RxBool(false); //nousage
   eventVisibility = RxString("public");
   eventPrivateVisibilityOptions = RxMap({
    "linkAccess": false,
    "passwordProtected": false,
    "password": ""});
   eventPublishType = RxString("now");
   scheduleDate = RxString("${DateFormat.yMd().format(DateTime.now())}");
   scheduleTime = RxString("10:00AM");
   eventPublishSchedule =RxMap({});

ticketField = RxList([Ticketdetailsfield(0)]);
ticketFieldId =RxInt(0);

   couponCode = RxString("");
   couponDiscount = RxString("");
   couponExpDate = RxString("");
   couponExpTime = RxString("");
   couponMaxUse = RxInt(0);

   linkAccess = RxBool(true);
   passwordProtected = RxBool(false);
   passwordProtectedPassword = RxString("");
   imgUrlsMap = [];
   _pickedFile = null;
 _imageFileLists = [];
imgsBiodata = RxList([]);
_finalImgList = [];
isSameDayEvent = RxBool(false);
}


///eend
}