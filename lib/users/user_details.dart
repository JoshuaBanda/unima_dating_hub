import 'package:flutter/material.dart';
import '/loadingWidgets/current_user_api_service.dart';
import '/users/users.dart';

class UserDetails extends StatefulWidget {

  final int? userId;
  const UserDetails({super.key, required this.userId});


  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  late User _user;

  Future<void> _loadUser() async{
    final currentUserApiService=CurrentUserApiService();
    final user=await currentUserApiService.getCurrentUser(5);
    setState(() {
      _user=user;
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
