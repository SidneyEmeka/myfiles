import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../homes/attendeehomepage.dart';
import '../homes/creatorhomepage.dart';
import '../models/notificationsmodel.dart';
import '../server/apiclient.dart';
import '../server/getxserver.dart';

class NotificationsController extends GetxController {
  var nIsLoading = false.obs; //chaange to false
  var notifications = [].obs;

  Future getNotifications() async {
    nIsLoading.value = true;
    await NotificationApiClient()
        .makeGetRequest('user-notification/${Get.find<Triventizx>().userId}')
        .then((e) {
      if (Get.find<Triventizx>().statusCode.value == 0) {
        print(e);
        // //notifications = e.data;
        // final notificationsModel = notificationsModelFromJson(jsonEncode(e));
        notifications.value = e["data"];
        nIsLoading.value = false;
        //print(notifications);
      } else if (Get.find<Triventizx>().statusCode.value == 1) {
        print("ListNotiserror $e");
        nIsLoading.value = false;
      } else {
        print(e);
        nIsLoading.value = false;
      }
    });
  }

  Future readNotification(String notificationId) async {
    print(notificationId);
    await NotificationApiClient()
        .makePutRequest('mark-read/$notificationId')
        .then((r) {
      print(r);
      //update
      final theReadIndex =
          notifications.indexWhere((theNot) => theNot['_id'] == notificationId);
      notifications[theReadIndex] = r['data'];

      ///FOr updating the whole list
      //  NotificationApiClient().makeGetRequest('user-notification/${Get
      //      .find<Triventizx>()
      //      .userId}').then((e){
      //    if (Get.find<Triventizx>().statusCode.value == 0) {
      //      //notifications = e.data;
      //      notifications.value = e["data"];
      //      nIsLoading.value = false;
      // //     print(notifications);
      //    }
      //  });
    });
  }

  ///push notification
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  ///initialize it
  Future<void> initNotification() async {
    if (_isInitialized) return;
    //for andriod
    const initSettingsAndriod =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    //for ios
    const initSettingsIos = DarwinInitializationSettings(
      //they are requested on permission page
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    //init settings
    const initSettings = InitializationSettings(
        android: initSettingsAndriod, iOS: initSettingsIos);
    //initialize the plugin
    await notificationPlugin.initialize(initSettings).whenComplete(() {
      _isInitialized = true;
    });
  }

  ///Handling Permissions
  Future requestNotificationPermision() async {
    if (Platform.isIOS) {
      await notificationPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      Get.find<Triventizx>().userRole == "attendee"
          ? Get.offAll(() => Attendeehomepage())
          : Get.offAll(() => CreatorHomepage());
    } else if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      //explicit notifications requests only work on API33+
      if (androidInfo.version.sdkInt >= 33) {
        await notificationPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        Get.find<Triventizx>().userRole == "attendee"
            ? Get.offAll(() => Attendeehomepage())
            : Get.offAll(() => CreatorHomepage());
      } else {
        Get.find<Triventizx>().userRole == "attendee"
            ? Get.offAll(() => Attendeehomepage())
            : Get.offAll(() => CreatorHomepage());
      }
    }
  }

  ///NOTIFICATION DETAIL SETUP
  NotificationDetails notificationDetails(String? title, String? body) {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            'daily_channel_id', '3ventiz Notifications',
            channelDescription: '3ventiz Notification Channel',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation("$body")),
        iOS: DarwinNotificationDetails());
  }

  ///SHOW NOTIFICATION
  Future<void> showNotification(
      {int id = 1, String? title, String? body}) async {
    return notificationPlugin.show(
        id, title, body, notificationDetails(title, body));
  }

  bool _isConnected = false;

// String websocketUrl = "wss://echo.websocket.org";
  String websocketUrl =
      "wss://rpz7bb1dk1.execute-api.eu-north-1.amazonaws.com/dev?token=";

  //wss://uz0t28cxzg.execute-api.eu-north-1.amazonaws.com/dev?token=${token}
  Future<bool> connectToWebSocket() async {
    // print("${Get.find<Triventizx>().userAccessToken}");
    // print("tryeuw");
    //if (_isConnected) return true;
    try {
      final _channel = IOWebSocketChannel.connect(
          "$websocketUrl${Get.find<Triventizx>().userAccessToken}");
      //final _channel = IOWebSocketChannel.connect("$websocketUrl");
      print('Notifications connected');
      _channel.stream.listen(
        (message) {
          print(message);
          final data = jsonDecode(message);
          //  print('Received notification: $data');

          // Show local notification
          showNotification(
            title: data['message']['title'] ?? 'New Notification',
            body: data['message']['body'] ?? '',
            //  payload: data['payload'] ?? '',
          );
        },
        onError: (error) {
          print('WebSocket error: ${error}');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          // Implement reconnection logic here
          _reconnect();
        },
      );

      // // Send subscription message if needed
      // _channel.sink.add(jsonEncode({
      //   'action': 'subscribe',
      //   'userId': '${Get.find<Triventizx>().userId}',
      // }));

      _isConnected = true;
      return true;
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> _reconnect() async {
    // Wait before attempting to reconnect
    await Future.delayed(const Duration(seconds: 5));
    connectToWebSocket();
  }
}
