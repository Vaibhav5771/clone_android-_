import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'shop_model.dart';

class ShopMarker {
  static Marker buildMarker({
    required Shop shop,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: shop.location,
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: onTap,
        child: const Icon(
          Icons.storefront_sharp,
          color: Colors.lightGreen,
          size: 30,
        ),
      ),
    );
  }
}