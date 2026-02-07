import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoViewerPage extends StatefulWidget {
  final String url;
  final String? title;
  final String? heroTag;

  const VideoViewerPage({
    super.key,
    required this.url,
    this.title,
    this.heroTag,
  });

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  bool _error = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initFuture = _controller!
        .initialize()
        .catchError((_) {
          setState(() => _error = true);
        })
        .then((_) {
          if (mounted && _controller != null && !_error) {
            _controller!.setLooping(true);
            _controller!.play();
            setState(() {});
            _controller!.addListener(() {
              if (mounted) setState(() {});
            });
            _resetHideTimer();
          }
        });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _resetHideTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    _resetHideTimer();
  }

  void _seekRelative(Duration delta) async {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final duration = _controller!.value.duration;
    Duration target = current + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    await _controller!.seekTo(target);
    _resetHideTimer();
  }

  String _format(Duration d) {
    final totalSeconds = d.inSeconds;
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final useHero = widget.heroTag != null && widget.heroTag!.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title ?? 'فيديو'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _error
            ? Text(
                'تعذر تشغيل الفيديو'.tr,
                style: const TextStyle(color: Colors.white),
              )
            : FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  if (_controller == null ||
                      !_controller!.value.isInitialized) {
                    return Text(
                      'تعذر تشغيل الفيديو'.tr,
                      style: const TextStyle(color: Colors.white),
                    );
                  }
                  final playing = _controller!.value.isPlaying;
                  final position = _controller!.value.position;
                  final duration = _controller!.value.duration;
                  final player = GestureDetector(
                    onTap: _toggleControls,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                        if (_showControls)
                          Container(
                            color: Colors.black38,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      iconSize: 32,
                                      color: Colors.white,
                                      onPressed: () => _seekRelative(
                                        const Duration(seconds: -10),
                                      ),
                                      icon: const Icon(Icons.replay_10),
                                    ),
                                    IconButton(
                                      iconSize: 48,
                                      color: Colors.white,
                                      onPressed: _togglePlay,
                                      icon: Icon(
                                        playing
                                            ? Icons.pause_circle
                                            : Icons.play_circle,
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 32,
                                      color: Colors.white,
                                      onPressed: () => _seekRelative(
                                        const Duration(seconds: 10),
                                      ),
                                      icon: const Icon(Icons.forward_10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _format(position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Expanded(
                                        child: VideoProgressIndicator(
                                          _controller!,
                                          allowScrubbing: true,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          colors: const VideoProgressColors(
                                            playedColor: Colors.blueAccent,
                                            bufferedColor: Colors.white30,
                                            backgroundColor: Colors.white10,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _format(duration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          AnimatedOpacity(
                            opacity: 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  );
                  if (useHero) {
                    return Hero(tag: widget.heroTag!, child: player);
                  }
                  return player;
                },
              ),
      ),
    );
  }
}
