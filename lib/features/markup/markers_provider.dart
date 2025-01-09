import 'dart:math';

import 'package:flutter/material.dart';

class MarkerDescription {
  final String shortDescription;
  final String longDescription;

  MarkerDescription({
    required this.shortDescription,
    this.longDescription = '',
  });
}

// Model class for storing marker data
class MarkerData {
  String id;
  int? index;
  Offset position;
  MarkerDescription info;
  bool showText;
  bool hide;
  Color color;
  bool? delete;
  MarkersProvider? provider;
  
  MarkerData({required this.id, required this.position, required this.info, this.showText = true, this.hide = false, this.color = Colors.red});

  // Getter for position
  Offset get getPosition => position;

  // Getter for info
  MarkerDescription get getInfo => info;

  // Getter for showText
  bool? get isShowText => showText;
}

class MarkersProvider extends ChangeNotifier {
  final List<MarkerData> _markers = [];

  static double width = 60;
  static double height = 46;
  static double iconSize = 20;
  static Point offset = Point(width/2, height/2);

  static MarkerData getEmptyMarker(){
    return MarkerData(id: DateTime.now().millisecondsSinceEpoch.toString(), position: Offset(0, 0), info: MarkerDescription(shortDescription: ''));
  }

  MarkersProvider([List<MarkerData>? initialMarkers]) {
    if (initialMarkers != null) {
      _markers.addAll(initialMarkers);
    }
  }

  List<MarkerData> get markers => List.unmodifiable(_markers);

  void hideMarker(MarkerData marker, bool hide) {
    marker.hide = hide;
    notifyListeners();
  }

  void addMarker(MarkerData marker) {
    marker.provider = this;
    _markers.add(marker);
    notifyListeners();
  }

  void moveToFrontofZIndex(MarkerData marker) {
      _markers.sort((a, b) {
        if (a == marker) return 1; // Move `a` to the end
        if (b == marker) return -1; // Move `b` to the end
        return 0; // Keep other markers in their current order
      });
      notifyListeners();
  }

  void updateMarkerPosition(MarkerData marker, Offset newPosition) {
    marker.position = newPosition;
    //moveToFrontofZIndex(marker);
  }

  void updateMarkerInfo(MarkerData marker, MarkerDescription info) {
    marker.info = info;
    notifyListeners();
  }

  void removeMarker(MarkerData marker) {
    if(_markers.remove(marker)){
      notifyListeners();
    }
  }

  void removeDeletedMarkers() {
    for(MarkerData marker in _markers){
      if(marker.delete == true){
        _markers.remove(marker);
      }
    }
    notifyListeners();
  }

  void showText(MarkerData marker, bool showText) {
    marker.showText = showText;
    notifyListeners();
  }
}
