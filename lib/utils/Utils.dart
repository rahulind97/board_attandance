import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  static Future<void> saveStringToPrefs(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  static Future<String?> getStringFromPrefs(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }


  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('No Internet Connection'),
            content: Text('Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  static String formDataToString(FormData formData) {
    StringBuffer buffer = StringBuffer();

    for (var entry in formData.fields) {
      buffer.write('${entry.key}: ${entry.value}\n');
    }

    return buffer.toString();
  }
  static int getIdBySubName(String jsonResponse, String subName) {
    final decodedResponse = json.decode(jsonResponse);

    if (decodedResponse['data'] != null &&
        decodedResponse['data']['data'] != null &&
        decodedResponse['data']['data']['PacketInBankClasswise'] != null) {
      final packetInBankClasswise = decodedResponse['data']['data']['PacketInBankClasswise'];

      for (var packet in packetInBankClasswise) {
        if (packet['subName'] == subName) {
          return packet['id'];
        }
      }
    }

    // If the subName is not found, you can return a default value or handle it as needed.
    return -1; // Return -1 as an example for not found.
  }
  static void AlertGoToSetting(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('Alert'),
              content: Text(
                  "To enhance the security and authenticity of student examinations, the app requires access to your location and camera. These permissions are necessary for verifying teacher presence and identity during exams. Please enable both location and camera access to ensure a smooth and secure examination process. You can update these settings in your device's Settings app."),
              actions: [
                TextButton(
                  child:
                  Text('Close', style: TextStyle(color: Color(0xFF01579B))),
                  // Negative button
                  onPressed: () {
                    // Close the dialog without performing any action
                    exit(0);
                  },
                ),
                TextButton(
                  child: Text('I confirm',
                      style: TextStyle(color: Color(0xFF01579B))),
                  onPressed: () {
                    // Close the dialog
                    Navigator.of(context).pop();

                    // Open app settings
                    // OpenAppSettings.openAppSettings();
                  },
                ),
              ],
            ));
  }

  static void PermisionAlert(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('Alert'),
              content: Text(
                  "To enhance the security and authenticity of student examinations, the app requires access to your location and camera. These permissions are necessary for verifying teacher presence and identity during exams. Please enable both location and camera access to ensure a smooth and secure examination process. You can update these settings in your device's Settings app."),
              actions: [
                TextButton(
                  child:
                  Text('Close', style: TextStyle(color: Color(0xFF01579B))),
                  // Negative button
                  onPressed: () {
                    // Close the dialog without performing any action
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }


  static void showAlertDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Set background color to white
          title: Text('Alert', style: TextStyle(color: Colors.red)), // Set title color to red
          content: Text(title),
          elevation: 5, // Add a slight elevation to create a shadow effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Round the corners of the dialog
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10), // Reduce vertical padding
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.red), // Set button text color to red
              ),
            ),
          ],
        );
      },
    );
  }
  static String convertListToString(String input) {
    // Remove any commas from the input string
    String result = input.replaceAll(',', '');
    String result1 = result.replaceAll('[', '');
    String result2 = result1.replaceAll(']', '');
    String result3 = result2.replaceAll(' ', '');

    return result3;
  }

 static void showCustomAlertDialog(
      BuildContext context, {
        required String title,
        String? content, // Optional content
        String positiveButtonText = 'OK',
        VoidCallback? onPositivePressed, // Optional callback for positive button
        String? negativeButtonText,
        VoidCallback? onNegativePressed, // Optional callback for negative button
        bool isDismissible = true, // Allow user to dismiss by tapping outside
      })


 {
    showDialog(
      context: context,
      barrierDismissible: isDismissible, // Control dismiss on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content != null ? Text(content) : null, // Only show content if provided
          actions: [
            if (negativeButtonText != null) // Conditionally add negative button
              TextButton(
                onPressed: onNegativePressed,
                child: Text(negativeButtonText),
              ),
            TextButton(
              onPressed: onPositivePressed ?? () => Navigator.pop(context), // Default close on positive button press
              child: Text(positiveButtonText),
            ),
          ],
        );
      },
    );
  }


  static bool isStrongPassword(String password) {
    // Define a regular expression pattern to match the password criteria
    RegExp regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\-]).{8,}$',
    );

    // Use the RegExp's hasMatch method to check if the password matches the pattern
    return regex.hasMatch(password);
  }

 static Future<bool> checkNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }
  // static String getCurrentFormattedDate() {
  //   DateTime currentDate = DateTime.now();
  //   return DateFormat('dd-MM-yyyy').format(currentDate);
  // }

  static void addAllUniqueClasses(String jsonResponse, List<String> dropdownItemList) {
    final decodedResponse = json.decode(jsonResponse);

    if (decodedResponse['data'] != null &&
        decodedResponse['data']['data'] != null &&
        decodedResponse['data']['data']['PacketInBank'] != null) {
      final packetInBank = decodedResponse['data']['data']['PacketInBank'];

      for (var packet in packetInBank) {
        String currentClass = packet['class'];
        if (!dropdownItemList.contains(currentClass)) {
          dropdownItemList.add(currentClass);
        }
      }
    }
  }
  static String replaceSchoolCodeInJson(String originalJson, String newSchoolCode) {
    try {
      // Parse the original JSON string
      Map<String, dynamic> jsonData = json.decode(originalJson);

      // Replace the "SchoolCode" value with the newSchoolCode
      jsonData['SchoolCode'] = newSchoolCode;

      // Convert the modified data back to a JSON string
      String modifiedJson = json.encode(jsonData);

      return modifiedJson;
    } catch (e) {
      // Handle JSON parsing errors
      print("Error parsing or modifying JSON: $e");
      return originalJson; // Return the original JSON on error
    }
  }
  static void printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) =>   print(match.group(0)));
  }
  static int getNoOfBlankSheetFromJsonString(String jsonString, String desiredClass) {
    final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
    final List<dynamic> table = jsonResponse['data']['data']['Table'];

    for (var entry in table) {
      if (entry['class'] == desiredClass) {
        return entry['NoOfBlankSheet'];
      }
    }

    return 0; // Return a default value if the class is not found
  }

  static int getNoOfBlankSheetForClass(String responseJson, String targetClass) {
    Map<String, dynamic> jsonResponse = json.decode(responseJson);

    if (jsonResponse.containsKey('data') && jsonResponse['data'].containsKey('data')) {
      List<dynamic> tableData = jsonResponse['data']['data']['Table'];

      for (var entry in tableData) {
        String classs = entry['Class'];
        int noOfBlankSheet = entry['NoOfBlankSheet'];

        if (classs == targetClass) {
          return noOfBlankSheet;
        }
      }
    }

    // Return a default value or handle the case when the class is not found
    return 0;
  }



  static String formDataToStringg(FormData formData) {
    StringBuffer buffer = StringBuffer();

    for (var entry in formData.fields) {
      buffer.write('${entry.key}: ${entry.value}\n');
    }

    return buffer.toString();
  }

// ... Add more methods for different data types as needed
}