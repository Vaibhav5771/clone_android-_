import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/map_state.dart';
import '../shops/shop_marker.dart';
import '../shops/shop_model.dart';
import '../shops/shop_service.dart';
import '../auth_state.dart';
import '../pages/conversation_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // ... existing code (_goToCurrentLocation, _buildOptionChip, _showShopDetails) ...

  List<Marker> _buildShopMarkers(
      ({LatLng center, MapController? controller, List<Marker> markers, List<Shop> nearbyShops, bool isLocating, bool isEmpty}) mapData,
      BuildContext context) {
    print('Building markers for ${mapData.nearbyShops.length} nearby shops');
    return mapData.nearbyShops.map((shop) {
      return ShopMarker.buildMarker(
        shop: shop,
        onTap: () {
          _showShopDetails(context, shop);
        },
      );
    }).toList();
  }

  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    Provider.of<MapState>(context, listen: false).initMapController(_mapController);
  }

  @override
  void dispose() {
    final mapState = Provider.of<MapState>(context, listen: false);
    mapState.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MapState, ({LatLng center, MapController? controller, List<Marker> markers, List<Shop> nearbyShops, bool isLocating, bool isEmpty})>(
      selector: (_, mapState) => (
      center: mapState.center,
      controller: mapState.controller,
      markers: mapState.markers,
      nearbyShops: mapState.nearbyShops,
      isLocating: mapState.isLocating,
      isEmpty: mapState.markers.isEmpty && mapState.shops.isEmpty,
      ),
      builder: (context, mapData, _) {
        print('Rebuilding MapPage with ${mapData.nearbyShops.length} nearby shops');
        return Stack(
          children: [
            FlutterMap(
              mapController: mapData.controller,
              options: MapOptions(
                initialCenter: mapData.center,
                initialZoom: mapData.center == const LatLng(18.5204, 73.8567) ? 12.0 : 15.0,
                minZoom: 2,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  Provider.of<MapState>(context, listen: false).setMapLoaded(true);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.clone_android',
                  additionalOptions: const {
                    'attribution':
                    '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors © <a href="https://carto.com/attributions">CARTO</a>',
                  },
                ),
                MarkerLayer(
                  markers: [
                    ...mapData.markers.where((marker) => mapData.nearbyShops.every((shop) => shop.location != marker.point)),
                    ..._buildShopMarkers(mapData, context),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF62C3F4),
                      Color(0xFF0469C4),
                    ],
                  ),
                ),
                child: mapData.isLocating
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : FloatingActionButton(
                  onPressed: () => _goToCurrentLocation(Provider.of<MapState>(context, listen: false)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              right: 10,
              child: Text(
                '© OpenStreetMap contributors © CARTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            if (mapData.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                    SizedBox(height: 16), // Adds spacing between loader and text
                    Text(
                      'Searching For Shops Near You',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              )
          ],
        );
      },
    );
  }

  void _showShopDetails(BuildContext context, Shop shop) {
    print('Showing details for shop: ${shop.name}, ownerUid: ${shop.ownerUid}');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.3,
        minChildSize: 0.15,
        maxChildSize: 0.6,
        snap: true,
        snapSizes: const [0.3, 0.6],
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A30),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shop.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.network(
                        shop.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/shop.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              shop.address,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shop.paperSizes.entries.map((entry) {
                      return _buildOptionChip(
                        label: entry.key,
                        isAvailable: entry.value,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Color',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shop.colorOptions.entries.map((entry) {
                      return _buildOptionChip(
                        label: entry.key,
                        isAvailable: entry.value,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Flex',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shop.flexSizes.entries.map((entry) {
                      return _buildOptionChip(
                        label: entry.key,
                        isAvailable: entry.value,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: shop.ownerUid == 'unknown'
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot connect: Shop owner not assigned'),
                          ),
                        );
                      }
                          : () async {
                        final authState = Provider.of<AuthState>(context, listen: false);
                        print('Current user UID: ${authState.uid}');
                        if (authState.uid == shop.ownerUid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You cannot connect to your own shop')),
                          );
                          return;
                        }

                        try {
                          print('Fetching user data for ownerUid: ${shop.ownerUid}');
                          final ownerDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(shop.ownerUid)
                              .get();

                          if (ownerDoc.exists) {
                            final ownerData = ownerDoc.data()!;
                            final ownerUsername = ownerData['username'] as String? ??
                                ownerData['email']?.split('@')[0] ??
                                'Shop Owner';
                            final ownerAvatarUrl = ownerData['avatarUrl'] as String? ??
                                'assets/avatar_1.png';

                            print('Navigating to ConversationPage for ${shop.ownerUid}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConversationPage(
                                  receiverId: shop.ownerUid,
                                  receiverUsername: ownerUsername,
                                  receiverAvatarUrl: ownerAvatarUrl,
                                ),
                              ),
                            );
                          } else {
                            print('Owner not found for ownerUid: ${shop.ownerUid}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shop owner not found')),
                            );
                          }
                        } catch (e) {
                          print('Error connecting to shop: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error connecting to shop: $e')),
                          );
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          color: shop.ownerUid == 'unknown' ? Colors.grey : Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Connect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({required String label, required bool isAvailable}) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        isAvailable ? Icons.check_circle : Icons.cancel,
        color: isAvailable ? Colors.green : Colors.red,
        size: 18,
      ),
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(fontSize: 14),
    );
  }

  Future<void> _goToCurrentLocation(MapState mapState) async {
    try {
      mapState.setLocating(true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turn Your GPS On.')),
        );
        mapState.setLocating(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          mapState.setLocating(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, please enable them in settings.',
            ),
          ),
        );
        mapState.setLocating(false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await mapState.setCenter(LatLng(position.latitude, position.longitude));
      mapState.markers.clear();
      mapState.addMarker(
        LatLng(position.latitude, position.longitude),
        markerId: 'user_location',
        isUser: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moved to your current location.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      mapState.setLocating(false);
    }
  }
}