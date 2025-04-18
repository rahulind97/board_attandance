import 'dart:io';
import 'dart:math';

import 'package:attandance/screens/LoginScreen.dart';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/Colors.dart';
import '../constants/constants.dart';
import '../utils/ApiInterceptor.dart';
import '../utils/Utils.dart';

class AttendanceHistory extends StatefulWidget {
  final String userId;
  final String exportUserId;

  const AttendanceHistory({
    super.key,
    required this.userId,
    required this.exportUserId,
  });

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  DateTime? startDate;
  DateTime? endDate;
  bool _isLoading = true;  // Flag to track loading state

  DateTime now = DateTime.now();
  final Dio _dio = ApiInterceptor.createDio(); // Use ApiInter
  // ceptor to create Dio instance
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      // requestStoragePermission();
      _getAttandanceHistory();
    });
  }
  late List<Map<String, dynamic>> attendanceData = [
    // {'date': DateTime(2025, 3, 6), 'in': '09:40 AM', 'out': '06:30 PM', 'hours': '08:50'},
    // {'date': DateTime(2025, 3, 7), 'in': '09:30 AM', 'out': '06:30 PM', 'hours': '09:00'},
    // {'date': DateTime(2025, 3, 8), 'in': '09:00 AM', 'out': '08:00 PM', 'hours': '11:00'},
    // {'date': DateTime(2025, 3, 9), 'in': '09:08 AM', 'out': '06:05 PM', 'hours': '08:13'},
    // {'date': DateTime(2025, 3, 10), 'in': '10:00 AM', 'out': '07:00 PM', 'hours': '09:00'},
  ];
  // List<Map<String, String>> notifications = [];

  List<Map<String, dynamic>> get filteredData {
    if (startDate == null || endDate == null) {
      return attendanceData;
    }
    return attendanceData.where((entry) {
      DateTime date = entry['date'];
      return date.isAfter(startDate!.subtract(const Duration(days: 1))) && date.isBefore(endDate!.add(const Duration(days: 1)));}).toList();
  }
  void _getAttandanceHistory() async {
    // Utils.progressbar(context);
    DateTime defaultStartDate = DateTime(now.year, now.month, 1);
// Check if startDate is null or empty, and set the default start date if true
    Object startDate1 = (startDate == null || startDate=="")
        ? DateFormat('yyyy-MM-dd').format(defaultStartDate)
        : startDate!;

// Check if endDate is null or empty, and set the current date if true
    Object endDate2 = (endDate == null || endDate=="")
        ? DateFormat('yyyy-MM-dd').format(now)
        : endDate!;
    try {
      final response = await _dio.post(
        constants.BASE_URL + constants.IN_OUT_HISTORY,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          "user_id": await Utils.getStringFromPrefs(constants.USER_ROLE)=="1" ?widget.exportUserId : widget.userId,
          "role": await Utils.getStringFromPrefs(constants.USER_ROLE),
          "start_date": startDate1,
          "end_date": endDate2
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Validate if 'data' exists and is not null or empty
        if (data != null && data.containsKey('data') && data['data'] != null && (data['data'] as List).isNotEmpty) {
          List<dynamic> dataList = data['data'];
          print("User ID: ${widget.userId}");
          print("Attendance data: $dataList");

          List<Map<String, dynamic>> attendanceData2 = dataList.map((item) {
            DateTime date = DateTime.parse(item['date']);

            String? rawCheckIn = item['check_in'];
            String? rawCheckOut = item['check_out'];

            String checkIn = (rawCheckIn != null && rawCheckIn != "N/A" && rawCheckIn.isNotEmpty)
                ? Utils.utcToLocalTime(rawCheckIn)
                : "--";
            String checkOut = (rawCheckOut != null && rawCheckOut != "N/A" && rawCheckOut.isNotEmpty)
                ? Utils.utcToLocalTime(rawCheckOut)
                : "--";

            String hours = "--";
            if (rawCheckIn != null && rawCheckOut != null &&
                rawCheckIn != "N/A" && rawCheckOut != "N/A" &&
                rawCheckIn.isNotEmpty && rawCheckOut.isNotEmpty) {
              try {
                DateTime inTime = DateTime.parse(rawCheckIn);
                DateTime outTime = DateTime.parse(rawCheckOut);
                Duration diff = outTime.difference(inTime);
                hours = _formatDuration(diff);
              } catch (e) {
                print("Error parsing time: $e");
              }
            }

            return {
              'date': date,
              'in': checkIn,
              'out': checkOut,
              'hours': hours,
            };
          }).toList();

          setState(() {
            attendanceData = attendanceData2;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(msg: "No attendance data available");
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: "Failed: ${response.statusCode}");
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error: $e");
      print("Error: $e");
    }

  }

  void _exportAttandanceHistory() async {
    Utils.progressbar(context);
    DateTime defaultStartDate = DateTime(now.year, now.month, 1);
    Object startDate1 = (startDate == null || startDate=="")
        ? DateFormat('yyyy-MM-dd').format(defaultStartDate)
        : startDate!;

    Object endDate2 = (endDate == null || endDate=="")
        ? DateFormat('yyyy-MM-dd').format(now)
        : endDate!;
    try {
      final response = await _dio.post(
        constants.BASE_URL + constants.EXPORT_HISTORY,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          "user_id": widget.userId,
          "export_user_id": widget.exportUserId,
          "role": await Utils.getStringFromPrefs(constants.USER_ROLE),
          "start_date": startDate1,
          "end_date": endDate2,
        },
      );
      final data = response.data;
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])),);
      }else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.red,),);
      }
    } catch (e) {
      Navigator.pop(context);
      _isLoading = false; // Data is loaded, stop loading animation
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  /// Helper function to format Duration into "hh:mm"
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance History"),
        backgroundColor: thameColor,  // You can change this color to any you'd prefer
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () {
              _exportAttandanceHistory();
              },
          ),
        ],
// Optional, to remove the shadow if you don't want it
      ),

      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // _buildHeader(),
            _buildDateRangePicker(context),
            Expanded(child: _buildAttendanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8), // Space between back button and title
              const Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate != null && endDate != null
                    ? '${DateFormat.yMMMd().format(startDate!)} - ${DateFormat.yMMMd().format(endDate!)}'
                    : 'Select Date Range',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range, color: Colors.red),
                onPressed: () => _selectDateRange(context),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal, // 👉 Header background color
              onPrimary: Colors.white, // 👉 Header text/icon color
              onSurface: Colors.black, // 👉 Default text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // 👉 Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return _buildShimmerEffect();  // Show shimmer effect while loading
    }
    _isLoading=false;
    List<Map<String, dynamic>> data = filteredData;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No attendance records found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        var item = data[index];
        DateTime date = item['date'];

        return _buildAttendanceCard(
          DateFormat.d().format(date),
          DateFormat.E().format(date),
          item['in'],
          item['out'],
          item['hours'],
          // Colors.red,
        );
      },
    );
  }

  Widget _buildAttendanceCard(String day, String weekday, String punchIn, String punchOut, String hours) {
    // Generate a random color
    final Random random = Random();
    final Color randomColor = Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: randomColor,  // 🎯 Use the random color here
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat.E().format(DateTime(2025, 3, int.parse(day))),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    '$punchIn          $punchOut',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Punch In          Punch Out',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '$hours',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      'Total Hours',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],

          ),
        ],

      ),
    );
  }
  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,  // Number of shimmer items you want to display
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
