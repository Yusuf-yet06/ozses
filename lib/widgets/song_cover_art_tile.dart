import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../services/id3_service.dart';
import '../utils/song_media_utils.dart';
import 'mini_eq_visualizer.dart';

// 🎯 SİBER HAMLE: Cihazdan, çevrimdışından ve internetten çekilen müziklerin gerçek kapaklarını gösteren akıllı widget!
class SongCoverArtTile extends StatefulWidget {
  final SongModel song;
  final bool isSelected;
  final bool isPlaying;
  final Color themeColor;
  final double size;

  const SongCoverArtTile({
    super.key,
    required this.song,
    required this.isSelected,
    required this.isPlaying,
    required this.themeColor,
    this.size = 55.0,
  });

  @override
  State<SongCoverArtTile> createState() => _SongCoverArtTileState();
}

class _SongCoverArtTileState extends State<SongCoverArtTile> {
  Uint8List? _localBytes;

  @override
  void initState() {
    super.initState();
    _checkArtwork();
  }

  @override
  void didUpdateWidget(covariant SongCoverArtTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path ||
        oldWidget.song.videoId != widget.song.videoId ||
        oldWidget.song.artUrl != widget.song.artUrl) {
      _localBytes = null;
      _checkArtwork();
    }
  }

  void _checkArtwork() {
    final path = widget.song.path;
    final vid = widget.song.videoId ?? extractVideoIdFromPath(path);
    final art = widget.song.artUrl;

    ID3Service.getCoverBytesForSong(path, videoId: vid, artUrl: art).then((bytes) {
      if (mounted && bytes != null) {
        setState(() {
          _localBytes = bytes;
        });
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final vid = widget.song.videoId ?? extractVideoIdFromPath(widget.song.path);
    final artUrl = widget.song.artUrl;

    Widget content;

    if (_localBytes != null) {
      content = Image.memory(
        _localBytes!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        gaplessPlayback: true,
      );
    } else if (artUrl != null && artUrl.startsWith('http')) {
      content = CachedNetworkImage(
        imageUrl: artUrl,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (vid != null && vid.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.themeColor.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: widget.isSelected
              ? widget.themeColor.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.themeColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (widget.isSelected && widget.isPlaying)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: MiniEqVisualizer(
                      themeColor: widget.themeColor,
                      isPlaying: widget.isPlaying,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.6),
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
