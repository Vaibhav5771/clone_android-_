import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'shop_model.dart';

class ShopService {
  List<Shop> shops = [];

  Future<void> loadShops() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('shops').get();

      shops = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        GeoPoint location = data['location'] as GeoPoint;
        LatLng latLng = LatLng(location.latitude, location.longitude);
        String ownerUid = data['ownerUid'] as String? ?? 'unknown';

        print('Loaded shop: ${data['name']} with ownerUid: $ownerUid'); // Debug log

        return Shop(
          name: data['name'] ?? 'Unnamed Shop',
          address: data['address'] ?? 'No Address',
          location: latLng,
          services: [],
          paperSizes: Map<String, bool>.from(data['paperSizes'] ?? {}),
          colorOptions: Map<String, bool>.from(data['colorOptions'] ?? {}),
          flexSizes: Map<String, bool>.from(data['flexSizes'] ?? {}),
          imageUrl: data['imageUrl'],
          ownerUid: ownerUid,
        );
      }).toList();
      print('Loaded ${shops.length} shops');
    } catch (e) {
      print('Error loading shops from Firestore: $e');
      shops = [];
    }
  }

  List<Shop> getNearbyShops(LatLng center) {
    const Distance distance = Distance();
    return shops.where((shop) {
      final double km = distance.as(
        LengthUnit.Kilometer,
        center,
        shop.location,
      );
      return km < 10;
    }).toList();
  }
}