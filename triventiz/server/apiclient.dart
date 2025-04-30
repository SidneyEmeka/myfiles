import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:triventiz/server/getxserver.dart';
import 'package:triventiz/services/create_event_controller.dart';
import 'package:triventiz/services/created_events_controller.dart';

class ApiClient {
  String userBaseUrl =
      "https://jc2yevcbge.execute-api.eu-north-1.amazonaws.com"; //base url
  Future<Map<String, dynamic>> makePostRequest(
      {required String endPoint,
      required Map<String, dynamic> body,
      String contentType = 'application/json'}) async {
    try {
      // Convert the body into JSON
      String jsonBody = json.encode(body);

      // Set headers
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse("$userBaseUrl/$endPoint"),
        headers: headers,
        body: jsonBody,
      );
      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  //
  Future<Map<String, dynamic>> makeGetRequest(String endPoint) async {
    try {
      // Make the GET request
      final response = await http.get(Uri.parse("$userBaseUrl/$endPoint"),
          headers: {
            'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
          });

      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        // print('Request successful');
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return data;
      } else {
        // Request failed
        //print('Request failed with status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      // Handle any errors
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  Future<dynamic> makePatchRequest(
      {required String endPoint,
      required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    try {
      // Default headers
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };

      // Set headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Send PATCH request
      final response = await http.patch(Uri.parse("$userBaseUrl/$endPoint"),
          headers: headers, body: json.encode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

//
//   Future<Map<String, dynamic>> makePatchRequest(String url, Map<String, dynamic> body,) async {
//     try {
//       Map<String, String> headers = {
//         'Accept': 'application/json',
//         "Content-Type": "application/json",
//         // Add any other headers you need, e.g., authentication tokens
//         'Authorization': 'Bearer ${Get.find<Jollofx>().userTokens["accessToken"]}',
//       };
//
//       final response = await http.patch(
//         Uri.parse(url),
//         body: jsonEncode(body),
//         headers: headers,
//       );
//      //print(response.statusCode);
//
//       if (response.statusCode == 200) {
//         Get.find<Jollofx>().statusCode.value = 0;
//         Map<String,dynamic>  reply=jsonDecode(response.body);
//        // print(reply);
//         return reply;
//       } else {
//         //print('Error making PATCH request: ${response.statusCode}');
//         Get.find<Jollofx>().statusCode.value = 1;
//         return {"1":"@"};
//       }
//     } catch (e) {
//       Get.find<Jollofx>().statusCode.value = 2;
//       //print('Exception during PATCH request: $e');
//       return {"2":"@"};
//     }
//   }
//
//   Future<Map<String, dynamic>> makePutRequest(String url,String id) async {
//     final formedUrl = '$url/$id';
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${Get.find<Jollofx>().userTokens["accessToken"]}',
//     };
//
//     try {
//       final response = await http.put(Uri.parse(formedUrl), headers: headers);
//
//       if (response.statusCode == 200) {
//         Map<String, dynamic> returned = jsonDecode(response.body);
//         Get.find<Jollofx>().statusCode.value = 0;
//         //print('Resource updated successfully');
//         //print('Response: ${response.body}');
//         return returned;
//       } else {
//         Get.find<Jollofx>().statusCode.value = 1;
//        // print('Failed to update resource. Status code: ${response.statusCode}');
//         //print('Response: ${response.body}');
//         return {};
//       }
//     } catch (e) {
//       Get.find<Jollofx>().statusCode.value = 2;
//      // print('Error occurred: $e');
//       return {};
//     }
//   }
//
}

class EventApiClient {
  String eventBaseUrl =
      //"https://syasf93cr4.execute-api.eu-north-1.amazonaws.com"; //base url
      "https://udt357wt87.execute-api.eu-north-1.amazonaws.com"; //base url

  Future<Map<String, dynamic>> makePostRequest(
      {required String endPoint,
      required Map<String, dynamic> body,
      String contentType = 'application/json'}) async {
    try {
      // Convert the body into JSONz
      String jsonBody = json.encode(body);

      // Set headers
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse("$eventBaseUrl/$endPoint"),
        headers: headers,
        body: jsonBody,
      );
      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  //
  Future<Map<String, dynamic>> makeGetRequest(String endPoint) async {
    try {
      // Make the GET request
      final response = await http.get(Uri.parse("$eventBaseUrl/$endPoint"),
          headers: {
            'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
          });

      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        // print('Request successful');
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return data;
      } else {
        // Request failed
        //print('Request failed with status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      // Handle any errors
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  Future<num> uploadImage(XFile theImage, RxString imgUrl) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/ds1ll9kkv/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'work-upload'
        ..files.add(await http.MultipartFile.fromPath('file', theImage.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseMap = jsonDecode(responseData);
      if (response.statusCode == 200) {
        imgUrl.value = responseMap['secure_url'];
        //Get.find<Triventizx>().newImgUrl.value = responseMap['secure_url'];
        return 0;
      } else {
        //print('Upload failed: ${responseMap['error']['message']}');
        return 1;
      }
    } catch (e) {
      //print('Error uploading image: $e');
      return 2;
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> images) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/ds1ll9kkv/image/upload');
      List<String> uploadedUrls = [];

      // Upload each image one by one
      for (XFile image in images) {
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = 'work-upload'
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final responseMap = jsonDecode(responseData);

        if (response.statusCode == 200) {
          uploadedUrls.add(responseMap['secure_url']);
        } else {
          //print('Upload failed: ${responseMap['error']['message']}');
        }
      }

      return uploadedUrls;
    } catch (e) {
      //print('Error uploading images: $e');
      return [];
    }
  }

  Future<dynamic> makePatchRequest(
      {required String endPoint,
        required Map<String, dynamic> body,
        Map<String, String>? headers}) async {
    try {
      // Default headers
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };

      // Set headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Send PATCH request
      final response = await http.patch(Uri.parse("$eventBaseUrl/$endPoint"),
          headers: headers, body: json.encode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      //print(e.toString());
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

//end
}

class NotificationApiClient {
  String notificationBaseUrl =
      "https://qtjwlorqq9.execute-api.eu-north-1.amazonaws.com"; //base url

  Future<Map<String, dynamic>> makePostRequest(
      {required String endPoint,
      required Map<String, dynamic> body,
      String contentType = 'application/json'}) async {
    try {
      // Convert the body into JSON
      String jsonBody = json.encode(body);

      // Set headers
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse("$notificationBaseUrl/$endPoint"),
        headers: headers,
        body: jsonBody,
      );
      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  //
  Future<Map<String, dynamic>> makeGetRequest(String endPoint) async {
    try {
      // Make the GET request
      final response = await http
          .get(Uri.parse("$notificationBaseUrl/$endPoint"), headers: {
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      });

      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        // print('Request successful');
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return data;
      } else {
        // Request failed
        //print('Request failed with status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      // Handle any errors
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "Ans error occurred"};
      return outOfScppeError;
    }
  }

  Future<num> uploadImage(XFile theImage, RxString imgUrl) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/ds1ll9kkv/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'work-upload'
        ..files.add(await http.MultipartFile.fromPath('file', theImage.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseMap = jsonDecode(responseData);
      if (response.statusCode == 200) {
        imgUrl.value = responseMap['secure_url'];
        return 0;
      } else {
        print('Upload failed: ${responseMap['error']['message']}');
        return 1;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return 2;
    }
  }

  Future<Map<String, dynamic>> makePutRequest(String endpoint) async {
    try {
      final url = Uri.parse('$notificationBaseUrl/$endpoint');

      // Set headers for the request
      final headers = {
        'Authorization':
            'Bearer ${Get.find<Triventizx>().userAccessToken}' // Replace with your actual auth token
      };
      // Make the PUT request
      final response = await http.put(
        url,
        headers: headers,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        // print('Request successful');
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return data;
      } else {
        // Request failed
        //print('Request failed with status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error updating user: $e');
      return {};
    }
  }

//end
}

class PaymentApiClient {
  String paymentBaseUrl =
      //"https://op4c2elbdk.execute-api.eu-north-1.amazonaws.com"; //base url
      "https://15n8envs6e.execute-api.eu-north-1.amazonaws.com"; //base url
  Future<Map<String, dynamic>> makePostRequest(
      {required String endPoint,
        required Map<String, dynamic> body,
        String contentType = 'application/json'}) async {
    try {
      // Convert the body into JSON
      String jsonBody = json.encode(body);

      // Set headers
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse("$paymentBaseUrl/$endPoint"),
        headers: headers,
        body: jsonBody,
      );
      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  //
  Future<Map<String, dynamic>> makeGetRequest(String endPoint) async {
    try {
      // Make the GET request
      final response = await http.get(Uri.parse("$paymentBaseUrl/$endPoint"),
          headers: {
            'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
          });

      // Check the status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        // print('Request successful');
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return data;
      } else {
        // Request failed
        //print('Request failed with status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      // Handle any errors
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

  Future<dynamic> makePatchRequest(
      {required String endPoint,
        required Map<String, dynamic> body,
        Map<String, String>? headers}) async {
    try {
      // Default headers
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };

      // Set headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Add any other headers you need, e.g., authentication tokens
        'Authorization': 'Bearer ${Get.find<Triventizx>().userAccessToken}'
      };

      // Send PATCH request
      final response = await http.patch(Uri.parse("$paymentBaseUrl/$endPoint"),
          headers: headers, body: json.encode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> successReturnbody = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 0;
        return successReturnbody;
      } else {
        //print(response.body);
        Map<String, dynamic> errorMessage = jsonDecode(response.body);
        Get.find<Triventizx>().statusCode.value = 1;
        return errorMessage;
      }
    } catch (e) {
      Get.find<Triventizx>().statusCode.value = 2;
      Map<String, dynamic> outOfScppeError = {"e": "An error occurred"};
      return outOfScppeError;
    }
  }

//
//   Future<Map<String, dynamic>> makePatchRequest(String url, Map<String, dynamic> body,) async {
//     try {
//       Map<String, String> headers = {
//         'Accept': 'application/json',
//         "Content-Type": "application/json",
//         // Add any other headers you need, e.g., authentication tokens
//         'Authorization': 'Bearer ${Get.find<Jollofx>().userTokens["accessToken"]}',
//       };
//
//       final response = await http.patch(
//         Uri.parse(url),
//         body: jsonEncode(body),
//         headers: headers,
//       );
//      //print(response.statusCode);
//
//       if (response.statusCode == 200) {
//         Get.find<Jollofx>().statusCode.value = 0;
//         Map<String,dynamic>  reply=jsonDecode(response.body);
//        // print(reply);
//         return reply;
//       } else {
//         //print('Error making PATCH request: ${response.statusCode}');
//         Get.find<Jollofx>().statusCode.value = 1;
//         return {"1":"@"};
//       }
//     } catch (e) {
//       Get.find<Jollofx>().statusCode.value = 2;
//       //print('Exception during PATCH request: $e');
//       return {"2":"@"};
//     }
//   }
//
//   Future<Map<String, dynamic>> makePutRequest(String url,String id) async {
//     final formedUrl = '$url/$id';
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${Get.find<Jollofx>().userTokens["accessToken"]}',
//     };
//
//     try {
//       final response = await http.put(Uri.parse(formedUrl), headers: headers);
//
//       if (response.statusCode == 200) {
//         Map<String, dynamic> returned = jsonDecode(response.body);
//         Get.find<Jollofx>().statusCode.value = 0;
//         //print('Resource updated successfully');
//         //print('Response: ${response.body}');
//         return returned;
//       } else {
//         Get.find<Jollofx>().statusCode.value = 1;
//        // print('Failed to update resource. Status code: ${response.statusCode}');
//         //print('Response: ${response.body}');
//         return {};
//       }
//     } catch (e) {
//       Get.find<Jollofx>().statusCode.value = 2;
//      // print('Error occurred: $e');
//       return {};
//     }
//   }
//
} //Just for  storing  and sending creator bank details not making payments
