import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart';
import 'package:triventiz/onboarding/onboardauser/asattendeeorcreator.dart';
import 'package:triventiz/server/apiclient.dart';
import 'package:triventiz/server/getxserver.dart';

import '../authentication/twofactorauthentication.dart';
import '../homes/attendeehomepage.dart';
import '../homes/creatorhomepage.dart';
import '../homes/permissions/locationpermission.dart';
import '../utils/loadingpage.dart';

class Oauthsforgoogle extends GetxController{
  var gAuthLoading = false.obs;
  var gAuthError = "".obs;
  final GoogleSignIn _googleSignIn =  GoogleSignIn(
    scopes: [
      'openid',
      'email',
      'profile',
    ],
    serverClientId: "webclient id" //web client
  );
  // Store user info
  var _token = "";
  var _userData = {};
  // Getters
  //String? get token => _token;
 // Map<String, dynamic>? get userData => _userData;
  //bool get isAuthenticated => _token != null;
  
  
  ///Register
  Future signUpWithGoogle() async{
    gAuthError.value="";
    await signOut();
    gAuthLoading.value=true;
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        gAuthLoading.value=false;
        return;
      }
      else{
       // print(googleUser);
        Get.find<Triventizx>().userEmail.value = googleUser.email; //login is  set here
        Get.find<Triventizx>().loginEmail.value = googleUser.email;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
       // print("Access token ${googleAuth.accessToken}");
       // print("Id Token ${googleAuth.idToken}");
        _token = "${googleAuth.idToken}";
        ApiClient().makePostRequest(
            endPoint: "google-register",
            body: {"token":_token}
        ).then((g){
          if (Get.find<Triventizx>().statusCode.value == 0) {
            gAuthLoading.value=false;
            print(g);
            Get.find<Triventizx>().isUsingGAuth.value =true;
            Get.to(()=>OnboardRegUser());
          }
          else if(Get.find<Triventizx>().statusCode.value == 1){
            print(g);
            if(g['message']=="Email is already registered."){
              silentlySignIn();
            }
           else{
              gAuthError.value=g['message'];
              gAuthLoading.value=false;
            }
          }
          else{
            gAuthLoading.value=false;
            gAuthError.value="A network error occurred";
          }
        });

      }
    } catch(e){
      gAuthLoading.value=false;
      gAuthError.value="An error occurred";
    }

  }
  
  
  
  
  ///SILENTLY LOG IN FOR USERS COMING FROM OTHER SOURCES INSTEAD OF RESTART
  Future silentlySignIn() async{
   // print("silentlyyyyy");
    ApiClient().makePostRequest(
        endPoint: "google-login",
        body: {"token":_token}
    ).then((s) async {
      if (Get.find<Triventizx>().statusCode.value == 0) {
        gAuthLoading.value=false;
        print(s);
        Location _location = Location();
        PermissionStatus status = await _location.hasPermission();
        Get.to(() => Loadingpage(doingWhat: "Logging in"));
        if(s['data']['base32']!=null){
          Get.find<Triventizx>().isLoading.value = false;
          Get.find<Triventizx>().baseThreeTwoSecret = s['data']['base32'];
          Get.find<Triventizx>().otpAuthUrl = s['data']['otpauth_url'];
          Get.off(()=>Twofactorauthentication());
        }
        else{
          Get.find<Triventizx>().isLoading.value = false;
          Get.find<Triventizx>().loginErrorText.value = "";
          Get.find<Triventizx>().userAccessToken = s['data']['token'];
          Get.find<Triventizx>().userId = s['data']['_id'];
          Get.find<Triventizx>().userEmail.value = s['data']['email'];
          Get.find<Triventizx>().userAvatar = s['data']['url'] ?? "";
          Get.find<Triventizx>().mfa.value = s['data']['mfa'];
          Get.find<Triventizx>().userSessionId = s['data']['sessionId'] ?? "";
          final List tempRole = s['data']['role'];
          // userNotificationPreferences.value = {
          //   "email": l['data']['userNotificationPreferences']['email'],
          //   "push": l['data']['userNotificationPreferences']['push'],
          //   "sms": l['data']['userNotificationPreferences']['sms'],
          //   "marketing": l['data']['userNotificationPreferences']['marketing'],
          // };
          //do if role from server is not null check

          //check
          //if there is alreeady a location in shared preferences
          //go to homepage
          //else
          //check persistedrolesvalue to determine homepage
          if (tempRole.isEmpty) {
            Get.to(() => OnboardRegUser());
          }
          else if (status == PermissionStatus.denied) {
            Get.find<Triventizx>().userRole.value = s['data']['role'][0];
            Get.find<Triventizx>().userNotificationPreferences.value = {
              "email": s['data']['preference']['email'],
              "push": s['data']['preference']['push'],
              "sms": s['data']['preference']['sms'],
              "marketing": s['data']['preference']['marketing'],
            };
            Get.find<Triventizx>().userFullName = s['data']['fullName'];
            Get.find<Triventizx>().businessName = s['data']['businessName'] ?? "";
            Get.find<Triventizx>().userPhoneNumber.value = s['data']['phone'];

            Get.find<Triventizx>().businessFacebook = s['data']['facebook']??'';
            Get.find<Triventizx>().businessX = s['data']['x']??"";
            Get.find<Triventizx>().businessWebsite = s['data']['website']??'';
            Get.find<Triventizx>().bio = s['data']['bio']??'';
            Get.find<Triventizx>().businessInstagram = s['data']['instagram']??'';
            Get.find<Triventizx>().businessIndustryList = s['data']['industry']??'';
            Get.to(() => Permission());
          }
          else if (tempRole.isNotEmpty) {
            Get.find<Triventizx>().userRole.value = s['data']['role'][0];
            Get.find<Triventizx>().userFullName = s['data']['fullName'];
            Get.find<Triventizx>().userNotificationPreferences.value = {
              "email": s['data']['preference']['email'],
              "push": s['data']['preference']['push'],
              "sms": s['data']['preference']['sms'],
              "marketing": s['data']['preference']['marketing'],
            };
            Get.find<Triventizx>().businessName = s['data']['businessName'] ?? "";
            Get.find<Triventizx>().userPhoneNumber.value = s['data']['phone'];

            Get.find<Triventizx>().businessFacebook = s['data']['facebook']??'';
            Get.find<Triventizx>().businessX = s['data']['x']??'';
            Get.find<Triventizx>().businessWebsite = s['data']['website']??'';
            Get.find<Triventizx>().bio = s['data']['bio']??'';
            Get.find<Triventizx>().businessInstagram = s['data']['instagram']??'';
            Get.find<Triventizx>().businessIndustryList = s['data']['industry']??'';
            Get.find<Triventizx>().userRole == "attendee"
                ? Get.offAll(() => Attendeehomepage())
                : Get.offAll(() => CreatorHomepage());
          }
        }
      }
      else if(Get.find<Triventizx>().statusCode.value == 1){
        gAuthLoading.value=false;
        gAuthError.value=s['message'];
        if(s["message"]=="user account not yet onboarded"){
          Get.find<Triventizx>().isUsingGAuth.value =true;
          Get.off(() => OnboardRegUser());
        }
        print(s);
      }
      else{
        gAuthLoading.value=false;
        gAuthError.value="An error occurred";
      }
    });
  }
  
  
  

  // Sign in with Google
  Future signInWithGoogle() async{
    gAuthError.value="";
    await signOut();
    gAuthLoading.value=true;
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        gAuthLoading.value=false;
        return;
      }
      else{
        // print(googleUser);
        Get.find<Triventizx>().userEmail.value = googleUser.email;
        Get.find<Triventizx>().loginEmail.value = googleUser.email;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        // print("Access token ${googleAuth.accessToken}");
        // print("Id Token ${googleAuth.idToken}");
        _token = "${googleAuth.idToken}";
       // Clipboard.setData(ClipboardData(text: "$_token"));
        silentlySignIn();
      }
    } catch(e){
      gAuthLoading.value=false;
      gAuthError.value="An error occurred";
    }

  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _token = "";
    gAuthError.value='';
    _userData = {};
  }










  //END
}