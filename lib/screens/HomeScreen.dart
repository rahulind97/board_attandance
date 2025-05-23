import 'dart:async';

import 'package:attandance/constants/constants.dart';
import 'package:attandance/screens/AttandanceHistoryScreen.dart';
import 'package:attandance/screens/UserListScreen.dart';
import 'package:attandance/utils/Utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../utils/ApiInterceptor.dart';

class HomeScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _time = '';
  String _date = '';
  String _name = '';
  String _checkInTime = '';
  String _checkOutTime = '';
  String _totalTime = '';
  String _status = '';
  String _locationMessage = "Fetching location...";
  double _scale = 1.0; // Initial scale factor
  double _checkInLat = 0.0;
  double _checkInLong= 0.0;
  double _checkInRad= 0.0;
  double _currentLat = 0.0;
  double _currentLang= 0.0;
  String _currentRadius='';
  String _userRole='0';
  String _address = "Fetching address...";
  String? userId ='';
  final now = DateTime.now();
  bool _isLoading = false;
  final Dio _dio = ApiInterceptor.createDio(); // Use ApiInterceptor to create Dio instance

  @override
  void initState() {
    super.initState();
    _updateTime(); // Set initial time
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
    _getCheckInDetails();
    // _getCurrentLocation();
  }

  Future<void> _updateTime() async {
    final now2 = DateTime.now();

    // Format time and date
    final timeFormat = DateFormat('hh:mm a'); // 09:00 AM format
    final dateFormat = DateFormat(
        'MMM dd, yyyy - EEEE'); // Oct 26, 2022 - Wednesday format
    _time = timeFormat.format(now2);
    _date = dateFormat.format(now2);
    _name = (await Utils.getStringFromPrefs(constants.USER_NAME))!;
    userId = await Utils.getStringFromPrefs(constants.USER_ID);
    _userRole= (await Utils.getStringFromPrefs(constants.USER_ROLE))!;
    // _status = 'checkin';
    setState(() {

    });
  }

  String _getGreetingMessage() {
    // final now = DateTime.now();
    final int hour = now.hour;

    if (hour < 12) {
      return 'Good morning! Mark your attendance';
    } else if (hour < 17) {
      return 'Good afternoon! Mark your attendance';
    } else {
      return 'Good evening! Mark your attendance';
    }
  }

  // Function to get current location with permissions
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = "Location permissions are permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationMessage = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        // print("dfdsfsd"+_locationMessage);
        _currentLat=position.latitude;
        _currentLang=position.longitude;
      });



      if (_currentLat != null && _currentLang != null) {
        await _getAddress(_currentLat!, _currentLang!);
        double distanceInMeters = Geolocator.distanceBetween(_checkInLat, _checkInLong, _currentLat, _currentLang);
        print("distance"+distanceInMeters.toString());
        print("distancemtere"+_checkInRad.toString());
        // print("lat"+_currentLat.toString()+"wew"+_currentLang.toString());

        print("radius"+_checkInRad.toString());
        if(distanceInMeters <= _checkInRad){
          print("distance"+distanceInMeters.toString());
          _currentRadius= distanceInMeters.toString();
          _status== '' ? _checkInOut("in") :_checkInOut("out");

        }
        else Fluttertoast.showToast(msg: "You are not in Checkin Range");


      } else {
        Fluttertoast.showToast(msg: "Coordinates are null. Can't fetch address.");
      }

    } catch (e) {
      setState(() => _locationMessage = "Failed to get location: $e");
      Fluttertoast.showToast(msg: _locationMessage);

    }
  }
  // Function to get address from latitude and longitude
  Future<void> _getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          _address = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}";
        });
      }
    } catch (e) {
      print("Failed to get address: $e");
      setState(() {
        _address = "Failed to get address";
      });
    }
  }

  void _checkInOut(String action) async {
    try {


      if (userId == null || _currentLat == null || _currentLang == null || _currentRadius == null) {
        Fluttertoast.showToast(msg: "Missing required data");
        return;
      }
      FormData formData = FormData.fromMap({
        "user_id": userId,
        "action": action,
        "lat": _currentLat.toString(),
        "long": _currentLang.toString(),
        "location": _address,
        "radius": _currentRadius.toString(),
      });
      formData.fields.forEach((field) => print("${field.key}: ${field.value}"));
      final response = await _dio.post(
        "${constants.BASE_URL}${constants.CHECK_IN_OUT}", // Ensure correct endpoint
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = response.data;
        print("Response Data: $data");

        if (data["status"] == "success") {
          Fluttertoast.showToast(msg: "Success: ${data['message']}");
          _getCheckInDetails();
        } else {
          Fluttertoast.showToast(msg: "Error: ${data['message']}");
        }
      } else {
        Fluttertoast.showToast(msg: "Request failed: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }
  void _getCheckInDetails() async {
    setState(() => _isLoading = true);

    try {
      Response response = await _dio.post(
        constants.BASE_URL+constants.GET_DETAILS,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "user_id": await Utils.getStringFromPrefs(constants.USER_ID),
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = response.data;

        print("trace1");
        _checkInTime = (data['data']?['check_in'] != null
            ? Utils.utcToLocalTime(data['data']['check_in'])
            : null)!;
        print("trace2");


        _checkOutTime = (data['data']?['check_out'] != null
            ? Utils.utcToLocalTime(data['data']['check_out'])
            : null) ?? '';

        print("trace3");

        String? checkIn = data['data']?['check_in'];
        String? checkOut = data['data']?['check_out'];
        print("trace4");

// Handle null and empty string cases properly
        DateTime? time1 = (checkIn != null && checkIn.isNotEmpty) ? DateTime.parse(checkIn) : null;
        DateTime? time2 = (checkOut != null && checkOut.isNotEmpty) ? DateTime.parse(checkOut) : null;

        print("trace4");


        if (time1 != null && time2 != null) {
          print("trace6");
          Duration difference = time2.difference(time1);
          // Convert to hh:mm format
          String formattedTime = '${difference.inHours.toString().padLeft(2, '0')}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}';
          _totalTime = formattedTime;
          print('Difference: $formattedTime');
        } else if (time1 != null && time2 == null) {
          print("trace5");
          _totalTime = "N/A";  // Handle empty check-out case
          print('Check-out time is missing');
        } else {
          print("trace6");
          print('Invalid time values');
        }


        _status=data['data']['checkinout_status'];
        _checkInLat = double.tryParse(data['data']['office']['lat'].toString()) ?? 0.0;
        _checkInLong = double.tryParse(data['data']?['office']?['long']?.toString() ?? '') ?? 0.0;
        _checkInRad = double.tryParse(data['data']?['office']?['radius']?.toString() ?? '') ?? 0.0;

        setState(() {

        });
      } else {
        Fluttertoast.showToast(msg: "Login failed: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }
  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => _userRole=='1'? UsersListScreen() : AttendanceHistory(userId:userId.toString(),exportUserId:userId.toString(),)),);
            },
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.manage_history, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Hey $_name!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                _getGreetingMessage(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _time,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
          ),
          Text(
            _date,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Center the Check In/Check Out images
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        print("Check In tapped");
                        if(_status=='inout'){
                          Fluttertoast.showToast(msg: "You alredy punch out");
                        }else
                        {
                          Utils.progressbar(context);
                          await _getCurrentLocation();
                          Navigator.pop(context);
                        }


                      },
                      onTapDown: (_) {
                        setState(() {
                          _scale = 0.90; // Shrink the button on tap
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _scale = 1.0; // Return to normal size after tap
                        });
                        // Perform your navigation or other action here
                        //   String loginTAG = "state";
                        //   Utils.navigateToPageAnimation(context, StateScreenLogin(loginTAG: loginTAG));

                        //  Fluttertoast.showToast(gravity: ToastGravity.CENTER,gravity: ToastGravity.CENTER,msg: "State Login coming soon");
                      },
                      onTapCancel: () {
                        setState(() {
                          _scale = 1.0; // Reset scale if tap is canceled
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        transform: Matrix4.identity()..scale(_scale),
                        child: Image.asset(
                          _status == ''
                              ? 'assets/checkin.png' // Show checkin image
                              : 'assets/checkout.png', // Show checkout image
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Check In, Check Out, and Total Hrs Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconWithLabel('assets/checkin_logo.png', 'Check In', _checkInTime == '' ? '--:--' : _checkInTime),
              _buildIconWithLabel('assets/checkout_logo.png', 'Check Out', _checkOutTime == '' ? '--:--' :_checkOutTime),
              _buildIconWithLabel('assets/total_time.png', 'Total Hrs', _totalTime),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIconWithLabel(String assetPath, String label, String time) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          assetPath,
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 5),
        Text(
          time,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }}