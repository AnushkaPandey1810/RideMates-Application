
class PredictedPlaces {
  String? place_id;          // Unique identifier for the place
  String? main_text;         // Primary text (e.g., name of the place)
  String? secondary_text;    // Secondary text (e.g., address or additional name information)

  // Constructor for creating a PredictedPlaces instance
  PredictedPlaces({this.place_id, this.main_text, this.secondary_text});

  // Factory constructor to create a PredictedPlaces instance from JSON data
  PredictedPlaces.fromJson(Map<String, dynamic> jsonData) {
    place_id = jsonData["place_id"];
    main_text = jsonData["structured_formatting"]["main_text"];
    secondary_text = jsonData["structured_formatting"]["secondary_text"];
  }
}