class TrailerModel {
  final String key;
  final String name;
  final String site;
  final String type;

  TrailerModel({required this.key, required this.name, required this.site, required this.type});

  factory TrailerModel.fromJson(Map<String, dynamic> json) => TrailerModel(
        key: json['key'] as String,
        name: json['name'] as String,
        site: json['site'] as String,
        type: json['type'] as String,
      );
}
