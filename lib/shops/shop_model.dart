import 'package:latlong2/latlong.dart';

class Shop {
  final String name;
  final String address;
  final LatLng location;
  final List<String> services;
  final Map<String, bool> paperSizes;
  final Map<String, bool> colorOptions;
  final Map<String, bool> flexSizes;
  final String? imageUrl;
  final String ownerUid; // Still required, but 'unknown' is a valid value

  Shop({
    required this.name,
    required this.address,
    required this.location,
    this.services = const [],
    required this.paperSizes,
    required this.colorOptions,
    required this.flexSizes,
    this.imageUrl,
    required this.ownerUid,
  });
}