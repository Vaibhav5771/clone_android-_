import 'package:chats/pallete.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout() {
    // get auth service
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Pallete.borderColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //logo
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: const Text(
                    "Home",
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
                child: ListTile(
                  title: const Text(
                    "Settings",
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  onTap: () {
                    // navigate to settings page
                    Navigator.pop(context);
                    // navigate to settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: ListTile(
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              leading: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onTap: logout,
            ),
          ),
        ],

        // home list tile

        // settings list tile

        // logout list tile
      ),
    );
  }
}
