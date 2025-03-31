import 'dart:math';

import 'package:attandance/screens/LoginScreen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/constants.dart';
import '../utils/ApiInterceptor.dart';
import '../utils/Utils.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  DateTime? startDate;
  DateTime? endDate;
  final Dio _dio = ApiInterceptor.createDio(); // Use ApiInterceptor to create Dio instance
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _getAttandanceHistory();
    });
  }
  // Future<void> initfdf() async {   // Change return type to Future<void>
  //   await _getAttandanceHistory();
  // }
  //
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
      return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();
  }
  void _getAttandanceHistory() async {
    Utils.progressbar(context);
    try {
      final response = await _dio.post(
        constants.BASE_URL + constants.IN_OUT_HISTORY,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          "user_id": await Utils.getStringFromPrefs(constants.USER_ID),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        List<dynamic> dataList = data['data'];

        List<Map<String, dynamic>> attendanceData2 = dataList.map((item) {
          DateTime date = DateTime.parse(item['date']);

          // Handle "N/A" values gracefully
          String checkIn = item['check_in'] != "N/A"
              ? Utils.utcToLocalTime(item['check_in'])
              : "--";
          String checkOut = item['check_out'] != "N/A"
              ? Utils.utcToLocalTime(item['check_out'])
              : "--";

          String hours = "--";

          if (item['check_in'] != "N/A" && item['check_out'] != "N/A") {
            DateTime inTime = DateTime.parse(item['check_in']);
            String formattedTime = DateFormat('hh:mm a').format(inTime);
            DateTime outTime = DateTime.parse(item['check_out']);
            String formattedTime2 = DateFormat('hh:mm a').format(inTime);
            Duration diff = outTime.difference(inTime);
            hours = _formatDuration(diff);
          }

          return {
            'date': date,
            'in': checkIn,
            'out': checkOut,
            'hours': hours,
          };
        }).toList();

        setState(() {
          // Assign the transformed data to the state variable
          attendanceData = attendanceData2;
        });

        Navigator.pop(context);
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Failed: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  /// Helper function to format datetime strings into "hh:mm a"
  String _formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
        "${dateTime.hour < 12 ? 'AM' : 'PM'}";
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
          const Text(
            'Attendance History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoginScreen()),);

            },
          )
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
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Widget _buildAttendanceList() {
    List<Map<String, dynamic>> data = filteredData;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No attendance records found for this range.',
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
          )
        ],
      ),
    );
  }

}
