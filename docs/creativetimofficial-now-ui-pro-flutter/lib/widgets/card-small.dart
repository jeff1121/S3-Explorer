import 'package:flutter/material.dart';
import 'package:now_ui_pro_flutter/constants/Theme.dart';

class CardSmall extends StatelessWidget {
  CardSmall({
    this.title = "Placeholder Title",
    this.cta = "",
    this.img = "https://via.placeholder.com/200",
    required void Function() tap,
  }): onTap = tap;

  final String cta;
  final String img;
  final void Function() onTap;
  final String title;

  static void defaultFunc() {
    print("the function works!");
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: Container(
      height: 235,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
            elevation: 3,
            shadowColor: NowUIColors.muted.withValues(alpha: 0.22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4.0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                    flex: 11,
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0)),
                            image: DecorationImage(
                              image: NetworkImage(img),
                              fit: BoxFit.cover,
                            )))),
                Flexible(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, bottom: 16.0, left: 16.0, right: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  color: NowUIColors.text, fontSize: 12)),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(cta,
                                style: TextStyle(
                                    color: NowUIColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ))
              ],
            )),
      ),
    ));
  }
}
