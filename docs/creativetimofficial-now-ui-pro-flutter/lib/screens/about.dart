import 'package:flutter/material.dart';

import 'package:now_ui_pro_flutter/constants/Theme.dart';

import 'package:now_ui_pro_flutter/widgets/navbar.dart';

String aboutText1 =
    "Shares of the giant tech companies tumbled on Monday, pushing major stock market indexes into negative territory for November and leaving investors clinging to a gain of less than 1 percent for the year.";
String aboutText2 =
    "Apple, Amazon, Facebook and Microsoft were all down by more than 3 percent shortly after midday, as investors digested a series of negative reports that suggested they face growing risks to their extraordinary pipeline of profits.";
String aboutText3 =
    "In an interview with Axios, Tim Cook, the chief executive of Apple, called new regulations for the tech sector “inevitable.” That prospect could significantly raise compliance costs for tech firms and potentially weigh on profits of the iPhone maker as well as other large, dominant tech companies like Amazon and Microsoft. Facebook has already seen its share price plummet after it reported that it significantly increased the amount it spends on security.";
String aboutText4 =
    "The beauty in opening with “tell me about yourself” is that it allows you to start a conversation without the fear that you’re going to inadvertently make someone uncomfortable or self-conscious. Posing a broad question lets people lead you to who they are. As an interviewer, Ms. Gross’s goal is to find out how her subject became who they are; as a conversationalist, make that goal your own.";

class About extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Navbar(
          title: "About",
          rightOptions: false,
          backButton: true, tags: [], getCurrentPage: () => {}, searchController: searchController, searchOnChanged: () => {},
        ),
        backgroundColor: NowUIColors.bgColorScreen,
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24),
          child: Column(
            children: [
              Text(aboutText1,
                  style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(aboutText2,
                    style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(aboutText3,
                    style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(aboutText4,
                    style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              ),
            ],
          ),
        )));
  }
}
