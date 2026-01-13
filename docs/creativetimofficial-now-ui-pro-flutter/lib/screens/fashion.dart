import 'package:flutter/material.dart';

import 'package:now_ui_pro_flutter/constants/Theme.dart';
import 'package:now_ui_pro_flutter/constants/Images.dart';

//widgets
import 'package:now_ui_pro_flutter/widgets/navbar.dart';
import 'package:now_ui_pro_flutter/widgets/card-horizontal.dart';
import 'package:now_ui_pro_flutter/widgets/card-small.dart';
import 'package:now_ui_pro_flutter/widgets/card-square.dart';

import 'package:now_ui_pro_flutter/screens/product.dart';

final Map<String, List<Map>> fashionCards = {
  "Shoes": [
    {
      "title": "Society has put up so many boundaries",
      "image": images["fashion"]!["Society"],
    },
    {
      "title": 'That is One Way To Ditch You',
      "image": images["fashion"]!["That is"],
    },
    {
      "title": 'Why would anyone pick blue',
      "image": images["fashion"]!["Why would"],
    },
    {
      "title": 'How to wear black suit?',
      "image": images["fashion"]!["How to"],
    },
    {
      "title": 'The best way to write',
      "image": images["fashion"]!["The best"],
    },
  ],
  "Beauty": [
    {
      "title": 'Think in the morning. Act in the noon.',
      "image": images["fashion"]!["Think in"],
    },
    {
      "title": 'Love cures people - both the ones',
      "image": images["fashion"]!["Love cures"],
    },
    {
      "title": 'Keep your face always to the sun',
      "image": images["fashion"]!["Keep your"],
    },
    {
      "title": 'For it was not into my ear you whispered',
      "image": images["fashion"]!["For it"],
    },
    {
      "title":
          'There is only one corner of the universe you can be certain of improving',
      "image": images["fashion"]!["There is"],
    },
  ],
  "Fashion": [
    {
      "title": 'Do not dwell in the past, do not dream',
      "image": images["fashion"]!["Do not"],
    },
    {
      "title": 'Success is not final, failure is not fatal',
      "image": images["fashion"]!["Success is"],
    },
    {
      "title": 'Favorite high heels',
      "image": images["fashion"]!["Favorite high heels"],
    },
    {
      "title": 'Pastel Hearts Sunglasses',
      "image": images["fashion"]!["Pastel Hearts Sunglasses"],
    },
    {
      "title": 'Awesome destination',
      "image": images["fashion"]!["Awesome destination"],
    },
  ],
  "Places": [
    {
      "title": 'Venture investment in U.S. startups rose sequentially',
      "image": images["fashion"]!["Venture investment"],
    },
    {
      "title": 'Finding temporary housing for your dog',
      "image": images["fashion"]!["Finding temporary"],
    },
    {
      "title": 'As Uber works through a huge amount of turmoil',
      "image": images["fashion"]!["As Uber"],
    },
    {
      "title": 'Living in South Central L.A., Socrates Fortlow',
      "image": images["fashion"]!["Living in"],
    },
    {
      "title": 'Whether it comes from the Sun.',
      "image": images["fashion"]!["Whether it comes from the Sun."],
    },
  ],
};

final List<String> tags = ["Shoes", "Beauty", "Fashion", "Places"];

class Fashion extends StatefulWidget {
  @override
  _FashionState createState() => _FashionState();
}

class _FashionState extends State<Fashion> {
  static dynamic currentTag;

  _getCurrentPage(activeTag) {
    setState(() {
      currentTag = activeTag;
      print('currentTag is $currentTag');
    });
  }

  void initState() {
    currentTag = tags[0];
    super.initState();
  }
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Navbar(
          title: "Fashion",
          tags: tags,
          getCurrentPage: _getCurrentPage,
          backButton: true, searchController: searchController, searchOnChanged: () => {},
        ),
        backgroundColor: NowUIColors.bgColorScreen,
        body: Container(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CardHorizontal(
                        cta: "View article",
                        title: fashionCards[currentTag]![0]['title'],
                        img: fashionCards[currentTag]![0]['image'],
                        tap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Product(
                                  title: fashionCards[currentTag]![0]['title'],
                                  urlImg: fashionCards[currentTag]![0]['image'],
                                ),
                              ));
                        }),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      CardSmall(
                          cta: "View article",
                          title: fashionCards[currentTag]![1]['title'],
                          img: fashionCards[currentTag]![1]['image'],
                          tap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Product(
                                    title: fashionCards[currentTag]![1]['title'],
                                    urlImg: fashionCards[currentTag]![1]
                                        ['image'],
                                  ),
                                ));
                          }),
                      CardSmall(
                          cta: "View article",
                          title: fashionCards[currentTag]![2]['title'],
                          img: fashionCards[currentTag]![2]['image'],
                          tap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Product(
                                    title: fashionCards[currentTag]![2]['title'],
                                    urlImg: fashionCards[currentTag]![2]
                                        ['image'],
                                  ),
                                ));
                          })
                    ],
                  ),
                  SizedBox(height: 8.0),
                  CardHorizontal(
                      cta: "View article",
                      title: fashionCards[currentTag]![3]['title'],
                      img: fashionCards[currentTag]![3]['image'],
                      tap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Product(
                                title: fashionCards[currentTag]![3]['title'],
                                urlImg: fashionCards[currentTag]![3]['image'],
                              ),
                            ));
                      }),
                  SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: CardSquare(
                        cta: "View article",
                        title: fashionCards[currentTag]![4]['title'],
                        img: fashionCards[currentTag]![4]['image'],
                        tap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Product(
                                  title: fashionCards[currentTag]![4]['title'],
                                  urlImg: fashionCards[currentTag]![4]['image'],
                                ),
                              ));
                        }),
                  )
                ],
              ),
            )));
  }
}
