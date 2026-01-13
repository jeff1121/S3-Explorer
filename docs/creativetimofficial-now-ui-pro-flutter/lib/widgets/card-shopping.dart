import 'package:flutter/material.dart';
import 'package:now_ui_pro_flutter/constants/Theme.dart';

class CardShopping extends StatelessWidget {
  CardShopping(
      {this.body = "Placeholder Title",
      this.stock = true,
      this.price = "332",
      this.img = "https://via.placeholder.com/200",
      required this.deleteOnPress});

  final String body;
  final bool stock;
  final String price;
  final String img;
  final Function deleteOnPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135,
      // margin: EdgeInsets.only(top: 64),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      height: 65,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(img)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3.0)),
                      )),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NowUIColors.secondary,
                      textStyle: TextStyle(color: NowUIColors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 4.0),
                    ),
                    onPressed: () {},
                    child: Dropdown(),
                  ),
                ]),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body,
                        style: TextStyle(
                            color: NowUIColors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w400)),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 1.0),
                            child: Text(
                                stock == true ? 'In Stock' : 'Not In Stock',
                                style: TextStyle(
                                    color: stock == true
                                        ? NowUIColors.success
                                        : NowUIColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text("\$$price",
                                style: TextStyle(
                                    color: NowUIColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NowUIColors.secondary,
                            textStyle: TextStyle(color: NowUIColors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 2.0),
                          ),
                          onPressed: () {
                            deleteOnPress();
                          },
                          child: Text(
                            "DELETE",
                            style: TextStyle(fontSize: 10.0, color: NowUIColors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                             backgroundColor: NowUIColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 2.0),
                          ),
                          onPressed: () {
                            // Add your save for later logic here
                          },
                          child: Text(
                            "SAVE FOR LATER",
                            style: TextStyle(fontSize: 10.0, color: NowUIColors.white),
                          ),
                        ),
                      ],
                    )
                  ]),
            ),
          )
        ]),
      ),
      decoration: BoxDecoration(
        color: NowUIColors.white,
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 0), // changes position of shadow
          ),
        ],
      ),
    );
  }
}

class Dropdown extends StatefulWidget {
  Dropdown({Key? key}) : super(key: key);

  @override
  _DropdownState createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String dropdownValue = '1';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.0,
      child: DropdownButtonHideUnderline(
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: NowUIColors.secondary,
          ),
          child: DropdownButton<String>(
            value: dropdownValue,
            icon: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 0),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: NowUIColors.white,
              ),
            ),
            iconSize: 17,
            elevation: 1,
            style: TextStyle(color: NowUIColors.white),
            onChanged: (String? newValue) {
              setState(() {
                dropdownValue = newValue ??
                    ''; // Provide a default value if newValue is null
              });
            },
            items: <String>['1', '2', '3', '4']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: TextStyle(
                        color: NowUIColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
