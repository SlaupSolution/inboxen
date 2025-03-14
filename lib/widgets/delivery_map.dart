import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class DeliveryMap extends StatefulWidget {
  final int? orderId;
  final Position? initialPosition;
  final Position? destinationPosition;
  final bool showCurrentLocation;
  final bool trackDelivery;

  const DeliveryMap({
    super.key,
    this.orderId,
    this.initialPosition,
    this.destinationPosition,
    this.showCurrentLocation = true,
    this.trackDelivery = false,
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final _locationService = LocationService();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription? _locationSubscription;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.trackDelivery && widget.orderId != null) {
      _startDeliveryTracking();
    }
  }

  Future<void> _initializeMap() async {
    if (widget.initialPosition != null) {
      _addMarker(
        widget.initialPosition!,
        'origin',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        'Ponto de Coleta',
      );
    }

    if (widget.destinationPosition != null) {
      _addMarker(
        widget.destinationPosition!,
        'destination',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        'Ponto de Entrega',
      );
    }

    if (widget.showCurrentLocation) {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        _addMarker(
          currentLocation,
          'current',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          'Sua Localização',
        );
      }
    }

    setState(() {});
  }

  void _startDeliveryTracking() {
    // Update location every 30 seconds
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null && widget.orderId != null) {
        await _locationService.updateDeliveryLocation(
          orderId: widget.orderId!,
          position: currentLocation,
          context: context,
        );
      }
    });

    // Watch location updates from other delivery person
    if (widget.orderId != null) {
      _locationSubscription = _locationService
          .watchOrderLocation(widget.orderId!)
          .listen((locationData) {
        if (locationData.isNotEmpty) {
          final position = Position(
            latitude: locationData['latitude'],
            longitude: locationData['longitude'],
            timestamp: DateTime.parse(locationData['updated_at']),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
          );

          _updateDeliveryMarker(position);
        }
      });
    }
  }

  void _addMarker(
    Position position,
    String markerId,
    BitmapDescriptor icon,
    String title,
  ) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: LatLng(position.latitude, position.longitude),
      icon: icon,
      infoWindow: InfoWindow(title: title),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _updateDeliveryMarker(Position position) {
    final deliveryMarker = Marker(
      markerId: MarkerId('delivery'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(title: 'Entregador'),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'delivery');
      _markers.add(deliveryMarker);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.initialPosition == null
        ? Center(child: CircularProgressIndicator())
        : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.initialPosition!.latitude,
                widget.initialPosition!.longitude,
              ),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: widget.showCurrentLocation,
            myLocationButtonEnabled: widget.showCurrentLocation,
            onMapCreated: (controller) => _mapController = controller,
          );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}