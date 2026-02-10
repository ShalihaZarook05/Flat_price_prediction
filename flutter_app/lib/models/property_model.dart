class PropertyModel {
  String area;
  int bedrooms;
  int bathrooms;
  int stories;
  String mainroad;
  String guestroom;
  String basement;
  String hotwaterheating;
  String airconditioning;
  int parking;
  String prefarea;
  String furnishingstatus;

  PropertyModel({
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.stories,
    required this.mainroad,
    required this.guestroom,
    required this.basement,
    required this.hotwaterheating,
    required this.airconditioning,
    required this.parking,
    required this.prefarea,
    required this.furnishingstatus,
  });

  Map<String, dynamic> toJson() => {
        "area": area,
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "stories": stories,
        "mainroad": mainroad,
        "guestroom": guestroom,
        "basement": basement,
        "hotwaterheating": hotwaterheating,
        "airconditioning": airconditioning,
        "parking": parking,
        "prefarea": prefarea,
        "furnishingstatus": furnishingstatus,
      };
}
