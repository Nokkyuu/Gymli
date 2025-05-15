import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/profile_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  Credentials? _credentials;

  late Auth0Web auth0;

  @override
  void initState() {
    super.initState();
    auth0 = Auth0Web('dev-aqz5a2g54oer01tk.us.auth0.com',
        'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa');

    auth0.onLoad().then((final credentials) => setState(() {
          _credentials = credentials;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_credentials == null)
          ElevatedButton(
              onPressed: () =>
                  auth0.loginWithRedirect(redirectUrl: 'http://localhost:3000'),
              child: const Text("Log in"))
        else
          Column(
            children: [
              ProfileView(user: _credentials!.user),
              ElevatedButton(
                  onPressed: () async {
                    await auth0.logout(returnToUrl: 'http://localhost:3000');
                  },
                  child: const Text("Log out"))
            ],
          )
      ],
    );
  }
}
