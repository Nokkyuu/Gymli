import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key, required this.user}) : super(key: key);

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (user.name != null) Text(user.name!),
      ],
    );
  }
}
