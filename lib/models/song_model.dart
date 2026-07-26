class SongModel {
  final String? title;
  final String? path;
  final String? name;
  final int? duration;
  final String? videoId;
  final String? artUrl;
  final String? artist;

  SongModel({
    this.title,
    this.path,
    this.name,
    this.duration,
    this.videoId,
    this.artUrl,
    this.artist,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'path': path,
      'name': name,
      'duration': duration,
      'videoId': videoId,
      'artUrl': artUrl,
      'artist': artist,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      title: json['title'],
      path: json['path'],
      name: json['name'],
      duration: json['duration'],
      videoId: json['videoId'],
      artUrl: json['artUrl'],
      artist: json['artist'],
    );
  }
}
