import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triventiz/authentication/login.dart';
import 'package:triventiz/authentication/signups/verifyemail.dart';
import 'package:triventiz/authentication/unverifiiedlogin.dart';
import 'package:triventiz/homes/attendeehomepage.dart';
import 'package:triventiz/homes/creatorhomepage.dart';
import 'package:triventiz/server/apiclient.dart';
import 'package:triventiz/services/created_events_controller.dart';
import 'package:triventiz/services/oauthsforgoogle.dart';
import 'package:triventiz/services/settings_controller.dart';
import 'package:triventiz/splashscreen.dart';
import 'package:triventiz/authentication/twofactorauthentication.dart';
import 'package:triventiz/utils/loadingpage.dart';
import 'package:triventiz/utils/reusables/tbutton.dart';

import '../authentication/signups/signinmethods.dart';
import '../homes/permissions/locationpermission.dart';
import '../onboarding/onboardauser/asattendeeorcreator.dart';
import '../onboarding/onboarduser.dart';
import '../services/attendee/attendee_events_controller.dart';
import '../services/create_event_controller.dart';
import '../services/notifications_controller.dart';
import '../utils/stylings.dart';

class Triventizx extends GetxController {
  @override
  void onInit() {
    //notifications Controller
    Get.put<NotificationsController>(NotificationsController());
    //others initialized on splash screen
    super.onInit();
  }

  ///Remember to refactor this into init
  //settings Controller
  var setX = Get.put<SettingsController>(SettingsController());

  //createEvent Controller
  var createX = Get.put<CreateEventController>(CreateEventController());

  var obscure = true.obs;

  //date formatter to how mamny days or hours ago
  getRelativeTime(String isoString) {
    // Parse the ISO 8601 string to DateTime
    DateTime dateTime = DateTime.parse(isoString);

    // Get the current time
    DateTime now = DateTime.now().toUtc();

    // Calculate the difference
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return "${difference.inDays ~/ 365} ${difference.inDays ~/ 365 == 1 ? 'year' : 'years'} ago";
    } else if (difference.inDays > 30) {
      return "${difference.inDays ~/ 30} ${difference.inDays ~/ 30 == 1 ? 'month' : 'months'} ago";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago";
    } else {
      return "just now";
    }
  }

  //date formaterr to dd/mm/yy
  dateFormat(String theDate) {
    String dateTimeString = theDate;
    DateTime dateTime = DateTime.parse(dateTimeString);

    // Create a DateFormat object with the desired format
    DateFormat formatter = DateFormat('EEEE, MMMM d');

    // Format the date and time
    String formattedDateTime = formatter.format(dateTime);
    return formattedDateTime;
    // print(formattedDateTime);
  }

  //date picker
  Future<void> pickDate(BuildContext context, RxString storeIn) async {
    showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Get.back();
                },
                child: Tbutton(
                  bText: "Done",
                  bColor: Stylings.blue,
                  hasMargin: false,
                ),
              ),
              actions: [
                SizedBox(
                  height: Get.height * 0.25,
                  child: CupertinoDatePicker(
                      initialDateTime: DateTime.now(),
                      maximumYear: 2099,
                      minimumYear: DateTime.now().year,
                      mode: CupertinoDatePickerMode.date,
                      onDateTimeChanged: (date) {
                        storeIn.value = date.toString().split(" ")[0];
                      }),
                ),
              ],
            ));
    // DateTime? theDate = await
    //
    // // showDatePicker(context: context,
    //   firstDate: DateTime.now(),
    //   initialDate: DateTime.now(),
    //   lastDate: DateTime(2099),
    // );
    // if(theDate!=null){
    //
    //   storeIn.value  = theDate.toString().split(" ")[0];
    // }
  }

  //time picker
  Future<void> pickTime(BuildContext context, RxString storeIn) async {
    showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Get.back();
                },
                child: Tbutton(
                  bText: "Done",
                  bColor: Stylings.blue,
                  hasMargin: false,
                ),
              ),
              actions: [
                SizedBox(
                  height: Get.height * 0.25,
                  child: CupertinoDatePicker(
                      initialDateTime: DateTime.now(),
                      maximumYear: 2099,
                      minimumYear: DateTime.now().year,
                      mode: CupertinoDatePickerMode.time,
                      onDateTimeChanged: (time) {
                        storeIn.value = "${DateFormat('h:mm a').format(time)}";
                      }),
                ),
              ],
            ));
    // TimeOfDay? theTime = await showTimePicker(context: context,
    //     initialTime: TimeOfDay.now());
    // if(theTime!=null){
    //   storeIn.value  = "${theTime.format(context).toString()}";
    // }
  }

  ///Auths Locale///
  var userEmail = "".obs;
  var bIsActive = false.obs;
  var eErrorText = "".obs;

  emailInputFormatter() {
    if (userEmail.isEmpty) {
      bIsActive.value = false;
    } else if (!userEmail.contains("@") ||
        !userEmail.contains(".") ||
        userEmail.contains(" ")) {
      bIsActive.value = false;
    } else {
      bIsActive.value = true;
    }
  }

  //password validation
  var userPassword = "".obs;
  var hidePassword = true.obs;
  var hasAllcharacters = false.obs;
  var hasUpperCase = false.obs;
  var hasLowerCase = false.obs;
  var hasAnumber = false.obs;
  var hasSpecialCharacter = false.obs;
  var allChecked = false.obs;

  passwordInputFomatter(String pass) {
    if (pass.length > 7) {
      hasAllcharacters.value = true;
    } else if (pass.length < 8) {
      hasAllcharacters.value = false;
    }
    if (pass.contains(RegExp(r'[A-Z]'))) {
      hasUpperCase.value = true;
    } else if (!pass.contains(RegExp(r'[A-Z]'))) {
      hasUpperCase.value = false;
    }
    if (pass.contains(RegExp(r'[a-z]'))) {
      hasLowerCase.value = true;
    } else if (!pass.contains(RegExp(r'[a-z]'))) {
      hasLowerCase.value = false;
    }
    if (pass.contains(RegExp(r'[0-9]'))) {
      hasAnumber.value = true;
    } else if (!pass.contains(RegExp(r'[0-9]'))) {
      hasAnumber.value = false;
    }
    if (pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      hasSpecialCharacter.value = true;
    } else if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      hasSpecialCharacter.value = false;
    }
    //if all checks
    if (hasAllcharacters.value &&
        hasUpperCase.value &&
        hasLowerCase.value &&
        hasAnumber.value &&
        hasSpecialCharacter.value) {
      userPassword.value = pass;
      //print(userPassword.value);
    }
    //if any doesn't check
    else if (!hasAllcharacters.value ||
        !hasUpperCase.value ||
        !hasLowerCase.value ||
        !hasAnumber.value ||
        !hasSpecialCharacter.value) {
      userPassword.value = "";

      //print(userPassword.value);
    }
  }

  var confirmPassErrorText = "".obs;

  confirmPassword(String confirmPass) {
    if (confirmPass == userPassword.value) {
      allChecked.value = true;
      eErrorText.value = "";
    } else {
      allChecked.value = false;
      eErrorText.value = "Password doesn't match";
    }
  }

//OTP timer
  Timer? timer;
  int remSecs = 1;
  final time = '60'.obs;
  var isTimerDone = false.obs;

  startTimer(int seconds) {
    const duration = Duration(seconds: 1);
    remSecs = seconds;
    timer = Timer.periodic(duration, (Timer timer) {
      if (remSecs < 0) {
        timer.cancel();
        isTimerDone.value = true;
      } else {
        int min = remSecs ~/ 60;
        int secs = remSecs % 60;
        time.value = secs.toString().padLeft(2, '0');
        remSecs--;
      }
    });
  }

  ///ONBOARD USERS
  var linearIndValue = 0.33.obs;
  var userFullName = "";
  var userPhoneNumber = "".obs;

  // var userOnbardEmail = "";
  //attendee
  var attendeeeInterests = [
    'SmartContracts',
    'Conference',
    "Design",
    'DecentralizedFinance',
    'Blockchain',
    'Cryptocurrency',
    'Tech',
    'Web3',
    'NFTs',
    'Finance'
  ];
  var selecteedInterests = [].obs;

  //creator
  var businessName = "";
  var businessWebsite = "";
  var businessFacebook = "";
  var businessInstagram = "";
  var businessX = "";
  var businessIndustry = "";
  var businessIndustryList = [];
  var bio = '';

  formIndustries(String industries) {
    businessIndustryList = industries.split(',');
  }

  //Choose Role
  var userRole = "".obs;

  //user IMG
  var userAvatar = '';

  //sessionId
  var userSessionId = '';

  //phone number uk
  var pErrorText = "".obs;

  phoneNumberInputFormatter(RxString toUpdate, RxString toCheck) {
    final RegExp ukPhoneRegex = RegExp(r'^\+44\d{10}$');
    if (!ukPhoneRegex.hasMatch(toCheck.value)) {
      toUpdate.value = "Please enter a valid Uk phone number";
    } else {
      toUpdate.value = "";
    }
  }

  bool isBioDataComplete() {
    if (userFullName.isEmpty ||
        userPhoneNumber.isEmpty ||
        userPhoneNumber.value.length != 13) {
      return false;
    } else if (!userFullName.isEmpty || !userPhoneNumber.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  bool isRoleSelected() {
    if (userRole.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  //role form error
  var roleFormError = "";

  //persist role
  // var persistedRole = "".obs;
  //
  // Future<void> getPersistedRole() async{
  //   final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   persistedRole.value = sharedPreferences.getString("uRole")!;
  // }
  //
  // void persistRole() async{
  //   final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   sharedPreferences.setString("uRole", "$userRole");
  // }

  bool isRoleInputsFilled() {
    if (userRole.value == "Attendee") {
      if (selecteedInterests.length < 3) {
        roleFormError = "Select at least three interests";
        return false;
      } else {
        return true;
      }
    } else if (userRole.value == "Creator") {
      if (businessName.isEmpty) {
        roleFormError = "Please enter a Business Name";
        return false;
      } else {
        return true;
        //persist  role
      }
    }
    return false;
  }  ///DO CHECKS FOR CREATOR

  nextOnboard() {
    if (linearIndValue.value == 0.33) {
      isBioDataComplete()
          ? linearIndValue.value = 0.66
          : Get.snackbar(
              "Incomplete Details",
              "Please fill details correctly",
              duration: Duration(seconds: 2),
            );
    } else if (linearIndValue.value == 0.66) {
      isRoleSelected()
          ? linearIndValue.value = 1
          : Get.snackbar(
              "Incomplete Details",
              "Please choose a role",
              duration: Duration(seconds: 2),
            );
    } else if (linearIndValue.value == 1) {
      isRoleInputsFilled()
          ? updateOnboardDetails()
          : Get.snackbar("Incomplete Details", "$roleFormError",
              duration: Duration(seconds: 2));
    }
  }

  ///Consumables
  ///Onboard Carousel
  //set
  Future<void> hasSeenCarousel() async {
    final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("seenCarousel", true);
      Get.offAll(()=> Signinmethods());
  }
  //get
  Future<void> getHasSeenCarousel() async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    if (sharedPreferences.getBool("seenCarousel") == true) {
      Get.offAll(()=>Login());
    } else {
      Get.offAll(()=>Onboarduser());
    }
  }



  var isLoading = false.obs;
  var statusCode = 0.obs;

  //Register
  var registerErrorText = "".obs;
  var userSendUpdate = "".obs;

  createAccount() {
    //print(userEmail);
    isLoading.value = true;
    if (userEmail.isEmpty || userPassword.isEmpty) {
      registerErrorText.value = "Details Incomplete";
      Future.delayed(const Duration(seconds: 1), () {
        isLoading.value = false;
      });
    } else {
      //register
      ApiClient().makePostRequest(endPoint: "register", body: {
        "email": userEmail.value,
        "password": userPassword.value,
        "subscribe": true
      }).then((c) {
        //print(statusCode);
        if (statusCode.value == 0) {
          //print(c);
          isLoading.value = false;
          registerErrorText.value = "";
          //  print("yes");
          Get.to(() => const Verifyemail());
        } else if (statusCode.value == 1) {
          isLoading.value = false;
          //print(c);
          registerErrorText.value = c["message"];
        } else {
          isLoading.value = false;
          registerErrorText.value = "An error occurred";
        }
      });
    }
  }

  //Verify OTP
  var verifyCodeErrorText = "".obs;
  var isCodeComplete = false.obs;
  var codeToVerify = "".obs;
  var blurUBackground = false.obs;

  verifyCode() {
    if (codeToVerify.isNotEmpty) {
      isLoading.value = true;
      ApiClient().makePostRequest(endPoint: "verify", body: {
        "email": userEmail.value,
        "code": codeToVerify.value
      }).then((v) {
        if (statusCode.value == 0) {
          //print(v);
          isLoading.value = false;
          verifyCodeErrorText.value = "";
          blurUBackground.value = true;
          //  print("yes");
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
                    "assets/animations/check.json",
                    width: Get.height * 0.12,
                    height: Get.height * 0.12,
                    repeat: false,
                  ),
                  Text("Account Verification is successful!",
                      style: Stylings.thicSubtitle),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Your account has been successfully verified. You’re all set to start planning and discovering amazing events!",
                    style: Stylings.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.offAll(() => const OnboardRegUser());
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Stylings.blue,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Proceed",
                        style: Stylings.body.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ));
        }
        else if (statusCode.value == 1) {
          blurUBackground.value = false;
          //print(v);
          isLoading.value = false;
          verifyCodeErrorText.value = v["message"];
        }
        else {
          blurUBackground.value = false;
          verifyCodeErrorText.value = "An error occurred";
          isLoading.value = false;
        }
      });
    }
  }

  //update user details to DB
  var updateUserDetailsError = "".obs;
  var blurVBackground = false.obs;
  ///gAUTH///
  var isUsingGAuth = false.obs;
  updateOnboardDetails() {
    //print(userEmail.value);
    String emailToUse = userEmail.value.isEmpty?loginEmail.value:userEmail.value;
    //  print(userRole.value.toLowerCase());
    //  print(selecteedInterests.toList());
    //  print(userFullName);
    //  print(userPhoneNumber);
    isLoading.value = true;
    var onboardPayload = userRole.value == "Creator"
        ? {
            "email": emailToUse,
            "fullName": userFullName,
            "businessName": businessName,
            "phone": userPhoneNumber.value,
            "role": ["${userRole.value.toLowerCase()}"],
            "facebook": businessFacebook,
            "instagram": businessInstagram,
            "x": businessX,
            "website": businessWebsite,
            "industry": businessIndustryList
          }
        : {
            "email": emailToUse,
            "fullName": userFullName,
            "phone": userPhoneNumber.value,
            "role": ["${userRole.value.toLowerCase()}"],
            "categories": selecteedInterests.toList(),
          };
    //print(onboardPayload);
    ApiClient()
        .makePostRequest(endPoint: "onboard", body: onboardPayload)
        .then((u) {
      if (statusCode.value == 0) {
        //print(u);
        isLoading.value = false;
        updateUserDetailsError.value = "";
        blurVBackground.value = true;
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
                  "assets/animations/check.json",
                  width: Get.height * 0.12,
                  height: Get.height * 0.12,
                  repeat: false,
                ),
                Text("Setting up unique experience",
                    style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Please proceed while the algorithm sets up a unique experience",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () async{
                   // Get.offAll(() => Login());
                    if(isUsingGAuth.value) {
                      Get.offAll(()=>Loadingpage(doingWhat: "Please wait while we customize your experience"));
                     await Get.find<Oauthsforgoogle>().silentlySignIn();
                    }
                    else{
                      Get.offAll(() => Login());
                    }
                 // isUsingGAuth.value? Get.find<Oauthsforgoogle>().signInWithGoogle() :  Get.offAll(() => Login());//do a silent login
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Proceed",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
      } else if (statusCode.value == 1) {
        //blurVBackground.value = true;
        //print(u);
        updateUserDetailsError.value = u["message"];
        isLoading.value = false;
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("An Error Occurred", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "${updateUserDetailsError.value}",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    blurVBackground.value = false;
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
      }
      else {
        //print('kik');
       // blurVBackground.value = true;
        updateUserDetailsError.value = "An error occurred";
        isLoading.value = false;
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("An Error Occurred", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Please try again",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    blurVBackground.value = false;
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
      }
    });
  }

  //Permissions
  var userLocation = "".obs;

  Future<void> getPersistedLocation() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    if (sharedPreferences.getString("uLocation") != null) {
      userLocation.value = sharedPreferences.getString("uLocation")!;
      //print(userLocation.value);
    } else {
      return;
    }
  }

  //Login
  var loginEmail = ''.obs;
  var loginPassword = ''.obs;
  var loginErrorText = ''.obs;
  var isLogsComplete = false.obs;
  var userAccessToken = "Bearer your-token-here";
  var userId = "";
  RxMap<String,dynamic> userNotificationPreferences = RxMap({
    "email": true,
    "push": false,
    "sms": true,
    "marketing": false
  });
  var mfa = false.obs;
  var baseThreeTwoSecret = '';
  var otpAuthUrl = '';

  isLoginDetailsComplete() {
    if (loginEmail.isEmpty || loginPassword.isEmpty) {
      isLogsComplete.value = false;
    } else if (loginEmail.isNotEmpty && loginPassword.value.length >= 8) {
      isLogsComplete.value = true;
    } else {
      isLogsComplete.value = false;
    }
  }

  logIntoAccount() async{
    Location _location = Location();
    PermissionStatus status =await _location.hasPermission();
    //isLoading.value=true;
    // getPersistedRole();
    Get.to(() => Loadingpage(doingWhat: "Logging in"));
    ApiClient().makePostRequest(endPoint: "login", body: {
      "email": loginEmail.value.isEmpty?preSavedEmail.value:loginEmail.value,
      "password": loginPassword.value.isEmpty?preSavedPassword.value:loginPassword.value
    }).then((l) {
      if (statusCode.value == 0) {
        saveLoginDetails(savedLoginPassword: loginPassword.value, savedLoginEmail: loginEmail.value);
        //print(l);
        if(l['data']['base32']!=null){
          isLoading.value = false;
          baseThreeTwoSecret = l['data']['base32'];
          otpAuthUrl = l['data']['otpauth_url'];
          Get.off(()=>Twofactorauthentication());
        }
       else{
          isLoading.value = false;
          loginErrorText.value = "";
          userAccessToken = l['data']['token'];
          userId = l['data']['_id'];
          userEmail.value = l['data']['email'];
          userAvatar = l['data']['url'] ?? "";
          mfa.value = l['data']['mfa'];
          userSessionId = l['data']['sessionId'] ?? "";
          final List tempRole = l['data']['role'];
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
            userRole.value = l['data']['role'][0];
            userNotificationPreferences.value = {
              "email": l['data']['preference']['email'],
              "push": l['data']['preference']['push'],
              "sms": l['data']['preference']['sms'],
              "marketing": l['data']['preference']['marketing'],
            };
            userFullName = l['data']['fullName'];
            businessName = l['data']['businessName'] ?? "";
            userPhoneNumber.value = l['data']['phone'];

            businessFacebook = l['data']['facebook']??'';
            businessX = l['data']['x']??"";
            businessWebsite = l['data']['website']??'';
            bio = l['data']['bio']??'';
            businessInstagram = l['data']['instagram']??'';
            businessIndustryList = l['data']['industry']??'';
            Get.to(() => Permission());
          }
          else if (tempRole.isNotEmpty) {
            userRole.value = l['data']['role'][0];
            userFullName = l['data']['fullName'];
            userNotificationPreferences.value = {
              "email": l['data']['preference']['email'],
              "push": l['data']['preference']['push'],
              "sms": l['data']['preference']['sms'],
              "marketing": l['data']['preference']['marketing'],
            };
            businessName = l['data']['businessName'] ?? "";
            userPhoneNumber.value = l['data']['phone'];

            businessFacebook = l['data']['facebook']??'';
            businessX = l['data']['x']??'';
            businessWebsite = l['data']['website']??'';
            bio = l['data']['bio']??'';
            businessInstagram = l['data']['instagram']??'';
            businessIndustryList = l['data']['industry']??'';
            userRole == "attendee"
                ? Get.offAll(() => Attendeehomepage())
                : Get.offAll(() => CreatorHomepage());
          }
        }
      }
      else if (statusCode.value == 1) {
        //print(l);
      //  userEmail.value = l['data']['email'];
        //loginErrorText.value = l["message"];
        if(l["message"]=="user account not yet verified"){
          isLoading.value = false;
          Get.off(()=>Unverifiiedlogin());
        }
        if(l["message"]=="user account not yet onboarded"){
          isLoading.value = false;
          Get.off(() => OnboardRegUser());
        }
        else{
          loginErrorText.value = l["message"];
          Get.back();
          isLoading.value = false;
        }
      }
      else {
        loginErrorText.value = "An error occurred";
        Get.back();
        isLoading.value = false;
      }
    });
  }

  ///problem verifying account check
  verifyUnverifiedLogin() {
    if (codeToVerify.isNotEmpty) {
      isLoading.value = true;
      ApiClient().makePostRequest(endPoint: "verify", body: {
        "email": loginEmail.value,
        "code": codeToVerify.value
      }).then((v) {
        if (statusCode.value == 0) {
          print(v);
          isLoading.value = false;
          verifyCodeErrorText.value = "";
          blurUBackground.value = true;
          //  print("yes");
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
                    "assets/animations/check.json",
                    width: Get.height * 0.12,
                    height: Get.height * 0.12,
                    repeat: false,
                  ),
                  Text("Account Verification is successful!",
                      style: Stylings.thicSubtitle),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Your account has been successfully verified. You’re all set to start planning and discovering amazing events! Proceed to log in",
                    style: Stylings.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      loginErrorText.value=="";
                      Get.offAll(() => const Login());
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Stylings.blue,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Log in",
                        style: Stylings.body.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ));
        }
        else if (statusCode.value == 1) {
          blurUBackground.value = false;
          print(v);
          isLoading.value = false;
          verifyCodeErrorText.value = v["message"];
        }
        else {
          blurUBackground.value = false;
          verifyCodeErrorText.value = "An error occurred";
          isLoading.value = false;
        }
      });
    }
  }
  ///Resend otp/// call on init of unverified login and on tap of resend codes on both page
  resendOtp(String whichEmail) async{
    print(whichEmail);
    ApiClient().makePostRequest(endPoint: "resend", body: {"email": whichEmail}).then((t){
      if (statusCode.value == 0){
        print(t);
        }
      else if (statusCode.value == 1) {
        print(t);
      }
      else {
        print("Error");
      }
    });
  }


///For Persisting login details
  var isRememberMe = false.obs;
  Future<void> saveLoginDetails({required String savedLoginPassword,required String savedLoginEmail,}) async {
    final prefs = await SharedPreferences.getInstance();

    if (isRememberMe.value) {
      await prefs.setString('email', savedLoginEmail);
      await prefs.setString('password', savedLoginPassword);
      await prefs.setBool('rememberMe', true);
      print("saved");
    } else {
      // Clear saved details if remember me is unchecked
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  //Getting saved Details
  var preSavedEmail = "".obs;
  var preSavedPassword = "".obs;
  // Load saved login details when screen initializes
  Future<void> loadSavedLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();

      preSavedEmail.value = prefs.getString('email') ?? '';
      preSavedPassword.value = prefs.getString('password') ?? '';

    print("gotten Login details - ${preSavedEmail.value} ${preSavedPassword.value}");
  }





///FOR 2FA///
  var isTwofaLoading = false.obs;
  var twoFaLoadingError = ''.obs;
  verifyTwoFA(String token) async{
    isTwofaLoading.value = true;
    Location _location = Location();
    PermissionStatus status =await _location.hasPermission();
    ApiClient().makePostRequest(endPoint: "verify-2fa", body: {"email": loginEmail.value,"token" :"$token"}).then((t){
      if (statusCode.value == 0){
        print(t);
        isTwofaLoading.value = false;
        loginErrorText.value = "";
        userAccessToken = t['data']['token'];
        userId = t['data']['_id'];
        userEmail.value = t['data']['email'];
        userAvatar = t['data']['url'] ?? "";
        mfa.value = t['data']['mfa'];
        userSessionId = t['data']['sessionId'] ?? "";
        userNotificationPreferences.value = {
          "email": t['data']['preference']['email'],
          "push": t['data']['preference']['push'],
          "sms": t['data']['preference']['sms'],
          "marketing": t['data']['preference']['marketing'],
        };
        final List tempRole =t['data']['role'];
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
          userRole.value = t['data']['role'][0];
          userNotificationPreferences.value = {
            "email": t['data']['preference']['email'],
            "push": t['data']['preference']['push'],
            "sms": t['data']['preference']['sms'],
            "marketing": t['data']['preference']['marketing'],
          };
          userFullName = t['data']['fullName'];
          businessName = t['data']['businessName'] ?? "";
          userPhoneNumber.value = t['data']['phone'];

          businessFacebook = t['data']['facebook']??'';
          businessX = t['data']['x']??"";
          businessWebsite = t['data']['website']??'';
          bio = t['data']['bio']??'';
          businessInstagram = t['data']['instagram']??'';
          businessIndustryList = t['data']['industry']??'';
          Get.to(() => Permission());
        }
        else if (tempRole.isNotEmpty) {
          userRole.value = t['data']['role'][0];
          userFullName = t['data']['fullName'];
          userNotificationPreferences.value = {
            "email": t['data']['preference']['email'],
            "push": t['data']['preference']['push'],
            "sms": t['data']['preference']['sms'],
            "marketing": t['data']['preference']['marketing'],
          };
          businessName = t['data']['businessName'] ?? "";
          userPhoneNumber.value = t['data']['phone'];

          businessFacebook = t['data']['facebook']??'';
          businessX = t['data']['x']??'';
          businessWebsite = t['data']['website']??'';
          bio = t['data']['bio']??'';
          businessInstagram = t['data']['instagram']??'';
          businessIndustryList = t['data']['industry']??'';
          userRole == "attendee"
              ? Get.offAll(() => Attendeehomepage())
              : Get.offAll(() => CreatorHomepage());
        }
      }
      else if (statusCode.value == 1) {
        print(t);
        twoFaLoadingError.value = t["message"];
        isTwofaLoading.value = false;
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("Verification Failed", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "${t['message']}",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
      }
      else {
        print("code here $t");
        twoFaLoadingError.value = "An error occurred";
        isTwofaLoading.value=false;
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("An Error Occurred", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Please try again",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
      }
    });
  }


  var newFullName = "".obs;
  var newPhoneNumber = "".obs;
  var newImgUrl = "".obs;
  var newEmail = "".obs;
  var updateProfileError = "".obs;
  var newPhoneError = "".obs;
  var newEmErrorCode = "".obs;

  //set file to null after uploading;
  //image upload
  //File? _image;
  XFile? _newDp;

  XFile? get newDp => _newDp;
  final _picker = ImagePicker();

  Future<void> pickNewDp() async {
    _newDp = await _picker.pickImage(source: ImageSource.gallery);
    if (_newDp != null) {}
  }

  //to server
  Future<int> uploadNewImageToCloud(BuildContext context) async {
    EventApiClient().uploadImage(_newDp!, newImgUrl).then((i) {
      if (i == 0) {
        print(" after $newImgUrl");
        final theBody = {
          "fullName": newFullName.value.isEmpty
              ? "$userFullName"
              : "${newFullName.value}",
          "phone": newPhoneNumber.value.isEmpty
              ? "$userPhoneNumber"
              : "${newPhoneNumber.value}",
          "url": "${newImgUrl.value}",
          "email": newEmail.value.isEmpty ? "$userEmail" : "${newEmail.value}"
        };
        print(theBody);
        //then  other deetails
        ApiClient()
            .makePatchRequest(endPoint: "update-user/$userId", body: theBody)
            .then((p) {
          //print(userId);
          if (statusCode.value == 0) {
            isLoading.value = false;
            print(p);
            userId = p['data']['_id'];
            userEmail.value = p['data']['email'];
            userAvatar = p['data']['url'] ?? "";
            userFullName = p['data']['fullName'] ?? "";
            _newDp = null;
            userRole == "attendee"
                ? Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Attendeehomepage(
                              initialIndex: 0,
                            )))
                : Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreatorHomepage(
                              initialIndex: 0,
                            )));
          } else if (statusCode.value == 1) {
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
                    Icon(
                      Icons.cancel_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                    SizedBox(
                      height: Get.height * 0.01,
                    ),
                    Text("Update Failed", style: Stylings.thicSubtitle),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "${p['message']}",
                      style: Stylings.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        alignment: const Alignment(0, 0),
                        width: Get.width,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Stylings.blue,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "Try again",
                          style: Stylings.body.copyWith(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ));
            print(p);
            isLoading.value = false;
          } else {
            isLoading.value = false;
            updateProfileError.value = "An error occurred";
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
                    Icon(
                      Icons.cancel_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                    SizedBox(
                      height: Get.height * 0.01,
                    ),
                    Text("An Error Occurred", style: Stylings.thicSubtitle),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "Please try again",
                      style: Stylings.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        alignment: const Alignment(0, 0),
                        width: Get.width,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Stylings.blue,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "Try again",
                          style: Stylings.body.copyWith(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ));
          }
        });
      } else if (i == 1) {
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("Upload Failed", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Please try again",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
        return 1;
      } else {
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
                Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red,
                ),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                Text("An Error Occurred", style: Stylings.thicSubtitle),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Please try again",
                  style: Stylings.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    alignment: const Alignment(0, 0),
                    width: Get.width,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Stylings.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Try again",
                      style: Stylings.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
              ],
            ));
        return 2;
      }
    });
    return 2;
  }

  Future updateUserProfile(BuildContext context) async {
    //print(" before $newImgUrl");
    //do checks
    if (newEmErrorCode.value.isNotEmpty || newPhoneError.value.isNotEmpty) {
      return;
    } else if (_newDp == null) {
      isLoading.value = true;
      final theBody = {
        "fullName": newFullName.value.isEmpty
            ? "$userFullName"
            : "${newFullName.value}",
        "phone": newPhoneNumber.value.isEmpty
            ? "$userPhoneNumber"
            : "${newPhoneNumber.value}",
        "url": "$userAvatar",
        "email": newEmail.value.isEmpty ? "$userEmail" : "${newEmail.value}"
      };
      print(theBody);
      ApiClient()
          .makePatchRequest(endPoint: "update-user/$userId", body: theBody)
          .then((p) {
        //print(userId);
        if (statusCode.value == 0) {
          isLoading.value = false;
          print(p);
          userId = p['data']['_id'];
          userEmail.value = p['data']['email'];
          userAvatar = p['data']['url'] ?? "";
          userFullName = p['data']['fullName'] ?? "";
          userRole == "attendee"
              ? Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Attendeehomepage(
                            initialIndex: 0,
                          )))
              : Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreatorHomepage(
                            initialIndex: 0,
                          )));
        } else if (statusCode.value == 1) {
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
                  Icon(
                    Icons.cancel_outlined,
                    size: 40,
                    color: Colors.red,
                  ),
                  SizedBox(
                    height: Get.height * 0.01,
                  ),
                  Text("Update Failed", style: Stylings.thicSubtitle),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${p['message']}",
                    style: Stylings.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Stylings.blue,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Try again",
                        style: Stylings.body.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ));
          print(p);
          isLoading.value = false;
        } else {
          isLoading.value = false;
          updateProfileError.value = "An error occurred";
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
                  Icon(
                    Icons.cancel_outlined,
                    size: 40,
                    color: Colors.red,
                  ),
                  SizedBox(
                    height: Get.height * 0.01,
                  ),
                  Text("An Error Occurred", style: Stylings.thicSubtitle),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Please try again",
                    style: Stylings.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      width: Get.width,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Stylings.blue,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Try again",
                        style: Stylings.body.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ));
        }
      });
    } else {
      isLoading.value = true;
      await uploadNewImageToCloud(context);
    }
  }

  //log out
  logUserOut() {
    Get.find<Oauthsforgoogle>().signOut();
    Get.to(() => Loadingpage(
          doingWhat: 'Logging out',
        ));
    ApiClient().makeGetRequest("remove-session/$userSessionId").then((g) {
      Get.offAll(() => Login());
    });
  }

//END
}
