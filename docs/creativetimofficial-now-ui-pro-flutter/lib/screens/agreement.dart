import 'package:flutter/material.dart';

import 'package:now_ui_pro_flutter/constants/Theme.dart';

import 'package:now_ui_pro_flutter/widgets/navbar.dart';

String userAgreementText1 =
    "It all started in the early 1970s, when, floundering a bit in her post-college life, she landed a gig at WBFO, a radio station in Buffalo. There she would call subjects and interview them for the program she hosted, “This Is Radio.” She moved to Philadelphia in 1975 to host “Fresh Air,” the brainchild of a colleague from WBFO.";
String userAgreementText2 =
    "Ms. Gross brings a combination of empathy and rigorous preparation to the job. “I read, watch or listen to as much of the person’s work as possible, so I have an understanding of what makes them, or their story, important,” she said. “I try to clarify in my own mind why this person matters, and why it’s worthy of our listeners’ time.";
String userAgreementText3 =
    "One thing she does not allow of her interview subjects, however, is input on the edit. “When the interview is over, you don’t have a chance to call back and say, ‘Well I like my answer to this, I don’t like my answer to that, can you edit that out,” she said. (As someone who has been interviewed by Ms. Gross, I would like to say that I wish I hadn’t insisted that her cats hate her. That said, I never asked for my comment to be removed from that particular episode of “Fresh Air.”)";

class UserAgreement extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Navbar(
          title: "User Agreement",
          rightOptions: false,
          backButton: true, tags: [], getCurrentPage: () => {}, searchController: searchController, searchOnChanged: () => {},
        ),
        backgroundColor: NowUIColors.bgColorScreen,
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24),
          child: Column(
            children: [
              Text(userAgreementText1,
                  style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(userAgreementText2,
                    style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(userAgreementText3,
                    style: TextStyle(fontSize: 16, color: NowUIColors.text)),
              ),
            ],
          ),
        )));
  }
}
