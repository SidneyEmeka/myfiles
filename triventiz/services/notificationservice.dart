import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:triventiz/homes/creatorhomepage.dart';

import '../homes/attendeehomepage.dart';
import '../server/getxserver.dart';
import '../utils/stylings.dart';

class NotificationPermissionHandler{

///NOt used anymore
  // Show custom permission dialog
  Future<bool> showCustomPermissionDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title:  Text('Enable Notifications',style: Stylings.thicSubtitle,),
          content:  Text(
            'To stay updated with important information, please allow 3ventiz send you notifications.',style: Stylings.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Get.snackbar("Permission status", "Denied");
              },
              child:  Text('Not Now',style: Stylings.thicSubtitle.copyWith(color: Stylings.blue,fontSize: 10),),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, true);
               // requestNotificationPermission();
                Get.find<Triventizx>().userRole=="attendee" ?Get.offAll(()=>Attendeehomepage()):  Get.offAll(()=>CreatorHomepage());
              },
              child:  Text('Enable',style: Stylings.thicSubtitle.copyWith(color: Stylings.blue,fontSize: 10),),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

