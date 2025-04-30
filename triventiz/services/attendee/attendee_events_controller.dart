import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:triventiz/homes/attendeedashbboard/bookedevents/reviewtransferdetails.dart';
import 'package:triventiz/homes/attendeehomepage.dart';
import 'package:triventiz/homes/creatorhomepage.dart';
import 'package:triventiz/utils/paymentfailedpage.dart';
import 'package:triventiz/utils/paymmentsuccesspage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../homes/attendeedashbboard/bookevent/checkout.dart';
import '../../models/attendeealleventsmodel.dart';
import '../../models/attendeeallticketsmodel.dart';
import '../../server/apiclient.dart';
import '../../server/getxserver.dart';
import '../../utils/stylings.dart';

class AttendeeEventsController extends GetxController{
 var aIsLoading = false.obs;
  ///Browse events for attendees
 var allAttendeeEvents = [].obs;
  Future getAttendeeEvents() async {
    print(Get.find<Triventizx>().userId);
    //print(Get.find<Triventizx>().userAccessToken);
    aIsLoading.value=true;
    await EventApiClient().makeGetRequest("browse-events").then((a){
      print(Get.find<Triventizx>().userAccessToken);
     if(Get.find<Triventizx>().statusCode.value == 0){
       print("Error 0 $a");
       final attendeeAllEventsModel = attendeeAllEventsModelFromJson(jsonEncode(a));
       List<Datum> theEvents = attendeeAllEventsModel.data;
       allAttendeeEvents.value = theEvents;
       aIsLoading.value=false;
     }
     else if(Get.find<Triventizx>().statusCode.value == 1){
       print("Error 1 $a");
       aIsLoading.value = false;
     }
     else{
       print("Error 2 $a");
       aIsLoading.value = false;
     }
    });
  }

  ///Booked Tickets for attendees
 var allAttendeeTickets = [].obs;
 Future getBookedTickets() async{
   aIsLoading.value=true;
   await EventApiClient().makeGetRequest("user-bookings/${Get.find<Triventizx>().userId}").then((a){
     if(Get.find<Triventizx>().statusCode.value == 0){
      print(a);
       final attendeeAllTicketsModel = attendeeAllTicketsModelFromJson(jsonEncode(a));
      List<AttendeeTicketDatum> theBookedEvents = attendeeAllTicketsModel.data;
       allAttendeeTickets.value = theBookedEvents;
       print(allAttendeeTickets);
       aIsLoading.value=false;
     }
     else if(Get.find<Triventizx>().statusCode.value == 1){
       print(a);
       aIsLoading.value = false;
     }
     else{
       print(a);
       aIsLoading.value = false;
     }
   });
 }

  ///booking  event///
 ///has limits
//   RxNum ticketTotal = RxNum(0);
//   var tickets = [{
//  "ticketId": "",
//  "eventId": "",
//  "eventName": "",
//  "creator": "",//creator email
//  "ticketType": "",
//  "quantity": 0,
//  "price": 0
// },{
// "ticketId": "",
// "eventId": "",
// "eventName": "",
// "creator": "",//creator email
// "ticketType": "",
// "quantity": 0,
// "price": 0
// },{
// "ticketId": "",
// "eventId": "",
// "eventName": "",
// "creator": "",//creator email
// "ticketType": "",
// "quantity": 0,
// "price": 0
// }]; ///if it has limit
//   var selectedTickets = [];
  ///calculate the total
  //  calcTicketTotal(){
  //    //print(tickets);
  //    ticketTotal.value=( (num.parse(tickets[0]['quantity'].toString()) * num.parse(tickets[0]['price'].toString()) ) + (num.parse(tickets[1]['quantity'].toString()) * num.parse(tickets[1]['price'].toString())) + (num.parse(tickets[2]['quantity'].toString()) * num.parse(tickets[2]['price'].toString())));
  // }
  //check if atleast aticket is selected
  ///Check to be selected
// checkTicketSelected(Widget toWhere){
//      if(tickets[0]['ticketId']==''&&tickets[1]['ticketId']==''&&tickets[2]['ticketId']==''){
//        Get.snackbar("Choose ticket", "Kindly select a ticket at least to proceed");
//      }
//      else{
//        Get.to(()=>toWhere);
//      }
// }



///no limits
 var baseTickets = [].obs;
  var selectedTickets = [];
 double calculateTotal() {
   return baseTickets.fold(0.0, (sum, item) {
     return sum + (item['quantity'] * item['price']);
   });
 }

 checkTicketsToBuy(Widget toWhere){
     if(baseTickets.every((aTick)=>aTick['ticketId']=="")){
       Get.snackbar("Choose ticket", "Kindly select a ticket at least to proceed");
     }
     else{
       Get.to(()=>toWhere);
     }
   }



//checkout details
var firstName = '';
var lastName = '';
var emailAddress = '';
var couponCode = '';
var emErrorCode = ''.obs;
validateEmail(String theEmail, RxString toUpdate){
  if(theEmail.isEmail){
    toUpdate.value='';
  }
  else{
    toUpdate.value = "Invalid email address";
  }
}
//collect selectedTickets
  collectTickets(){
  selectedTickets = [];
  for(//Map ticket in tickets
  var ticket in baseTickets
  ){
    if(ticket["ticketId"]!=""){
      selectedTickets.add(ticket);
    }
  }
  }
//start payment  and pay stripe
Future<void> sendCheckout({required String eventId, required String eventCreator, required String eventName}) async{
  collectTickets();
  if(firstName.isEmpty||lastName.isEmpty||emailAddress.isEmpty){
    Get.snackbar("Incomplete Details", "Kindly fill the required fields");
   // print(selectedTickets);
    //print(calculateTotal()<=0);
  }
  else{
    aIsLoading.value=true;
    if(//ticketTotal.value==0
    calculateTotal()<=0
    ){
      final thePayLoad = {
        "email": "${emailAddress}",
        "firstName": "${firstName}",
        "lastName": "${lastName}",
        "coupon": "${couponCode}",
        "tickets": selectedTickets,
        "eventId": "$eventId",
        "eventName": "$eventName",
        "creator": "$eventCreator",
       // "isFree": true
      };
      print("For freee $thePayLoad");
      await bookTheTicket(thePayLoad).whenComplete((){
        aIsLoading.value=false;
      });
    }
    else{
      final thePayLoad = {
        "email": "${emailAddress}",
        "firstName": "${firstName}",
        "lastName": "${lastName}",
        "coupon": "${couponCode}",
        "tickets": selectedTickets,
        "eventId": "$eventId",
        "eventName": "$eventName",
        "creator": "$eventCreator",
        //"isFree": false
      };
      print(thePayLoad);
      ApiClient().makePostRequest(endPoint: 'start-payment', body: thePayLoad).then((p) async {
        if (Get.find<Triventizx>().statusCode.value == 0) {
          print(p);
          final secretkey = p['data']['secret'];
          final publishkey = p['data']['publishableKey'];
          final amountReturned = p['data']['totalAmount'];
          // Stripe.publishableKey  =  publishkey;
          aIsLoading.value=false;
          // await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
          //   paymentIntentClientSecret: secretkey,
          //   merchantDisplayName: "3ventiz",
          //     appearance: PaymentSheetAppearance(
          //       colors: PaymentSheetAppearanceColors(
          //         background: Colors.white,
          //         componentBackground: Colors.grey[100],
          //         primaryText: Colors.black,
          //         secondaryText: Colors.black,
          //         componentText: Colors.black,
          //         placeholderText: Colors.grey[700],
          //         componentBorder: Colors.grey[100],
          //         componentDivider: Colors.grey[300],
          //       ),
          //       shapes: PaymentSheetShape(
          //         borderRadius: 12,
          //         borderWidth: 1,
          //       ),
          //       primaryButton: PaymentSheetPrimaryButtonAppearance(
          //         shapes: PaymentSheetPrimaryButtonShape(
          //           blurRadius: 0,
          //         ),
          //         colors: PaymentSheetPrimaryButtonTheme(
          //           light: PaymentSheetPrimaryButtonThemeColors(
          //             background: Stylings.blue
          //           )
          //         )
          //       )),
          // ));
          await processPayment(secKey: secretkey,pubKey: publishkey, payload: thePayLoad);
        }
        else if(Get.find<Triventizx>().statusCode.value == 1){
          // print("for niggas $p");
          aIsLoading.value=false;
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
                      "Oops!",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    p['message'],
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
          print(p);
          aIsLoading.value=false;
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

  }
} //here

//processPayment

Future<void> processPayment({required String pubKey, required String secKey, required Map<String,dynamic> payload})  async{
  try{
    Stripe.publishableKey  =  pubKey;
    await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: secKey,
      merchantDisplayName: "3ventiz",
      appearance: PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            background: Colors.white,
            componentBackground: Colors.grey[100],
            primaryText: Colors.black,
            secondaryText: Colors.black,
            componentText: Colors.black,
            placeholderText: Colors.grey[700],
            componentBorder: Colors.grey[100],
            componentDivider: Colors.grey[300],
          ),
          shapes: PaymentSheetShape(
            borderRadius: 12,
            borderWidth: 1,
          ),
          primaryButton: PaymentSheetPrimaryButtonAppearance(
              shapes: PaymentSheetPrimaryButtonShape(
                blurRadius: 0,
              ),
              colors: PaymentSheetPrimaryButtonTheme(
                  light: PaymentSheetPrimaryButtonThemeColors(
                      background: Stylings.blue
                  )
              )
          )),
    ));
    await Stripe.instance.presentPaymentSheet();
    //book event
    await bookTheTicket(payload);
  }catch(e){
    if(e is StripeException){
      print(e.toString());
      Get.to(()=>Paymentfailedpage());
    }
    else{
      print("Not stripe  $e");
      Get.to(()=>Paymentfailedpage());
    }
  }
}
//book the ticket
var blurCheckoutBackground = false.obs;
Future<void> bookTheTicket(Map<String,dynamic> payload) async{
  print(payload);
  blurCheckoutBackground.value = true;
  ApiClient().makePostRequest(endPoint: 'book-ticket', body: payload).then((b){
    if (Get.find<Triventizx>().statusCode.value == 0) {
      print("Booking succesful $b");
      blurCheckoutBackground.value = false;
      Get.off(()=>Paymmentsuccesspage());
    }
    else if(Get.find<Triventizx>().statusCode.value == 1){
      print("for niggas $b");
      blurCheckoutBackground.value = false;
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
                  "Ticket Booking Failed",
                  style: Stylings.thicSubtitle
              ),
              Text(
                  "$b",
                  style: Stylings.body
              ),
              const SizedBox(height: 5,),
              GestureDetector(
                onTap: (){
                  Get.back();
                 bookTheTicket(payload);
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
      blurCheckoutBackground.value = false;
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
                  "Ticket Booking Failed",
                  style: Stylings.thicSubtitle
              ),
              const SizedBox(height: 5,),
              GestureDetector(
                onTap: (){
                  Get.back();
                  bookTheTicket(payload);
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
} //here


///Ticket Transfer///
var recipientFullName = "".obs;
var recipientPhone = "".obs;
var recipientPhoneError = "".obs;
var recipientEmailAddress = "".obs;
var recipientEmailAddressError = "".obs;
RxMap<String,dynamic> ticketToTransfer = RxMap({});
isTransferDetailsComplete(AttendeeTicketDatum theEventToTrsf, String bookingID){
  if(bookingID.isEmpty||recipientFullName.isEmpty||recipientPhone.isEmpty||recipientEmailAddress.isEmpty||recipientPhoneError.value.isNotEmpty||recipientEmailAddressError.value.isNotEmpty){
    Get.snackbar("Incomplete Details", "Kindly fill the required details");
  }
  else{
Get.to(()=>Reviewtransferdetails(theEventToTrsf: theEventToTrsf, bookingID: bookingID,));
  }
}


var giftIsLoading = false.obs;
giftTheTicket({required String bookingId,required String eventName,required String eventCreator}){
  giftIsLoading.value = true;
  var thePayload = {
    "bookingId": "$bookingId",
    "senderId": "${Get.find<Triventizx>().userId}",
    "senderEmail": "${Get.find<Triventizx>().userEmail}",
    "fullName": "$recipientFullName",
    "email": "$recipientEmailAddress",
    "phone": "$recipientPhone",
    "eventName": "$eventName",
    "creator": "$eventCreator",
  };
  print(thePayload);
  ApiClient().makePostRequest(endPoint: "gift-ticket", body: thePayload).then((g){
    if (Get.find<Triventizx>().statusCode.value == 0) {
      print("Transfer succesful $g");
      giftIsLoading.value = false;
      Get.offAll(()=>Attendeehomepage(initialIndex: 0,));
    }
    else if(Get.find<Triventizx>().statusCode.value == 1){
      print("for niggas $g");
      giftIsLoading.value = false;
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
                  "Ticket Gifting Failed",
                  style: Stylings.thicSubtitle
              ),
              Text(
                  "${g['message']}",
                  style: Stylings.greyBody
              ),
              const SizedBox(height: 5,),
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
      giftIsLoading.value = false;
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
                  "Ticket Booking Failed",
                  style: Stylings.thicSubtitle
              ),
              const SizedBox(height: 5,),
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


/////Getting Creators Info/////
  ///Followers///
  var hfolIsLoading = false.obs;
  var hostFollowers = [].obs;
  //get all followers
  Future<void> getHostFollowers(String creatorId) async{
    hfolIsLoading.value=true;
    await ApiClient().makeGetRequest("get-followers/$creatorId").then((f){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(f);
        hfolIsLoading.value = false;
        hostFollowers.value = f['data'];
        isFollowing.value=checkIfIdExists(Get.find<Triventizx>().userId);
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print("follower error $f");
        hfolIsLoading.value = false;
      }
      else{
        print(f);
        hfolIsLoading.value = false;
      }
    });
  }
  //get host user data
  var isCreatorDataLoading = false.obs;
  var hostUserData = {}.obs;
  var hostBio =''.obs;
  Future<void> getHostData(String creatorId) async{
    isCreatorDataLoading.value=true;
    await ApiClient().makeGetRequest("user/$creatorId").then((f){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(f);
        isCreatorDataLoading.value = false;
        hostUserData.value = f['data'];
        hostBio.value = f['data']['bio']??'';
        getHostFollowers(creatorId);
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print("follower error $f");
        isCreatorDataLoading.value = false;
      }
      else{
        print(f);
        isCreatorDataLoading.value = false;
      }
    });
  }
  //check if should follow or unfollow
  var isFollowing = false.obs;
  bool checkIfIdExists(String idToCheck) {
    return hostFollowers.any((user) => user['id'] == idToCheck);
  }
  //follow a host
  var toFollowOrUnfollowisLoading =  false.obs;
  Future followHost(String creatorId) async{
    print('foll');
    toFollowOrUnfollowisLoading.value=true;
    await ApiClient().makeGetRequest("follow/$creatorId").then((f){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(f);
        getHostFollowers(creatorId);
        toFollowOrUnfollowisLoading.value = false;
        isFollowing.value=checkIfIdExists(Get.find<Triventizx>().userId);
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print("toFollow error $f");
        toFollowOrUnfollowisLoading.value = false;
      }
      else{
        print(f);
        toFollowOrUnfollowisLoading.value = false;
      }
    });
  }
  //unfollow a host
  Future unfollowHost(String creatorId) async{
    print('unfoll');
    toFollowOrUnfollowisLoading.value=true;
    await ApiClient().makeGetRequest("unfollow/$creatorId").then((f){
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(f);
        getHostFollowers(creatorId);
        toFollowOrUnfollowisLoading.value = false;
        isFollowing.value=checkIfIdExists(Get.find<Triventizx>().userId);
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print("toFollow error $f");
        toFollowOrUnfollowisLoading.value = false;
      }
      else{
        print(f);
        toFollowOrUnfollowisLoading.value = false;
      }
    });
  }
  //get Creators events
  var hostEvents = [];
 getHostEvents(String creatorId){
  hostEvents=[];
  for(Datum hostEvent in allAttendeeEvents){
    hostEvents.addIf(creatorId==hostEvent.creatorId, hostEvent);
  }
 // print(hostEvents.length);
}

///SOCIAL LINKS LAUNCHER
launchHostUrl(String url, String who, BuildContext context) async{
   if(url==""){
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         // shape: RoundedRectangleBorder(
         //     borderRadius: BorderRadius.vertical(top: Radius.circular(15))
         // ),
         backgroundColor: Stylings.blue,
         content: Text('$who not available',style: Stylings.subTitles.copyWith(color: Colors.white,fontSize: 11),),
         duration: Duration(seconds: 2),
       ),
     );
   }
   else if(url.contains('https')){
     final Uri parsedUrl = Uri.parse(url);
     if (!await launchUrl(
       parsedUrl,
       mode: LaunchMode.externalApplication,
     )) {
       print('Could not launch $url');
     }
   }
   else{
     final Uri parsedUrl = Uri.parse("https://$url");
     if (!await launchUrl(
       parsedUrl,
       mode: LaunchMode.externalApplication,
     )) {
       //print('Could not launch $url');
     }
   }

}





 //END
}