library pdf_to_book;

import 'dart:io';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:path_provider/path_provider.dart';

class PdfBook extends StatefulWidget {
  final String pdfUrl;
  final String filename;
  PdfBook({@required this.pdfUrl, this.filename = "book.pdf"});

  @override
  _PdfBookState createState() => _PdfBookState();
}

class _PdfBookState extends State<PdfBook> {
  List<PdfPageImage> pageImages = [];

  @override
  void initState() {
    getBookImages().then((images) {
      setState(() {
        pageImages = images;
      });
    });
    super.initState();
  }

  Future<List<PdfPageImage>> getBookImages() async {
    List<PdfPageImage> images = [];

    File f = await createFileOfPdfUrl(widget.pdfUrl, filename: widget.filename);
    PdfDocument doc = await PdfDocument.openFile(f.path);

    for (var i = 1; i <= doc.pagesCount; i++) {
      PdfPage page = await doc.getPage(i);
      PdfPageImage image =
          await page.render(width: page.width, height: page.height);
      images.add(image);
      await page.close();
    }
    await doc.close();

    return images;
  }

  Future<File> createFileOfPdfUrl(String url, {String filename}) async {
    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationSupportDirectory()).path;
    File file = File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  List<Widget> createCarouselItems(Orientation orientation) {
    List<Widget> res = [];
    if (orientation == Orientation.landscape) {
      for (var i = 0; i < pageImages.length; i++) {
        if (i == 0 || i == pageImages.length - 1) {
          res.add(PageImageWidget(
            pageImage: pageImages[i],
            orientation: orientation,
          ));
        } else {
          Row row = Row(
            children: [
              PageImageWidget(
                pageImage: pageImages[i],
                orientation: orientation,
              ),
              PageImageWidget(
                pageImage: pageImages[i + 1],
                orientation: orientation,
              )
            ],
          );
          i += 1;
          res.add(row);
        }
      }
    } else {
      res = pageImages
          .map((pageImage) => PageImageWidget(
                pageImage: pageImage,
                orientation: orientation,
              ))
          .toList();
    }

    return res;
  }

  CarouselController _controller = CarouselController();
  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    if (pageImages.length > 0) {
      return OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            var carousel = CarouselSlider(
              key: Key("carousel_portrait"),
              carouselController: _controller,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1,
                enlargeCenterPage: false,
                enableInfiniteScroll: false,
                onPageChanged: (pageNum, reason) {
                  currentPage = pageNum;
                },
              ),
              items: createCarouselItems(orientation),
            );
            _controller.onReady.then((_) {
              _controller
                  .jumpToPage(currentPage == 0 ? 0 : currentPage * 2 - 1);
            });
            return carousel;
          } else {
            var carousel = CarouselSlider(
              key: Key("carousel_landscape"),
              carouselController: _controller,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.width,
                viewportFraction: 1,
                enlargeCenterPage: false,
                enableInfiniteScroll: false,
                onPageChanged: (pageNum, reason) {
                  currentPage = pageNum;
                },
              ),
              items: createCarouselItems(orientation),
            );
            _controller.onReady.then(
              (_) {
                if (currentPage % 2 == 0) {
                  // Account for 2 pages on each page turn
                  _controller.jumpToPage(
                      currentPage == 0 ? 0 : (currentPage / 2).truncate());
                } else {
                  _controller.jumpToPage((currentPage / 2).truncate() + 1);
                }
              },
            );
            return carousel;
          }
        },
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}

class PageImageWidget extends StatelessWidget {
  const PageImageWidget({@required this.pageImage, @required this.orientation});

  final PdfPageImage pageImage;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: Container(
        width:
            orientation == Orientation.portrait ? size.width : size.width / 2,
        height: size.height,
        child: Image(
          image: MemoryImage(pageImage.bytes),
          fit: orientation == Orientation.portrait
              ? BoxFit.fitWidth
              : BoxFit.contain,
        ),
      ),
    );
  }
}
