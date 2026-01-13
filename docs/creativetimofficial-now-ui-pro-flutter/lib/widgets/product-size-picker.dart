import 'package:flutter/material.dart';

import 'package:now_ui_pro_flutter/constants/Theme.dart';

class ProductSizePicker extends StatefulWidget {
  @override
  _ProductSizePickerState createState() => _ProductSizePickerState();
}

class _ProductSizePickerState extends State<ProductSizePicker> {
  String isSelected = "0";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected = "XS";
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.only(top: 16, bottom: 16),
                      decoration: BoxDecoration(
                          color: isSelected == "XS"
                              ? NowUIColors.info.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border(
                            top: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            left: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            right: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            bottom: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                          ),
                          borderRadius:
                              BorderRadius.only(topLeft: Radius.circular(4.0))),
                      child: Center(
                        child: Text("XS",
                            style: TextStyle(
                                color: isSelected == "XS"
                                    ? NowUIColors.info
                                    : Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500)),
                      )),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected = "S";
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                          color: isSelected == "S"
                              ? NowUIColors.info.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border(
                            top: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            bottom: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                          )),
                      child: Center(
                        child: Text("S",
                            style: TextStyle(
                                color: isSelected == "S"
                                    ? NowUIColors.info
                                    : Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500)),
                      )),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected = "M";
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                          color: isSelected == "M"
                              ? NowUIColors.info.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border(
                            top: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            left: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            right: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                            bottom: BorderSide(
                                color: NowUIColors.border, width: 0.5),
                          ),
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4.0))),
                      child: Center(
                        child: Text("M",
                            style: TextStyle(
                                color: isSelected == "M"
                                    ? NowUIColors.info
                                    : Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500)),
                      )),
                ),
              )
            ],
          ),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected = "L";
                  });
                },
                child: Container(
                    padding: EdgeInsets.only(top: 16, bottom: 16),
                    decoration: BoxDecoration(
                        color: isSelected == "L"
                            ? NowUIColors.info.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border(
                          top:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          left:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          right:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          bottom:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                        ),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(4.0))),
                    child: Center(
                      child: Text("L",
                          style: TextStyle(
                              color: isSelected == "L"
                                  ? NowUIColors.info
                                  : Colors.black,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500)),
                    )),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected = "XL";
                  });
                },
                child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                        color: isSelected == "XL"
                            ? NowUIColors.info.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border(
                          top:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          bottom:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                        )),
                    child: Center(
                      child: Text("XL",
                          style: TextStyle(
                              color: isSelected == "XL"
                                  ? NowUIColors.info
                                  : Colors.black,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500)),
                    )),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected = "2XL";
                  });
                },
                child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                        color: isSelected == "2XL"
                            ? NowUIColors.info.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border(
                          top:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          left:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          right:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                          bottom:
                              BorderSide(color: NowUIColors.border, width: 0.5),
                        ),
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(4.0))),
                    child: Center(
                      child: Text("2XL",
                          style: TextStyle(
                              color: isSelected == "2XL"
                                  ? NowUIColors.info
                                  : Colors.black,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500)),
                    )),
              ),
            )
          ])
        ],
      ),
    );
  }
}
