import 'package:flutter/material.dart';
import 'package:indoor_positioning_system/constants.dart';
import 'package:indoor_positioning_system/navigations/MainScreen.dart';

class SideMenu extends StatefulWidget {
  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String activeRoute = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Drawer(
        backgroundColor: primaryColor,
        child: ListView(
          children: [
            // DrawerHeader(
            //   // child: Image.asset("assets/logo.png"),
            // ),
            DrawerListTile(
              title: "Room1",
              svgSrc: "assets/roomB.png",
              press: () {
                setActiveRoute('/');
                mainNavigatorKey.currentState!.pushNamed('/');
              },
            ),
            DrawerListTile(
              title: "Map",
              svgSrc: "assets/roomB.png",
              press: () {
                setActiveRoute('/map');
                mainNavigatorKey.currentState!.pushNamed('/map');
              },
            ),
            DrawerListTile(
              title: "History",
              svgSrc: "assets/roomB.png",
              press: () {
                setActiveRoute('/tagHistory');
                mainNavigatorKey.currentState!.pushNamed('/tagHistory');
              },
            ),
          ],
        ),
      ),
    );
  }

  void setActiveRoute(String routeName) {
    setState(() {});
    activeRoute = routeName;
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45.0),
      child: SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
          ),
          onPressed: press,
          icon: Image.asset(
            svgSrc,
            color: Colors.black,
            height: 16,
          ),
          label: Text(
            title,
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
