import 'package:flutter/material.dart';

// screens
import 'package:now_ui_pro_flutter/screens/onboarding.dart';
import 'package:now_ui_pro_flutter/screens/home.dart';
import 'package:now_ui_pro_flutter/screens/profile.dart';
import 'package:now_ui_pro_flutter/screens/settings.dart';
import 'package:now_ui_pro_flutter/screens/register.dart';
import 'package:now_ui_pro_flutter/screens/notifications.dart';
import 'package:now_ui_pro_flutter/screens/articles.dart';
import 'package:now_ui_pro_flutter/screens/components.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Now UI PRO Flutter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Montserrat'),
        initialRoute: '/onboarding',
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => new Home(),
          '/settings': (BuildContext context) => new Settings(),
          "/onboarding": (BuildContext context) => new Onboarding(),
          "/profile": (BuildContext context) => new Profile(),
          "/articles": (BuildContext context) => new Articles(),
          "/components": (BuildContext context) => new Components(),
          "/account": (BuildContext context) => new Register(),
          "/notifications": (BuildContext context) => new Notifications(),
        });
  }
}
