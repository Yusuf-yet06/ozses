import 'package:flutter/material.dart';

class ImperiumDrawer extends StatelessWidget {
  final Color themeColor;

  const ImperiumDrawer({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.2), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text("ÖZSES V7\nIMPERIUM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: themeColor),
            title: const Text("Profil ve Ayarlar",
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.workspace_premium, color: themeColor),
            title: const Text("Premium'a Geç",
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),

          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("v7.0.0 Alpha",
                style: TextStyle(color: Colors.white24, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
