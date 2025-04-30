 import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:triventiz/homes/attendeehomepage.dart';
import 'package:triventiz/homes/creatordashboard/creatorprofile.dart';
import 'package:triventiz/homes/creatordashboard/creatorsettings/payouts/creatorpayoutdetails.dart';
import 'package:triventiz/server/apiclient.dart';
import 'package:triventiz/server/getxserver.dart';

import '../homes/creatorhomepage.dart';
import '../utils/stylings.dart';

class SettingsController extends GetxController{

  RxBool setAllowLocation = RxBool(false);


  RxBool setIsLoading = RxBool(false);


  ///Followers///
  var folIsLoading = false.obs;
  var creatorFollowers = [].obs;
  //get all followers
  Future<void> getAllFollowers(String creatorId) async{
    folIsLoading.value=true;
   await ApiClient().makeGetRequest("get-followers/$creatorId").then((f){
     if (Get.find<Triventizx>().statusCode.value == 0) {
     //  print(f);
       folIsLoading.value = false;
       creatorFollowers.value = f['data'];
     }
     else if(Get.find<Triventizx>().statusCode.value == 1){
       //print("follower error $f");
       folIsLoading.value = false;
     }
     else{
      // print(f);
       folIsLoading.value = false;
     }
   });
  }




  ///payouts///
  RxList<String> currencies = RxList(["USD","NGN","GBP","CAD","EUR"]); //not used anymore
  RxString country = RxString("");
  RxString countryFlag = RxString("");
  RxString currency = RxString("GBP");//not used annymore
  RxString holder = RxString("");
  RxString firstName = RxString("");
  RxString lastName = RxString("");
  RxString address = RxString("");
  RxString city = RxString("");
  RxString postalCode = RxString("");
  RxString holderCountry = RxString("");
  RxString accountType = RxString("");
  RxString bankName = RxString("");
  RxString sortCode = RxString("");
  RxString accountNumber = RxString("");
  RxBool useAsDefaultAcct = RxBool(false);

  RxString sortCodeError = RxString("");
  RxString accountNumberError = RxString("");
  doesSortCodeMatch(String toCheck){
    if(!(toCheck==sortCode.value)){
      sortCodeError.value = "Doesn't match";
    }
    else if(toCheck==sortCode.value){
      sortCodeError.value="match";
    }
  }
  doesAcctNumberMatch(String toCheck){
    if(!(toCheck==accountNumber.value)){
      accountNumberError.value = "Doesn't match";
    }
    else if(toCheck==accountNumber.value){
      accountNumberError.value="match";
    }
  }

  ///To server
  mapBankDetails(BuildContext context){
    if(firstName.isEmpty||lastName.isEmpty||city.isEmpty||postalCode.isEmpty||holderCountry.isEmpty||bankName.isEmpty||sortCode.isEmpty||accountNumber.isEmpty){
     Get.snackbar("Incomplete", "Kindly enter the required");

    }
    else{
      if(sortCodeError == "match" && accountNumberError=="match"){
        setIsLoading.value = true;
       final theBankDetaills = {
          "email": "${Get.find<Triventizx>().userEmail}",
          "country":"United Kingdom",
          "countryCurrency":"GBP",
          //"countryCurrency":"${currency.value}",
          "owner":"${holder.value}",
          "firstName":"${firstName.value}",
          "lastName":"${lastName.value}",
          "address":"${address.value}",
          "city":"${city.value}",
          "postalCode":"${postalCode.value}",
          "countryAddress":"${holderCountry.value}",
          "accountType":"${accountType.value}",
          "bankName":"${bankName.value}",


          "sortCode":int.parse(sortCode.value),
          "accountNumber":int.parse(accountNumber.value),
         "isDefault" :  useAsDefaultAcct.value
        };
        //print(theBankDetaills);
      PaymentApiClient().makePostRequest(endPoint: "create-payout", body: theBankDetaills).then((b){
        if(Get.find<Triventizx>().statusCode.value == 0){
          //print(b);
          setIsLoading.value = false;
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
                          // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>CreatorHomepage(initialIndex: 0,)));
                          Get.offAll(()=> CreatorHomepage(initialIndex: 0,));
                        });
                      }),
                  Text(
                      "Saving Details...",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    "Hang tight as we collect your payout details!",
                    style: Stylings.body,textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15,),
                ],
              )
          );
        }
        else if(Get.find<Triventizx>().statusCode.value == 1){
          //print(b);
          setIsLoading.value = false;
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
                    b['message'],
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
          //print(b);
          setIsLoading.value = false;
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
      else{
        Get.snackbar("Incomplete", "Kindly fill the required correctly");
      }

    }
  }


  ///Get Payout
 RxMap<String,dynamic> creatorPayout = RxMap({});
Future<void> getPayoutAcct() async{
    setIsLoading.value=true;
    await  PaymentApiClient().makeGetRequest('get-payout/${Get.find<Triventizx>().userId}').then((p){
      if(Get.find<Triventizx>().statusCode.value == 0){
        //print(p);
        setIsLoading.value = false;
        creatorPayout.value = p['data'];
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        //print(p);
        setIsLoading.value = false;
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
        //print(p);
        setIsLoading.value = false;
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

///Password reset
  //password validation
  var cUserPassword = "".obs;
  var cHidePassword = true.obs;
  var cHasAllcharacters = false.obs;
  var cHasUpperCase = false.obs;
  var cHasLowerCase = false.obs;
  var cHasAnumber = false.obs;
  var cHasSpecialCharacter = false.obs;
  var cAllChecked = false.obs;
  var ceErrorText = "".obs;
  var cOldPassword = "".obs;


  passwordInputFomatter(String pass) {
    if (pass.length > 7) {
      cHasAllcharacters.value = true;
    } else if (pass.length < 8) {
      cHasAllcharacters.value = false;
    }
    if (pass.contains(RegExp(r'[A-Z]'))) {
      cHasUpperCase.value = true;
    } else if (!pass.contains(RegExp(r'[A-Z]'))) {
      cHasUpperCase.value = false;
    }
    if (pass.contains(RegExp(r'[a-z]'))) {
      cHasLowerCase.value = true;
    } else if (!pass.contains(RegExp(r'[a-z]'))) {
      cHasLowerCase.value = false;
    }
    if (pass.contains(RegExp(r'[0-9]'))) {
      cHasAnumber.value = true;
    } else if (!pass.contains(RegExp(r'[0-9]'))) {
      cHasAnumber.value = false;
    }
    if (pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      cHasSpecialCharacter.value = true;
    } else if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      cHasSpecialCharacter.value = false;
    }
    //if all checks
    if (cHasAllcharacters.value &&
        cHasUpperCase.value &&
        cHasLowerCase.value &&
        cHasAnumber.value &&
        cHasSpecialCharacter.value) {
      cUserPassword.value = pass;
      //print(userPassword.value);
    }
    //if any doesn't check
    else if (!cHasAllcharacters.value ||
        !cHasUpperCase.value ||
        !cHasLowerCase.value ||
        !cHasAnumber.value ||
        !cHasSpecialCharacter.value) {
      cUserPassword.value = "";

      //print(userPassword.value);
    }
  }

  var confirmPassErrorText = "".obs;

  confirmPassword(String confirmPass) {
    if (confirmPass == cUserPassword.value) {
      cAllChecked.value = true;
      ceErrorText.value = "";
    } else {
      cAllChecked.value = false;
      ceErrorText.value = "Password doesn't match";
    }
  }

  changePassword(BuildContext context){

    setIsLoading.value = true;
    final thePayload = {
      "password": {
        "newPassword": "$cUserPassword",
        "oldPassword": "$cOldPassword"
      }
    };
    //print(thePayload);
    ApiClient().makePatchRequest(endPoint: "update-user/${Get.find<Triventizx>().userId}", body: thePayload).then((a){
      if(Get.find<Triventizx>().statusCode.value == 0){
        //print(a);
        setIsLoading.value = false;
        Get.defaultDialog(
            barrierDismissible: false,
            title: "",
            radius: 12,
            backgroundColor: Colors.white,
            titlePadding: EdgeInsets.zero,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/check-circle-0 1.png"),
                  SizedBox(height: Get.height*0.01,),
                  Text(
                      "Password reset successful!",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    "Your password has been successfully reset. You're now ready to explore and enjoy fantastic events!",
                    style: Stylings.body.copyWith(fontSize: 10),textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15,),
                  GestureDetector(
                    onTap: (){
                      Get.find<Triventizx>().userRole.value=="attendee"?
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Attendeehomepage(initialIndex: 0,)))
                          :   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CreatorHomepage(initialIndex: 0,)));
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration:BoxDecoration(
                          color: Stylings.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text("Proceed to Home",style: Stylings.thicSubtitle.copyWith(color: Color(0xFF05045F),fontSize: 11),),
                    ),
                  )
                ],
              ),
            )
        );
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        //print(a);
        setIsLoading.value = false;
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
                  a['message'],
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
        print(a);
        setIsLoading.value = false;
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


  ///2fa
setTwoFA(){
    if(Get.find<Triventizx>().mfa.value){
      Get.snackbar("Enabled", "Two-factor authentication has been enabled");
    }
    else{
      Get.snackbar("Disabled", "Two-factor authentication has been disabled");
    }
}


///Event Host Profile
var eBio = '';
var eBusinessName = '';
var eIndusty = [];
updateEventProfileNameIndustryBio(BuildContext context){
  setIsLoading.value=true;
  final thePayload = {
    "businessName": eBusinessName.isEmpty?"${Get.find<Triventizx>().businessName}":"$eBusinessName",
    "industry": eIndusty.isEmpty?Get.find<Triventizx>().businessIndustryList:eIndusty,
    "bio": eBio.isEmpty?"${Get.find<Triventizx>().bio}":eBio,
  };
  ApiClient().makePatchRequest(endPoint: 'update-user/${Get.find<Triventizx>().userId}', body: thePayload).then((u){
    if(Get.find<Triventizx>().statusCode.value == 0){
      print(u);
      setIsLoading.value = false;
      Get.defaultDialog(
          barrierDismissible: false,
          title: "",
          radius: 12,
          backgroundColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/images/check-circle-0 1.png"),
                SizedBox(height: Get.height*0.01,),
                Text(
                    "Profile update successful!",
                    style: Stylings.thicSubtitle
                ),
                const SizedBox(height: 5,),
                Text(
                  "Your event page has been successfully updated. You're now ready to explore and enjoy fantastic events!",
                  style: Stylings.body.copyWith(fontSize: 10),textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CreatorHomepage(initialIndex: 0,)));
                    Get.offAll(()=>CreatorHomepage(initialIndex: 0,));
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration:BoxDecoration(
                        color: Stylings.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text("Proceed to Home",style: Stylings.thicSubtitle.copyWith(color: Color(0xFF05045F),fontSize: 11),),
                  ),
                )
              ],
            ),
          )
      );
    }
    else if(Get.find<Triventizx>().statusCode.value == 1){
      print(u);
      setIsLoading.value = false;
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
                u['message'],
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
      print(u);
      setIsLoading.value = false;
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

var eBusinessWebsite = '';
var eBusinessFacebook = '';
var eBusinessInstagram = '';
var eBusinessX = '';
  updateEventProfileLinks(BuildContext context){
    setIsLoading.value=true;
    final thePayload = {
      "website": eBusinessWebsite.isEmpty?"${Get.find<Triventizx>().businessWebsite}":"$eBusinessWebsite",
      "instagram": eBusinessInstagram.isEmpty?"${Get.find<Triventizx>().businessInstagram}":"$eBusinessInstagram",
      "x": eBusinessX.isEmpty?"${Get.find<Triventizx>().businessX}":"$eBusinessX",
      "facebook": eBusinessFacebook.isEmpty?"${Get.find<Triventizx>().businessFacebook}":"$eBusinessFacebook"
    };
    ApiClient().makePatchRequest(endPoint: 'update-user/${Get.find<Triventizx>().userId}', body: thePayload).then((u){
      if(Get.find<Triventizx>().statusCode.value == 0){
        print(u);
        setIsLoading.value = false;
        Get.defaultDialog(
            barrierDismissible: false,
            title: "",
            radius: 12,
            backgroundColor: Colors.white,
            titlePadding: EdgeInsets.zero,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/check-circle-0 1.png"),
                  SizedBox(height: Get.height*0.01,),
                  Text(
                      "Profile update successful!",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    "Your event page has been successfully updated. You're now ready to explore and enjoy fantastic events!",
                    style: Stylings.body.copyWith(fontSize: 10),textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15,),
                  GestureDetector(
                    onTap: (){
                    //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CreatorHomepage(initialIndex: 0,)));
                      Get.offAll(()=>CreatorHomepage(initialIndex: 0,));
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration:BoxDecoration(
                          color: Stylings.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text("Proceed to Home",style: Stylings.thicSubtitle.copyWith(color: Color(0xFF05045F),fontSize: 11),),
                    ),
                  )
                ],
              ),
            )
        );
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print(u);
        setIsLoading.value = false;
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
                  u['message'],
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
        print(u);
        setIsLoading.value = false;
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

  ///Legal Docs
//var communityGuidelines = "".obs;
var termsOfUse = """Updated: April 4, 2025
1. Acceptance of Terms
By downloading, installing, accessing, or using the 3ventiz Limited event management mobile application (the "App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, you may not access or use the App.  
2. Use of the App
3ventiz is a platform designed to help users discover, plan, and manage events. You may use the App to:
• Browse and search for events.
• View event details, including dates, times, locations, and descriptions.
• Purchase tickets for events.
• RSVP to events.
• Communicate with event organizers and other attendees.
• Utilize planning tools provided within the App.
• Save and manage your favorite events.
You agree to use the App only for lawful purposes and in a manner that does not infringe the rights of, restrict, or inhibit anyone else's use and enjoyment of the App.  
3. User Accounts
To access certain features of the App, you may be required to create a user account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate and complete information when creating your account and to update your information as necessary. You are responsible for notifying us immediately of any unauthorized access to or use of your account.  
4. Content and Conduct
You are solely responsible for any content you post, upload, or otherwise transmit through the App ("User Content"). You agree not to post User Content that is:
• Unlawful, harassing, libelous, abusive, threatening, harmful, vulgar, obscene, or otherwise objectionable.
• Infringing on the intellectual property rights of others.
• Containing viruses, malware, or other harmful code.
• Misleading or fraudulent.
• Used for spamming or unauthorized advertising.
3ventiz Limited reserves the right to remove any User Content that violates these Terms or is otherwise deemed inappropriate.
5. Intellectual Property
The App and its original content (excluding User Content), features, and functionality are and will remain the exclusive property of 3ventiz Limited and its licensors. The App is protected by copyright, trademark, and other laws. You may not modify, reproduce, distribute, create derivative works of, publicly display, or in any way exploit any of the content or software of the App without the prior written consent of 3ventiz Limited.  
6. Third-Party Links and Services
The App may contain links to third-party websites or services that are not owned or controlled by 3ventiz Limited. 3ventiz has no control over and assumes no responsibility for the content, privacy policies, or practices of any third-party websites or services. You acknowledge and agree that 3ventiz Limited shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods, or services available on or through any such third-party websites or services.  
7. Disclaimer of Warranties
THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND ANY WARRANTIES ARISING OUT OF COURSE OF DEALING OR USAGE OF TRADE. EVENTSPARK DOES NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, SECURE, OR FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.  
8. Limitation of Liability
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL 3VENTIZ LIMITED, ITS AFFILIATES, DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, SUPPLIERS, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOST PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES) ARISING OUT OF OR RELATING TO YOUR ACCESS TO OR USE OF, OR INABILITY TO ACCESS OR USE, THE APP, WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), STATUTE, OR ANY OTHER LEGAL THEORY, WHETHER OR NOT EVENTSPARK HAS BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE. IN NO EVENT SHALL 3VENTIZ LIMITED AGGREGATE LIABILITY TO YOU FOR ALL CLAIMS ARISING OUT OF OR RELATING TO THE APP EXCEED THE AMOUNT YOU PAID, IF ANY, TO 3VENTIZ LIMITED FOR ACCESSING OR USING THE APP IN THE TWELVE (12) MONTHS PRIOR TO THE EVENT GIVING RISE TO THE LIABILITY.  
9. Indemnification
You agree to defend, indemnify, and hold harmless 3ventiz Limited, its affiliates, directors, officers, employees, agents, suppliers, and licensors from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees) arising from: (i) your use of and access to the App; (ii) your violation of any term of these Terms; (iii) your violation of any third-party right, including without limitation any right of privacy or intellectual property rights; (iv) your violation of any applicable law, rule, or regulation; (v) your User Content; or (vi) any other party's access and use of the App with your unique username, password, or other appropriate security code.  
10. Governing Law and Dispute Resolution
These Terms shall be governed by and construed in accordance with the laws of England and Wales, without regard to its conflict of law provisions. Any dispute arising out of or relating to these Terms or the App shall be subject to the exclusive jurisdiction of the courts located in Bristol, England.  
11. Changes to These Terms
3ventiz Limited reserves the right to modify or revise these Terms at any time by posting the updated Terms within the App. Your continued use of the App after any such changes constitutes your acceptance of the new Terms. It is your responsibility to review these Terms periodically for any changes.  
12. Contact Us
If you have any questions about these Terms, please contact us at:  
Email: admin@3ventiz.co.uk
 Address: [3ventiz Limited, Bristol, United Kingdom]""".obs;
var privacyPolicy = """Last Updated: April 4, 2025
1. Introduction
3ventiz Limited ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your personal information when you use our mobile application (the "App"). Please read this Privacy Policy carefully.  
2. Information We Collect
We may collect the following types of personal information from you:
• Account Information: When you create an account, we collect your name, email address, password, and optionally, your phone number and profile picture.  
• Profile Information: You may choose to provide additional information in your profile, such as your interests, location, and social media links.
• Usage Data: We collect information about how you use the App, including the events you browse, tickets you purchase, events you RSVP to, your interactions with other users, and the features you use.
• Device Information: We collect information about your mobile device, including your device type, operating system, unique device identifiers, IP address, and mobile network information.
• Location Data: With your consent, we may collect your device's precise location to provide you with location-based event recommendations and features. You can manage your location sharing preferences in your device settings.  
• Communications: We may collect information contained in your communications with us, such as support requests and feedback.
• Payment Information: If you purchase tickets through the App, we use third-party payment processors to handle your payment information securely. We do not directly store your full credit card details.
3. How We Use Your Information
We may use your personal information for the following purposes:
• To provide and maintain the App and its features.  
• To personalize your experience and provide tailored event recommendations.
• To process your ticket purchases and RSVPs.
• To facilitate communication between you and event organizers or other attendees (with your consent).
• To send you notifications and updates about events you are interested in.
• To respond to your inquiries and provide customer support.
• To analyze App usage and trends to improve our services.
• To detect, prevent, and address technical issues, fraud, and abuse.
• To comply with applicable laws and regulations.
• For marketing and promotional purposes (with your consent, where required by law).
4. How We Share Your Information
We may share your personal information with the following categories of recipients:
• Event Organizers: When you purchase tickets for or RSVP to an event, we will share your relevant information (e.g., name, email address) with the event organizer for event management purposes.
• Other Users: If you choose to interact with other users through the App (e.g., through messaging features), your profile information and communications may be visible to them.
• Service Providers: We may share your information with third-party service providers who assist us with various functions, such as payment processing, data analytics, email delivery, and hosting services. These providers are contractually obligated to protect your information.  
• Business Transfers: In the event of a merger, acquisition, or sale of all or a portion of our assets, your information may be transferred to the acquiring entity.  
• Legal Compliance: We may disclose your information if required to do so by law or in response to a valid legal request, such as a court order or government investigation.  
• With Your Consent: We may share your information with third parties for other purposes with your explicit consent.
5. Your Rights and Choices
You have certain rights regarding your personal information, including:
• Access: You can request access to the personal information we hold about you.  
• Correction: You can request that we correct any inaccurate or incomplete personal information.
• Deletion: You can request that we delete your personal information, subject to certain exceptions.  
• Objection: You can object to the processing of your personal information for certain purposes, such as direct marketing.  
• Restriction: You can request that we restrict the processing of your personal information in certain circumstances.
You can exercise these rights by contacting us using the contact information provided below. We will respond to your request in accordance with applicable law.  
You can also manage your communication preferences within the App settings and control your location sharing permissions through your device settings.
6. Data Security
We have implemented reasonable technical and organizational measures designed to protect your personal information from unauthorized access, use, disclosure, alteration, or destruction. However, no method of transmission over the internet or method of electronic storage is completely secure, and we cannot guarantee absolute security.  
7. Data Retention
We will retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.  
8. Children's Privacy  
The App is not intended for children under the age of 18. We do not knowingly collect personal information from children under this age. If you are a parent or guardian and believe that your child has provided us with personal information, please contact us immediately, and we will take steps to delete such information.  
9. International Data Transfers
Your personal information may be transferred to and processed in countries outside of the UK, which may have different data protection laws than those in your country. We will take appropriate safeguards to ensure that your personal information remains protected in accordance with this Privacy Policy and applicable law.  
10. Changes to This Privacy Policy
We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. We will notify you of any material changes by posting the updated Privacy Policy within the App or by other means. Your continued use of the App after the effective date of the revised Privacy Policy constitutes your acceptance of the changes.  
11. Contact Us
If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:
Email: admin@3ventiz.co.uk
Address: [3ventiz Limited, Bristol, United Kingdom]
""".obs;
var contactInfo = {"phone":"+44 7402 531102", "email": "Admin@3ventiz.co.uk"}.obs;
var faq = [
  {
  "question": "How does 3ventiz help me plan my event?",
  "answer": "3ventiz connects you with reliable vendors, offers budget-matching tools, and provides planning features like checklists and reminders to ensure a smooth and stress-free event planning experience."
},
  {
  "question": "Is it safe to make payments through 3ventiz?",
  "answer": "Yes, all transactions are securely processed using trusted payment gateways, ensuring your data and payments are protected."
},
  {
  "question": "Can I communicate directly with vendors?",
  "answer": "Absolutely! Our built-in messaging feature allows you to chat with vendors, discuss details, and ask questions before booking."
},
  {
  "question": "How do I know the vendors are reliable?",
  "answer": "Every vendor on 3ventiz has verified profiles, reviews, and ratings from past clients to help you make informed decisions."
},
  {
  "question": "Can I sell tickets for my event on 3ventiz?",
  "answer": "Yes! You can easily create, manage, and sell tickets for your events using our secure ticketing system, similar to Eventbrite."
},
  {
  "question": "How do I sign up as a vendor on 3ventiz?",
  "answer": "Vendors can sign up by creating a profile, uploading their portfolio, and setting their services and pricing. Once verified, they can start receiving bookings."
},
  {
  "question": "What types of events can I plan using 3ventiz?",
  "answer": "3ventiz supports all kinds of events, including weddings, corporate meetings, birthdays, concerts, and private gatherings—big or small, we've got you covered."
},
  {
  "question": "Is there a cost to join 3ventiz as a client or vendor?",
  "answer": "Signing up as a client is completely free. Vendors can also join for free, with premium options available to boost visibility and reach more customers."
},
].obs;

getLegalDocs() {
  ApiClient().makeGetRequest('get-doc').then((d){
    if(Get.find<Triventizx>().statusCode.value == 0){
    //  print(d);
     // communityGuidelines.value = d['data']['communityGuidelines']??"";
      termsOfUse.value = d['data']['termsOfUse']??"""Updated: April 4, 2025
1. Acceptance of Terms
By downloading, installing, accessing, or using the 3ventiz Limited event management mobile application (the "App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, you may not access or use the App.  
2. Use of the App
3ventiz is a platform designed to help users discover, plan, and manage events. You may use the App to:
• Browse and search for events.
• View event details, including dates, times, locations, and descriptions.
• Purchase tickets for events.
• RSVP to events.
• Communicate with event organizers and other attendees.
• Utilize planning tools provided within the App.
• Save and manage your favorite events.
You agree to use the App only for lawful purposes and in a manner that does not infringe the rights of, restrict, or inhibit anyone else's use and enjoyment of the App.  
3. User Accounts
To access certain features of the App, you may be required to create a user account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate and complete information when creating your account and to update your information as necessary. You are responsible for notifying us immediately of any unauthorized access to or use of your account.  
4. Content and Conduct
You are solely responsible for any content you post, upload, or otherwise transmit through the App ("User Content"). You agree not to post User Content that is:
• Unlawful, harassing, libelous, abusive, threatening, harmful, vulgar, obscene, or otherwise objectionable.
• Infringing on the intellectual property rights of others.
• Containing viruses, malware, or other harmful code.
• Misleading or fraudulent.
• Used for spamming or unauthorized advertising.
3ventiz Limited reserves the right to remove any User Content that violates these Terms or is otherwise deemed inappropriate.
5. Intellectual Property
The App and its original content (excluding User Content), features, and functionality are and will remain the exclusive property of 3ventiz Limited and its licensors. The App is protected by copyright, trademark, and other laws. You may not modify, reproduce, distribute, create derivative works of, publicly display, or in any way exploit any of the content or software of the App without the prior written consent of 3ventiz Limited.  
6. Third-Party Links and Services
The App may contain links to third-party websites or services that are not owned or controlled by 3ventiz Limited. 3ventiz has no control over and assumes no responsibility for the content, privacy policies, or practices of any third-party websites or services. You acknowledge and agree that 3ventiz Limited shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods, or services available on or through any such third-party websites or services.  
7. Disclaimer of Warranties
THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND ANY WARRANTIES ARISING OUT OF COURSE OF DEALING OR USAGE OF TRADE. EVENTSPARK DOES NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, SECURE, OR FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.  
8. Limitation of Liability
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL 3VENTIZ LIMITED, ITS AFFILIATES, DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, SUPPLIERS, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOST PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES) ARISING OUT OF OR RELATING TO YOUR ACCESS TO OR USE OF, OR INABILITY TO ACCESS OR USE, THE APP, WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), STATUTE, OR ANY OTHER LEGAL THEORY, WHETHER OR NOT EVENTSPARK HAS BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE. IN NO EVENT SHALL 3VENTIZ LIMITED AGGREGATE LIABILITY TO YOU FOR ALL CLAIMS ARISING OUT OF OR RELATING TO THE APP EXCEED THE AMOUNT YOU PAID, IF ANY, TO 3VENTIZ LIMITED FOR ACCESSING OR USING THE APP IN THE TWELVE (12) MONTHS PRIOR TO THE EVENT GIVING RISE TO THE LIABILITY.  
9. Indemnification
You agree to defend, indemnify, and hold harmless 3ventiz Limited, its affiliates, directors, officers, employees, agents, suppliers, and licensors from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees) arising from: (i) your use of and access to the App; (ii) your violation of any term of these Terms; (iii) your violation of any third-party right, including without limitation any right of privacy or intellectual property rights; (iv) your violation of any applicable law, rule, or regulation; (v) your User Content; or (vi) any other party's access and use of the App with your unique username, password, or other appropriate security code.  
10. Governing Law and Dispute Resolution
These Terms shall be governed by and construed in accordance with the laws of England and Wales, without regard to its conflict of law provisions. Any dispute arising out of or relating to these Terms or the App shall be subject to the exclusive jurisdiction of the courts located in Bristol, England.  
11. Changes to These Terms
3ventiz Limited reserves the right to modify or revise these Terms at any time by posting the updated Terms within the App. Your continued use of the App after any such changes constitutes your acceptance of the new Terms. It is your responsibility to review these Terms periodically for any changes.  
12. Contact Us
If you have any questions about these Terms, please contact us at:  
Email: admin@3ventiz.co.uk
 Address: [3ventiz Limited, Bristol, United Kingdom]""";
      privacyPolicy.value = d['data']['privacyPolicy']??"""Last Updated: April 4, 2025
1. Introduction
3ventiz Limited ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your personal information when you use our mobile application (the "App"). Please read this Privacy Policy carefully.  
2. Information We Collect
We may collect the following types of personal information from you:
• Account Information: When you create an account, we collect your name, email address, password, and optionally, your phone number and profile picture.  
• Profile Information: You may choose to provide additional information in your profile, such as your interests, location, and social media links.
• Usage Data: We collect information about how you use the App, including the events you browse, tickets you purchase, events you RSVP to, your interactions with other users, and the features you use.
• Device Information: We collect information about your mobile device, including your device type, operating system, unique device identifiers, IP address, and mobile network information.
• Location Data: With your consent, we may collect your device's precise location to provide you with location-based event recommendations and features. You can manage your location sharing preferences in your device settings.  
• Communications: We may collect information contained in your communications with us, such as support requests and feedback.
• Payment Information: If you purchase tickets through the App, we use third-party payment processors to handle your payment information securely. We do not directly store your full credit card details.
3. How We Use Your Information
We may use your personal information for the following purposes:
• To provide and maintain the App and its features.  
• To personalize your experience and provide tailored event recommendations.
• To process your ticket purchases and RSVPs.
• To facilitate communication between you and event organizers or other attendees (with your consent).
• To send you notifications and updates about events you are interested in.
• To respond to your inquiries and provide customer support.
• To analyze App usage and trends to improve our services.
• To detect, prevent, and address technical issues, fraud, and abuse.
• To comply with applicable laws and regulations.
• For marketing and promotional purposes (with your consent, where required by law).
4. How We Share Your Information
We may share your personal information with the following categories of recipients:
• Event Organizers: When you purchase tickets for or RSVP to an event, we will share your relevant information (e.g., name, email address) with the event organizer for event management purposes.
• Other Users: If you choose to interact with other users through the App (e.g., through messaging features), your profile information and communications may be visible to them.
• Service Providers: We may share your information with third-party service providers who assist us with various functions, such as payment processing, data analytics, email delivery, and hosting services. These providers are contractually obligated to protect your information.  
• Business Transfers: In the event of a merger, acquisition, or sale of all or a portion of our assets, your information may be transferred to the acquiring entity.  
• Legal Compliance: We may disclose your information if required to do so by law or in response to a valid legal request, such as a court order or government investigation.  
• With Your Consent: We may share your information with third parties for other purposes with your explicit consent.
5. Your Rights and Choices
You have certain rights regarding your personal information, including:
• Access: You can request access to the personal information we hold about you.  
• Correction: You can request that we correct any inaccurate or incomplete personal information.
• Deletion: You can request that we delete your personal information, subject to certain exceptions.  
• Objection: You can object to the processing of your personal information for certain purposes, such as direct marketing.  
• Restriction: You can request that we restrict the processing of your personal information in certain circumstances.
You can exercise these rights by contacting us using the contact information provided below. We will respond to your request in accordance with applicable law.  
You can also manage your communication preferences within the App settings and control your location sharing permissions through your device settings.
6. Data Security
We have implemented reasonable technical and organizational measures designed to protect your personal information from unauthorized access, use, disclosure, alteration, or destruction. However, no method of transmission over the internet or method of electronic storage is completely secure, and we cannot guarantee absolute security.  
7. Data Retention
We will retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.  
8. Children's Privacy  
The App is not intended for children under the age of 18. We do not knowingly collect personal information from children under this age. If you are a parent or guardian and believe that your child has provided us with personal information, please contact us immediately, and we will take steps to delete such information.  
9. International Data Transfers
Your personal information may be transferred to and processed in countries outside of the UK, which may have different data protection laws than those in your country. We will take appropriate safeguards to ensure that your personal information remains protected in accordance with this Privacy Policy and applicable law.  
10. Changes to This Privacy Policy
We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. We will notify you of any material changes by posting the updated Privacy Policy within the App or by other means. Your continued use of the App after the effective date of the revised Privacy Policy constitutes your acceptance of the changes.  
11. Contact Us
If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:
Email: admin@3ventiz.co.uk
Address: [3ventiz Limited, Bristol, United Kingdom]
""";
      contactInfo.value = d['data']['contactInfo']??{"phone":"+44 7402 531102", "email": "Admin@3ventiz.co.uk"};
      faq.value = d['data']['faq']?? [
        {
          "question": "How does 3ventiz help me plan my event?",
          "answer": "3ventiz connects you with reliable vendors, offers budget-matching tools, and provides planning features like checklists and reminders to ensure a smooth and stress-free event planning experience."
        },
        {
          "question": "Is it safe to make payments through 3ventiz?",
          "answer": "Yes, all transactions are securely processed using trusted payment gateways, ensuring your data and payments are protected."
        },
        {
          "question": "Can I communicate directly with vendors?",
          "answer": "Absolutely! Our built-in messaging feature allows you to chat with vendors, discuss details, and ask questions before booking."
        },
        {
          "question": "How do I know the vendors are reliable?",
          "answer": "Every vendor on 3ventiz has verified profiles, reviews, and ratings from past clients to help you make informed decisions."
        },
        {
          "question": "Can I sell tickets for my event on 3ventiz?",
          "answer": "Yes! You can easily create, manage, and sell tickets for your events using our secure ticketing system, similar to Eventbrite."
        },
        {
          "question": "How do I sign up as a vendor on 3ventiz?",
          "answer": "Vendors can sign up by creating a profile, uploading their portfolio, and setting their services and pricing. Once verified, they can start receiving bookings."
        },
        {
          "question": "What types of events can I plan using 3ventiz?",
          "answer": "3ventiz supports all kinds of events, including weddings, corporate meetings, birthdays, concerts, and private gatherings—big or small, we've got you covered."
        },
        {
          "question": "Is there a cost to join 3ventiz as a client or vendor?",
          "answer": "Signing up as a client is completely free. Vendors can also join for free, with premium options available to boost visibility and reach more customers."
        },
      ];
    }
    else if(Get.find<Triventizx>().statusCode.value == 1){
      //print("legal error $d");
    }
    else{
   //   print(d);
    }
  });
}


///Update Payout.////
  RxString eholder = RxString("");
  RxString efirstName = RxString("");
  RxString elastName = RxString("");
  RxString eaddress = RxString("");
  RxString ecity = RxString("");
  RxString epostalCode = RxString("");
  RxString eholderCountry = RxString("");
  RxString eaccountType = RxString("");
  RxString ebankName = RxString("");
  RxString esortCode = RxString("");
  RxString eaccountNumber = RxString("");
  RxBool euseAsDefaultAcct = RxBool(false);
  var edPayIsLoading = false.obs;
  updateCreatorPayout(BuildContext context, Map<String,dynamic> existingPayout){
   edPayIsLoading.value=true;
    final thePayload = {
      "country": "United Kingdom",
      "countryCurrency": "GBP",
      "owner": "${eholder.value}",
      "firstName":efirstName.isEmpty? "${existingPayout['firstName']}": "${efirstName.value}",
      "lastName": elastName.isEmpty? "${existingPayout['lastName']}": "${elastName.value}",
      "address": eaddress.isEmpty? "${existingPayout['address']}": "${eaddress.value}",
      "city": ecity.isEmpty? "${existingPayout['city']}": "${ecity.value}",
      "postalCode": epostalCode.isEmpty? "${existingPayout['postalCode']}": "${epostalCode.value}",
      "countryAddress": eholderCountry.isEmpty? "${existingPayout['countryAddress']}": "${eholderCountry.value}",
      "accountType": eaccountType.value,
      "bankName": ebankName.isEmpty? "${existingPayout['bankName']}": "${ebankName.value}",
      "sortCode": esortCode.isEmpty? existingPayout['sortCode']: int.parse(esortCode.value),//int
      "accountNumber": eaccountNumber.isEmpty? existingPayout['accountNumber']: int.parse(eaccountNumber.value),//int
      "isDefault": euseAsDefaultAcct.value,//bool
    };
    print(thePayload);
    PaymentApiClient().makePatchRequest(endPoint: 'update-payout/${Get.find<Triventizx>().userId}', body: thePayload).then((u){
      if(Get.find<Triventizx>().statusCode.value == 0){
        print(u);
        edPayIsLoading.value = false;
        Get.defaultDialog(
            barrierDismissible: false,
            title: "",
            radius: 12,
            backgroundColor: Colors.white,
            titlePadding: EdgeInsets.zero,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/check-circle-0 1.png"),
                  SizedBox(height: Get.height*0.01,),
                  Text(
                      "Update successful!",
                      style: Stylings.thicSubtitle
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    "Your payout has been successfully updated.",
                    style: Stylings.body.copyWith(fontSize: 10),textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15,),
                  GestureDetector(
                    onTap: (){
                  //    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CreatorHomepage(initialIndex: 0,)));
                    Get.offAll(()=>CreatorHomepage(initialIndex: 0,));
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration:BoxDecoration(
                          color: Stylings.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text("Continue",style: Stylings.thicSubtitle.copyWith(color: Color(0xFF05045F),fontSize: 11),),
                    ),
                  )
                ],
              ),
            )
        );
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        print(u);
        edPayIsLoading.value = false;
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
                  u['message'],
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
        print(u);
        edPayIsLoading.value = false;
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



///Report An issue
  var isIssueFilled = false.obs;
 checkfilled(String lname,String fname,String body){
  if (lname.isNotEmpty&&fname.isNotEmpty&&body.isNotEmpty){
    isIssueFilled.value=true;
  }
  else  {
    isIssueFilled.value=false;
  }
 }





}