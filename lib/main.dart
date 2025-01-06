import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'features/markup/image_markup.dart';
import 'features/markup/markers_provider.dart'; // Import your MarkersProvider class

class ItemImage {
  final String image;
  final String name;
  final MarkersProvider provider;
  ItemImage({required this.image, required this.name, required this.provider});
}

void main() {
  //debugPaintPointersEnabled = true;
   // Disable widget build logs
  debugPrint = (String? message, {int? wrapWidth}) {};
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAppState()),
        ChangeNotifierProvider(
            create: (context) => MarkersProvider()), // Add MarkersProvider
      ],
      child: MaterialApp(
          title: 'Image Markup',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 58, 134, 221)),
          ),
          home: HomePage()),
    );
  }
}

class MyAppState extends ChangeNotifier {
  
  ItemImage? selectedImage;
  bool debug = false;

//These marekers work with the window at 500x500
  List<ItemImage> imageList = [
    ItemImage(image: 'grid.png', name: 'Grid', provider: MarkersProvider(
      [
        // MarkerData(position: Offset(0.5, 0.1859),info: 'short\nlong description')
      ])),
    //ItemImage(image: 'grid.png', name: 'Grid', provider: MarkersProvider()),
    ItemImage(image: 'pump.png', name: 'Pump', provider: MarkersProvider()),
    ItemImage(image: 'motor.png', name: 'Engine', provider: MarkersProvider(
      [ 
        MarkerData(position: Offset(0.3611,0.3419),info: MarkerDescription(shortDescription: 'intake')),
        MarkerData(position: Offset(0.0748,0.1948),info: MarkerDescription(shortDescription: 'alternator')),
        MarkerData(position: Offset(0.5412,0.729),info: MarkerDescription(shortDescription: 'serpentine')),
        MarkerData(position: Offset(0.1919,0.726),info: MarkerDescription(shortDescription: 'tensioner', longDescription: 'Failure marked by oil discharge')),
      ])),
    ItemImage(image: 'extinguisher.png', name: 'Fire Extinguisher', provider: MarkersProvider(
      [ 
        MarkerData(position: Offset(0.6, -0.16), info: MarkerDescription(shortDescription: 'handle')),
        MarkerData(position: Offset(0.52, -0.18), info: MarkerDescription(shortDescription: 'gauge', longDescription: 'Check monthly for proper charge')),
        MarkerData(position: Offset(0.515,0.780),info: MarkerDescription(shortDescription: 'tank')),
        MarkerData(position: Offset(0.309,0.32),info: MarkerDescription(shortDescription: 'hose')),
        MarkerData(position: Offset(0.513,0.376),info: MarkerDescription(shortDescription: 'label', longDescription: 'Safety/Instruction label')),
      ])),
    ItemImage(image: 'packaging.png', name: 'Packaging', provider: MarkersProvider())
  ];

  void setSelectedImage(ItemImage? image) {
    selectedImage = image;
    notifyListeners();
  }

  void sortImages({bool ascending = true}) {
    imageList.sort((a, b) =>
        ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    notifyListeners(); // Notify listeners about the change
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.sortImages();
    if(appState.debug && appState.selectedImage == null){
      Future.delayed(Duration(milliseconds: 1), () {
        appState.setSelectedImage(appState.imageList[0]);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Image Markup'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                    decoration: BoxDecoration(
                    color: Colors.white, // Background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    border: Border.all(color: Colors.grey, width: 1), // Border
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<ItemImage>(
                    hint: Text('Select an image'),
                    underline: SizedBox.shrink(),
                    isExpanded: true,
                    value: appState.selectedImage, // Set the initial value
                    onChanged: (value) {
                      appState.setSelectedImage(value);
                    },
                    items: appState.imageList.map<DropdownMenuItem<ItemImage>>((item) {
                      return DropdownMenuItem<ItemImage>(
                        value: item, // Use 'image' as the value
                        child: Text(
                            item.name), // Display 'name' as the dropdown text
                      );
                    }).toList()
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                    child: appState.selectedImage == null
                        ? SizedBox.shrink()
                        : MarkupPage(appState.selectedImage!)),
              )),
            ]
          ),
        );
      },
    );
  }
}

class MarkupPage extends StatelessWidget {
  final ItemImage image;
  MarkupPage(this.image);
  @override
  Widget build(BuildContext context) {
    // Directly include ImageMarkup here
    return ImageMarkup(image, MyAppState().debug);
  }
}