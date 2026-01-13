import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageSlider extends StatefulWidget {
  final List<String> imgArray;

  const ImageSlider({Key? key, required this.imgArray}) : super(key: key);

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider(
          items: widget.imgArray
              .map((item) => Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(item),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter))))
              .toList(),
          options: CarouselOptions(
              height: 700,
              autoPlay: false,
              enlargeCenterPage: false,
              // aspectRatio: 2.0,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(bottom: 30),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imgArray.map((url) {
                int index = widget.imgArray.indexOf(url);
                print(index);
                return Container(
                  width: 36.0,
                  height: 4.0,
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: _current == index
                        ? Color.fromRGBO(255, 255, 255, 1)
                        : Color.fromRGBO(255, 255, 255, 0.4),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }
}
