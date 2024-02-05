import 'package:flutter/material.dart';
import 'package:indoor_positioning_system/main.dart';
import 'package:indoor_positioning_system/navigations/SideMenu.dart';
import 'package:indoor_positioning_system/responsive.dart';

final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class MainScreen extends StatefulWidget {
  // Widget screenName;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // MainScreen({required this.screenName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // We want this side menu only for large screen
            if (Responsive.isDesktop(context))
              Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: SideMenu(),
              ),
            Expanded(
              // It takes 5/6 part of the screen
              flex: 5,
              child: Navigator(
                key: mainNavigatorKey,
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case '/':
                      return MaterialPageRoute(
                          builder: (context) => IndoorPositioningApp());
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
