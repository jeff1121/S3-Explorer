import 'package:flutter/material.dart';
import 'package:now_ui_pro_flutter/constants/Theme.dart';
// import 'package:now_ui_pro_flutter/constants/Images.dart';

// widgets
import 'package:now_ui_pro_flutter/widgets/navbar.dart';
import 'package:now_ui_pro_flutter/widgets/card-horizontal.dart';
import 'package:now_ui_pro_flutter/widgets/card-small.dart';
import 'package:now_ui_pro_flutter/widgets/table-cell.dart';

//screens
import 'package:now_ui_pro_flutter/screens/product.dart';
import 'package:now_ui_pro_flutter/screens/trending.dart';
import 'package:now_ui_pro_flutter/screens/fashion.dart';

final Map<String, List<Map>> productCards = {
  "Shoes": [
    {
      "title": "Hardly Anything Takes More Coura...",
      "image":
          "https://images.unsplash.com/photo-1539314171919-908b0cd96f03?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": "Find the cheapest deals on our range...",
      "image":
          "https://images.unsplash.com/photo-1515709980177-7a7d628c09ba?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": "Looking for Men's watches?",
      "image":
          "https://images.unsplash.com/photo-1490367532201-b9bc1dc483f6?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": 'Fashion Shoes',
      "image":
          "https://images.unsplash.com/photo-1539314171919-908b0cd96f03?crop=entropy&w=840&h=840&fit=crop"
    },
    {
      "title": "Curious Blossom Skin Care Kit.",
      "image":
          "https://images.unsplash.com/photo-1536303006682-2ee36ba49592?crop=entropy&w=840&h=840&fit=crop",
    },
  ],
  "Beauty": [
    {
      "title": "Adjust your watch to your outfit.",
      "image":
          "https://images.unsplash.com/photo-1491336477066-31156b5e4f35?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": "Everyone is a superhero in their hearts.",
      "image":
          "https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?crop=entropy&w=840&fit=crop",
    },
    {
      "title": "Yes, I’m a Princess and I like the color Red.",
      "image":
          "https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": "This was the best ice cream I had last summer.",
      "image":
          "https://images.unsplash.com/photo-1502901930015-158e72cff877?crop=entropy&w=840&h=840&fit=crop",
    },
    {
      "title": "This world is full of hope. Make the most of it!",
      "image":
          "https://images.unsplash.com/photo-1489710437720-ebb67ec84dd2?crop=entropy&w=840&h=840&fit=crop",
    },
  ],
};

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final myController = TextEditingController();

  String searchText = "";
  List results = [];

  void dispose() {
    myController.dispose();
    super.dispose();
  }

  _searchText(String searchTerm) {
    setState(() {
      results.clear();
    });
    if (searchTerm.isNotEmpty)
      productCards.forEach((k, v) => v.map((e) {
            if (e["title"].toLowerCase().contains(searchTerm.toLowerCase())) {
              setState(() {
                results.add(e);
              });
            }
          }).toList());
    print(results.length);
  }
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Navbar(
          backButton: true,
          title: "Search",
          rightOptions: false,
          searchBar: true,
          isOnSearch: true,
          searchOnChanged: (String typedText) {
            setState(() {
              searchText = typedText;
            });
            _searchText(searchText);
          },
          searchAutofocus: true, tags: [], getCurrentPage: () => {}, searchController: searchController,
          // searchController: myController
        ),
        backgroundColor: NowUIColors.bgColorScreen,
        body: Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24),
            child: searchText.isNotEmpty
                ? (results.length != 0
                    ? ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (BuildContext context, int index) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CardHorizontal(
                                  title: results[index]["title"],
                                  img: results[index]["image"],
                                  tap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Product(
                                            title: results[index]["title"],
                                            urlImg: results[index]["image"],
                                          ),
                                        ));
                                  }),
                            ))
                    : SingleChildScrollView(
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                    text: "We didn't find ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: NowUIColors.text,
                                        fontFamily: "Montserrat"),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: "\"$searchText\"",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: NowUIColors.text,
                                              fontFamily: "Montserrat",
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(
                                          text: " in our store.",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: NowUIColors.text))
                                    ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                    "You can see more products from other categories.",
                                    style: TextStyle(
                                        fontSize: 16, color: NowUIColors.text)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: TableCellSettings(
                                    title: "Trending",
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Trending(),
                                          ));
                                    }),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: TableCellSettings(
                                    title: "Fashion",
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Fashion(),
                                          ));
                                    }),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, bottom: 16.0),
                                child: Text("Daily Deals",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ),
                              Row(
                                children: [
                                  CardSmall(
                                      img: productCards["Shoes"]![2]["image"],
                                      title: productCards["Shoes"]![2]["title"],
                                      tap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Product(
                                                title: productCards["Places"]![2]
                                                    ["title"],
                                                urlImg: productCards["Places"]!
                                                    [2]["image"],
                                              ),
                                            ));
                                      }),
                                  CardSmall(
                                      img: productCards["Shoes"]![1]["image"],
                                      title: productCards["Shoes"]![1]["title"],
                                      tap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Product(
                                                title: productCards["Places"]![1]
                                                    ["title"],
                                                urlImg: productCards["Places"]!
                                                    [1]["image"],
                                              ),
                                            ));
                                      })
                                ],
                              ),
                              SizedBox(height: 10),
                              CardHorizontal(
                                  img: productCards["Shoes"]![0]["image"],
                                  title: productCards["Shoes"]![0]["title"],
                                  tap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Product(
                                            title: productCards["Places"]![0]
                                                ["title"],
                                            urlImg: productCards["Places"]![0]
                                                ["image"],
                                          ),
                                        ));
                                  }),
                              SizedBox(height: 32)
                            ],
                          ),
                        ),
                      ))
                : Container()));
  }
}
