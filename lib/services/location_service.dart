import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  late LocationData _locData;

  Future<void> initialize()async {
    bool serviceEnabled;
    PermissionStatus permission;

    serviceEnabled = await location.serviceEnabled();
    if(!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if(!serviceEnabled) {
        return;
      }
    }

    permission = await location.hasPermission();
    if(permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if(permission != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<double?> getLatitute() async {
    _locData = await location.getLocation();
    return _locData.latitude;
  }

  Future<double?> getLongtitute() async {
    _locData = await location.getLocation();
    return _locData.longitude;
  }
}