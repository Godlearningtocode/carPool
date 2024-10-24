import 'package:mongo_dart/mongo_dart.dart';

class TripService {
  static Db? db;
  static DbCollection? driverTripCollection;

  static Future<void> initialize() async {
    if (db == null || !db!.isConnected) {
      db = Db(
          'mongodb://shivamcodes01:Sh%21vamno1@carpool-shard-00-00.xl3fo.mongodb.net:27017,carpool-shard-00-01.xl3fo.mongodb.net:27017,carpool-shard-00-02.xl3fo.mongodb.net:27017/carpool?ssl=true&replicaSet=carpool-shard-0&authSource=admin&retryWrites=true');
      try {
        await db!.open(); // Open the connection
        driverTripCollection =
            db!.collection('trips'); // Select the trips collection
        print("MongoDB connected successfully");
      } catch (e) {
        print("Error connecting to MongoDB: $e");
        rethrow; // Rethrow the error if needed
      }
    }
  }

  // Fetches trip history for all drivers
  static Future<Map<String, List<Map<String, dynamic>>>>
      fetchTripHistory() async {
    try {
      await initialize(); // Ensure MongoDB connection is initialized

      // Check if the collection is initialized
      if (driverTripCollection == null) {
        throw Exception("Trips collection is not initialized.");
      }

      final trips =
          await driverTripCollection!.find().toList(); // Fetch all trips
      Map<String, List<Map<String, dynamic>>> groupedTrips = {};

      for (var doc in trips) {
        List tripData = (doc['tripData'] as List)
            .map((point) {
              var latitude = point['latitude'];
              var longitude = point['longitude'];
              var timeStamp = point['timeStamp'];

              if (latitude == null || longitude == null || timeStamp == null) {
                return null;
              }

              return {
                'latitude': latitude,
                'longitude': longitude,
                'timeStamp': timeStamp,
              };
            })
            .where((point) => point != null)
            .toList();

        tripData.sort((a, b) {
          DateTime? dateA, dateB;
          try {
            dateA = DateTime.parse(a['timeStamp']);
            dateB = DateTime.parse(b['timeStamp']);
          } catch (e) {
            print(
                "Invalid timestamp format found: ${a['timeStamp']} or ${b['timeStamp']}");
          }
          return dateA?.compareTo(dateB ?? DateTime.now()) ?? 0;
        });

        var driverName = doc['driverName'] ?? 'Unknown Driver';
        var startTime = doc['startTime'] ?? "Unknown";
        var endTime = doc['endTime'] ?? "Unknown";

        if (!groupedTrips.containsKey(driverName)) {
          groupedTrips[driverName] = [];
        }

        groupedTrips[driverName]?.add({
          'startTime': startTime,
          'endTime': endTime,
          'tripData': tripData,
        });
      }

      return groupedTrips;
    } catch (e) {
      print('Failed to fetch trip history: $e');
      throw Exception('Failed to fetch trip history: $e');
    }
  }

  // Method to save trip data for a driver
  static Future<void> saveTripData({
    required String driverName,
    required String driverId,
    required String tripId,
    required List<Map<String, dynamic>> tripData,
  }) async {
    try {
      await initialize(); // Ensure MongoDB connection is initialized

      // Check if the collection is initialized
      if (driverTripCollection == null) {
        throw Exception("Trips collection is not initialized.");
      }

      // Build the document to be saved
      var tripDocument = {
        'driverName': driverName,
        'tripId': tripId,
        'tripData': tripData.map((tripPoint) {
          return {
            'latitude': tripPoint['latitude'],
            'longitude': tripPoint['longitude'],
            'timeStamp': tripPoint['timeStamp'],
          };
        }).toList(),
        'startTime': tripData.first['timeStamp'],
        'endTime': DateTime.now().toIso8601String(),
      };

      var driverDoc =
          await driverTripCollection!.findOne(where.eq('driverId', driverId));

      if (driverDoc == null) {
        var newDriverDoc = {
          'driverName': driverName,
          'driverId': driverId,
          'trips': [tripDocument], // Add the trip under the 'trips' array
        };
        await driverTripCollection!.insert(newDriverDoc);
        print(
            "Driver and trip data saved successfully for driver: $driverName");
      } else {
        await driverTripCollection!.update(
            where.eq('driverId', driverId), modify.push('trips', tripDocument));
        print("Trip data appended successfully for driver: $driverName");
      }
    } catch (e) {
      print('Error saving trip data: $e');
      throw Exception('Error saving trip data: $e');
    }
  }

  // Method to update the trip location during the active trip
  static Future<void> updateTripLocation({
    required String driverId,
    required String tripId,
    required Map<String, dynamic> lastTripPoint,
  }) async {
    try {
      await initialize();

      if (driverTripCollection == null) {
        throw Exception('Trips collection is not intialized');
      }

      var driverDoc =
          await driverTripCollection!.findOne(where.eq('driverId', driverId));

      if (driverDoc == null) {
        throw Exception('driver with id $driverId not found');
      }

      var trips = driverDoc['trips'] as List;
      var tripsIndex = trips.indexWhere((trip) => trip['tripId'] == tripId);

      if (tripsIndex == 1) {
        throw Exception('trip with id $tripId not found for driver $driverId');
      }

      trips[tripsIndex]['tripData'].add({
        'latitude': lastTripPoint['latitude'],
        'longitude': lastTripPoint['longitude'],
        'timeStamp': lastTripPoint['timeStamp'],
      });

      await driverTripCollection!
          .update(where.eq('driverId', driverId), modify.set('trips', trips));

      print('trip location updated succesfully for driver: $driverId');
    } catch (e) {
      print('Error updating trip location: $e');
      throw Exception('Error updating trip location: $e');
    }
  }
}
