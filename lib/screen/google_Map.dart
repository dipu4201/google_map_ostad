import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _googleMapController;
  LocationData? _currentLocation;
  late Location _location;
  final List<LatLng> _polylineCoordinates = [];
  Marker? _currentLocationMarker;
  Polyline? _locationTrackingPolyline;
  bool _isFirstLocationUpdate = true;

  @override
  void initState() {
    super.initState();
    _location = Location();
    _initLocationService();
  }

  void _initLocationService() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _startTracking();
  }

  void _startTracking() {
    _location.changeSettings(interval: 10000);
    _location.onLocationChanged.listen((LocationData locationData) {
      _currentLocation = locationData;
      LatLng currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        _currentLocationMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          infoWindow: InfoWindow(
            title: 'My current location',
            snippet: 'Lat: ${locationData.latitude}, Lng: ${locationData.longitude}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        _polylineCoordinates.add(currentLatLng);

        _locationTrackingPolyline = Polyline(
          polylineId: const PolylineId('trackingPolyline'),
          color: Colors.blue,
          width: 5,
          points: _polylineCoordinates,
        );

        if (_isFirstLocationUpdate) {
          _googleMapController.animateCamera(
            CameraUpdate.newLatLngZoom(currentLatLng, 17.0),
          );
          _isFirstLocationUpdate = false;
        } else {
          _googleMapController.animateCamera(
            CameraUpdate.newLatLng(currentLatLng),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.terrain,
        initialCameraPosition: const CameraPosition(
          target: LatLng(24.37475236925892, 88.59983333998589),
          zoom: 17.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        onTap: (LatLng latLng) {
          print(latLng);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
        polylines: _locationTrackingPolyline != null ? {_locationTrackingPolyline!} : {},
      ),
    );
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }
}
