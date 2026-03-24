class Place {
  final String nodeId;
  final int? id;
  final String placeName;
  final String category;
  final String contact;
  final String alias;

  const Place({
    required this.nodeId,
    this.id,
    required this.placeName,
    required this.category,
    required this.contact,
    required this.alias,
  });
}
