import 'package:flutter/material.dart';
import 'package:now_ui_pro_flutter/constants/Theme.dart';

//widgets
import 'package:now_ui_pro_flutter/widgets/navbar.dart';
import 'package:now_ui_pro_flutter/widgets/slider.dart';
import 'package:now_ui_pro_flutter/widgets/product-size-picker.dart';
import 'package:now_ui_pro_flutter/screens/chat.dart';

class Product extends StatelessWidget {
  // final double height = window.physicalSize.height;
  final String urlImg;
  final String title;

  Product(
      {this.title = "Shoes", this.urlImg = "https://via.placeholder.com/250"});
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double height = View.of(context).physicalSize.height;
    final List<String> imgList = [
      urlImg,
      "https://images.unsplash.com/photo-1512675828443-4f454c42253a?ixlib=rb-1.2.1&auto=format&fit=crop&w=768&q=80"
    ];
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: Navbar(
          title: "",
          transparent: true,
          backButton: true,
          reverseTextcolor: true,
          tags: [],
          getCurrentPage: () => {},
          searchController: searchController,
          searchOnChanged: () => {},
        ),
        backgroundColor: NowUIColors.bgColorScreen,
        body: Stack(children: [
          Container(
              height: 0.18 * height, child: ImageSlider(imgArray: imgList)),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.0),
              child: Container(
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(
                                alpha: 0.2), // Use withValues to avoid precision loss
                            spreadRadius: 8,
                            blurRadius: 10,
                            offset: Offset(0, 0))
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      )),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.52,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Stack(children: [
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 34, vertical: 12),
                        child: SafeArea(
                          bottom: true,
                          top: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 82.0),
                                child: Text(title,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            "https://images.unsplash.com/photo-1512529920731-e8abaea917a5?fit=crop&w=840&q=80"),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("Ryan Scheinder",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text("Pro Seller",
                                                style: TextStyle(
                                                    color: NowUIColors.time)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text("735\$",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16))
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Size",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600))),
                              ),
                              ProductSizePicker(),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      backgroundColor: NowUIColors.info,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16.0),
                                    ),
                                    onPressed: () {},
                                    child: Text("Add to cart",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white))),
                              )
                            ],
                          ),
                        )),
                    FractionalTranslation(
                      translation: Offset(-0.07, -0.08),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: NowUIColors.info,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Chat()));
                            },
                            icon: Icon(Icons.message),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ])))
        ]));
  }
}
