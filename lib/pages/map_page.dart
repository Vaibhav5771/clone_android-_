import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:provider/provider.dart';
import '../services/map_state.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapState = Provider.of<MapState>(context, listen: false);
      if (mapState.controller == null) {
        mapState.initMapController();
      }
    });
  }

  @override
  void dispose() {
    final mapState = Provider.of<MapState>(context, listen: false);
    mapState.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapState>(
      builder: (context, mapState, _) {
        return Stack(
          children: [
            OSMFlutter(
              controller: mapState.controller ?? MapController(),
              osmOption: const OSMOption(
                zoomOption: ZoomOption(
                  initZoom: 12,
                  minZoomLevel: 2,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                userTrackingOption: UserTrackingOption(
                  enableTracking: false,
                ),
              ),
              onMapIsReady: (isReady) async {
                if (isReady) {
                  mapState.setMapLoaded(true);
                  await mapState.addMarkerAtCenter();
                }
              },
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: () => mapState.setZoom(mapState.zoomLevel + 1),
                    mini: true,
                    child: const Icon(Icons.zoom_in),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    onPressed: () => mapState.setZoom(mapState.zoomLevel - 1),
                    mini: true,
                    child: const Icon(Icons.zoom_out),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}