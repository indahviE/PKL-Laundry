class ManualAd {
  final String id;
  final String videoUrl;
  final int durationSeconds;
  final String? linkUrl;
  final String? title;

  ManualAd({
    required this.id,
    required this.videoUrl,
    required this.durationSeconds,
    this.linkUrl,
    this.title,
  });

  factory ManualAd.fromFirestore(String id, Map<String, dynamic> data) {
    return ManualAd(
      id: id,
      videoUrl: data['videoUrl'] as String,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 30,
      linkUrl: data['linkUrl'] as String?,
      title: data['title'] as String?,
    );
  }
}