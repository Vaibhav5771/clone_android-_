import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../shops/shop_service.dart';
import '../shops/shop_model.dart';

class MapState extends ChangeNotifier {
  bool _isMapLoaded = false;
  bool _isLocating = false;
  LatLng _center = const LatLng(18.5204, 73.8567);
  double _zoomLevel = 12.0;
  MapController? _controller;
  final List<Marker> _markers = [];
  final ShopService _shopService = ShopService();
  Timer? _debounceTimer;
  List<Shop> _nearbyShops = []; // Cache nearby shops instead of markers

  bool get isMapLoaded => _isMapLoaded;
  bool get isLocating => _isLocating;
  LatLng get center => _center;
  double get zoomLevel => _zoomLevel;
  MapController? get controller => _controller;
  List<Marker> get markers => _markers;
  List<Shop> get nearbyShops => _nearbyShops; // Expose nearby shops
  List<Shop> get shops => _shopService.shops;
  ShopService getShopService() => _shopService;

  void setLocating(bool locating) {
    _isLocating = locating;
    notifyListeners();
  }

  void initMapController(MapController controller) {
    _controller = controller;
    notifyListeners();
  }

  void addMarker(LatLng point, {String markerId = 'center', bool isUser = false}) {
    _markers.add(
      Marker(
        point: point,
        width: 56,
        height: 56,
        child: isUser
            ? const Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 56,
        )
            : const Icon(
          Icons.location_pin,
          color: Colors.grey,
          size: 56,
        ),
      ),
    );
    notifyListeners();
  }

  void addMarkerAtCenter() {
    addMarker(_center, markerId: 'center');
  }

  Future<void> setMapLoaded(bool loaded) async {
    _isMapLoaded = loaded;
    if (loaded) {
      print('Map loaded, triggering loadShops');
      await _loadShops();
      print('After loadShops, shops count: ${shops.length}');
      updateNearbyShops();
    }
    notifyListeners();
  }

  Future<void> setCenter(LatLng newCenter) async {
    if (_center == newCenter) return;
    _center = newCenter;
    if (_controller != null) {
      _controller!.move(newCenter, _zoomLevel);
    }
    print('Center changed to $_center, scheduling loadShops');
    _debounceLoadShops();
    notifyListeners();
  }

  Future<void> setZoom(double zoom) async {
    _zoomLevel = zoom.clamp(2.0, 19.0);
    if (_controller != null) {
      _controller!.move(_center, _zoomLevel);
    }
    notifyListeners();
  }

  void disposeController() {
    _controller = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  void _debounceLoadShops() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      print('Executing debounced loadShops');
      await _loadShops();
      updateNearbyShops();
      print('After debounced loadShops, shops count: ${shops.length}');
      notifyListeners();
    });
  }

  Future<void> _loadShops() async {
    await _shopService.loadShops();
  }

  void updateNearbyShops() {
    _nearbyShops = _shopService.getNearbyShops(_center);
    print('Updated nearby shops: ${_nearbyShops.length}');
  }
}