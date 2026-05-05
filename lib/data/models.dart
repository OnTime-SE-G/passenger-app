import 'package:latlong2/latlong.dart';

class BusStop {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final List<String> routeIds;

  const BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.routeIds,
  });
}

class BusRoute {
  final String id;
  final String code; // e.g. "24B"
  final String name; // e.g. "Downtown Express"
  final String origin;
  final String destination;
  final List<LatLng> path; // polyline
  final List<String> stopIds; // ordered

  const BusRoute({
    required this.id,
    required this.code,
    required this.name,
    required this.origin,
    required this.destination,
    required this.path,
    required this.stopIds,
  });
}

enum BusLiveStatus { onTime, delayed, arriving, cancelled }

class Bus {
  final String id;
  final String number;
  final String routeId;
  final String driverName;
  final int capacity;
  final String? status;

  const Bus({
    required this.id,
    required this.number,
    required this.routeId,
    required this.driverName,
    required this.capacity,
    this.status,
  });
}

/// Snapshot of a bus' real-time state. Emitted repeatedly from a stream.
class BusPosition {
  final String busId;
  final LatLng location;
  final double headingDeg;
  final double speedKmh;
  final BusLiveStatus status;
  final int etaMinutes; // to the user's selected stop / destination
  final int occupancyPct;
  final int nextStopIndex; // index into route.stopIds

  const BusPosition({
    required this.busId,
    required this.location,
    required this.headingDeg,
    required this.speedKmh,
    required this.status,
    required this.etaMinutes,
    required this.occupancyPct,
    required this.nextStopIndex,
  });
}
class RecentSearch {
  final String from;
  final String to;
  final DateTime at;

  const RecentSearch({
    required this.from,
    required this.to,
    required this.at,
  });
}

enum AlertType { disruption, delay, info }

class ServiceAlert {
  final String id;
  final AlertType type;
  final String routeCode;
  final String title;
  final String body;
  final DateTime timestamp;

  const ServiceAlert({
    required this.id,
    required this.type,
    required this.routeCode,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class SavedRoute {
  final String routeCode;
  final String name;

  const SavedRoute({required this.routeCode, required this.name});
}

class RecentTrip {
  final String from;
  final String to;
  final String routeCode;
  final DateTime at;

  const RecentTrip({
    required this.from,
    required this.to,
    required this.routeCode,
    required this.at,
  });
}
