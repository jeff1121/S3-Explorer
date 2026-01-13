import 'package:flutter/material.dart';

import 'package:now_ui_pro_flutter/constants/Theme.dart';

//widgets
import 'package:now_ui_pro_flutter/widgets/navbar.dart';
import 'package:now_ui_pro_flutter/widgets/table-cell.dart';

import 'package:now_ui_pro_flutter/widgets/drawer.dart';

import 'package:now_ui_pro_flutter/screens/notifications-settings.dart';
import 'package:now_ui_pro_flutter/screens/privacy.dart';
import 'package:now_ui_pro_flutter/screens/about.dart';
import 'package:now_ui_pro_flutter/screens/agreement.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late bool switchValueOne;
  late bool switchValueTwo;

  void initState() {
    setState(() {
      switchValueOne = true;
      switchValueTwo = false;
    });
    super.initState();
  }
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Navbar(
          title: "Settings", tags: [], getCurrentPage: () => {}, searchController: searchController, searchOnChanged: () => {},
        ),
        drawer: NowDrawer(currentPage: "Settings"),
        body: Container(
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 16, right: 16),
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Recommended Settings",
                        style: TextStyle(
                            color: NowUIColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 18)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("These are the most important settings",
                        style:
                            TextStyle(color: NowUIColors.time, fontSize: 14)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Use FaceID to signin",
                        style: TextStyle(color: NowUIColors.text)),
                    Switch.adaptive(
                      value: switchValueOne,
                      onChanged: (bool newValue) =>
                          setState(() => switchValueOne = newValue),
                      activeColor: NowUIColors.primary,
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Auto-Lock security",
                        style: TextStyle(color: NowUIColors.text)),
                    Switch.adaptive(
                      value: switchValueTwo,
                      onChanged: (bool newValue) =>
                          setState(() => switchValueTwo = newValue),
                      activeColor: NowUIColors.primary,
                    )
                  ],
                ),
                TableCellSettings(
                    title: "Notifications",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsSettings()));
                    }),
                SizedBox(height: 36.0),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Payment Settings",
                        style: TextStyle(
                            color: NowUIColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 18)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("These are also important settings",
                        style: TextStyle(color: NowUIColors.time)),
                  ),
                ),
                TableCellSettings(title: "Manage Payment Options", onTap: () {  },),
                TableCellSettings(title: "Manage Gift Cards", onTap: () {  },),
                SizedBox(
                  height: 36.0,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Privacy Settings",
                        style: TextStyle(
                            color: NowUIColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 18)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Third most important settings",
                        style: TextStyle(color: NowUIColors.time)),
                  ),
                ),
                TableCellSettings(
                    title: "User Agreement",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserAgreement()));
                    }),
                TableCellSettings(
                    title: "Privacy",
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Privacy()));
                    }),
                TableCellSettings(
                    title: "About",
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => About()));
                    }),
              ],
            ),
          ),
        )));
  }
}
