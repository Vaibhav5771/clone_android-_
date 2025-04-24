import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapState extends ChangeNotifier {
  bool _isMapLoaded = false;
  GeoPoint _center = GeoPoint(latitude: 18.5204, longitude: 73.8567); // Default: Pune, India
  double _zoomLevel = 12.0;
  MapController? _controller;

  bool get isMapLoaded => _isMapLoaded;
  GeoPoint get center => _center;
  double get zoomLevel => _zoomLevel;
  MapController? get controller => _controller;

  void initMapController() {
    _controller = MapController(
      initPosition: _center,
    );
    print('MapState: Controller initialized with center $_center');
    notifyListeners();
  }

  Future<void> addMarkerAtCenter() async {
    if (_controller != null) {
      await _controller!.addMarker(
        _center,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 56,
          ),
        ),
      );
      print('MapState: Marker added at $_center');
    } else {
      print('MapState: Cannot add marker, controller is null');
    }
  }

  void setMapLoaded(bool loaded) {
    _isMapLoaded = loaded;
    print('MapState: isMapLoaded set to $loaded');
    notifyListeners();
  }

  Future<void> setCenter(GeoPoint newCenter) async {
    _center = newCenter;
    if (_controller != null) {
      await _controller!.moveTo(newCenter);
      await _controller!.addMarker(
        newCenter,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 56,
          ),
        ),
      );
      print('MapState: Moved to new center $newCenter');
    }
    notifyListeners();
  }

  Future<void> setZoom(double zoom) async {
    _zoomLevel = zoom.clamp(2.0, 19.0); // OSM zoom range
    if (_controller != null) {
      await _controller!.setZoom(zoomLevel: _zoomLevel);
      print('MapState: Zoom set to $_zoomLevel');
    }
    notifyListeners();
  }

  void disposeController() {
    _controller?.dispose();
    _controller = null;
    print('MapState: Controller disposed');
    notifyListeners();
  }
}