import 'dart:math';
import 'package:attandance/constants/constants.dart';
import 'package:attandance/screens/AddUserScreen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/Colors.dart';
import '../utils/ApiInterceptor.dart';
import 'AttandanceHistoryScreen.dart';

class UsersListScreen extends StatefulWidget {
  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List users = [];
  List<Color> avatarColors = [];
  bool isLoading = true;
  String searchQuery = "";
  final Dio _dio = ApiInterceptor.createDio();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      var response = await _dio.post(
        constants.BASE_URL+constants.GET_USERS,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'role': '1'},
      );

      if (response.statusCode == 200 && response.data['data'] is List) {
        setState(() {
          users = response.data['data'];
          avatarColors = List.generate(users.length, (_) => getRandomColor());
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching users: $e');
    }
  }

  Color getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  void onUserTap(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ID: $userId')),
    );
  }

  Widget buildShimmerEffect() {
    return ListView.builder(
      itemCount: 6, // Showing 6 shimmer items while loading
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
              ),
            ),
            title: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 10,
                width: 100,
                color: Colors.white,
              ),
            ),
            subtitle: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 10,
                width: 150,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List filteredUsers = users
        .where((user) =>
        user['name'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Users List'),
        backgroundColor: thameColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserScreen()));
            },
            icon: const Icon(Icons.add_box, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search by Name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? buildShimmerEffect()
                : filteredUsers.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                var user = filteredUsers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceHistory(userId: user['user_id']),
                        ),
                      );
                      // onUserTap(user['user_id']); // This will show a SnackBar after navigation
                    },
                    leading: CircleAvatar(
                      backgroundColor: avatarColors[index],
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: Text(user['email'] ?? 'No email'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
