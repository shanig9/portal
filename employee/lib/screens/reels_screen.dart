import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../services/reels_service.dart';
import '../services/reel_storage.dart';
import '../state/employee_controller.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({
    super.key,
    required this.state,
    required this.immersive,
    required this.onToggleImmersive,
    this.service,
  });
  final EmployeeController state;
  final bool immersive;
  final VoidCallback onToggleImmersive;
  final ReelsService? service;
  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  late final _service = widget.service ?? ReelsService();
  final _reels = <Reel>[];
  final _pages = PageController();
  bool _loading = false, _uploading = false, _foreground = true;
  String? _cursor;
  String? _loadError;
  int _active = 0;
  Timer? _syncTimer;
  Future<void> _syncPending() async {
    try {
      await _service.syncPending();
      if (!mounted) return;
      final device = await _service.deviceReels();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _reels.length; i++) {
          final matches = device.where((item) => item.id == _reels[i].id);
          if (matches.isNotEmpty) _reels[i] = matches.first;
        }
        final remoteIds = device
            .map((item) => item.remoteId)
            .whereType<String>()
            .toSet();
        final activeId = _reels.isEmpty ? null : _reels[_active].id;
        _reels.removeWhere((item) => remoteIds.contains(item.id));
        final index = _reels.indexWhere((item) => item.id == activeId);
        _active = index < 0 ? 0 : index;
      });
    } catch (_) {
      // Keep saved videos queued until a later foreground retry.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _syncPending();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) {
        _syncPending();
        _load();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
      if (_foreground) {
        _syncPending();
        _load();
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (!more) {
        final device = await _service.deviceReels();
        if (!mounted) return;
        setState(() {
          _reels.addAll(
            device.where((item) => !_reels.any((r) => r.id == item.id)),
          );
        });
      }
      final page = await _service.list(cursor: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        _reels.addAll(
          page.items.where(
            (item) =>
                !_reels.any((r) => r.id == item.id || r.remoteId == item.id),
          ),
        );
        _cursor = page.nextCursor;
      });
    } catch (error) {
      if (mounted && _reels.isEmpty) {
        setState(() => _loadError = ReelsService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'webm'],
      );
      if (file == null || !mounted) return;
      final size = await file.length();
      if (size == null || size > 50 * 1024 * 1024) {
        throw Exception('Files must be 50 MB or smaller.');
      }
      if (!mounted) return;
      final caption = await showDialog<String>(
        context: context,
        builder: (_) => const _CaptionDialog(),
      );
      if (caption == null) return;
      final bytes = await file.readAsBytes();
      final reel = await _service.saveOnDevice(bytes, file.name, caption);
      if (!mounted) return;
      setState(() {
        _reels.insert(0, reel);
        _active = 0;
      });
      if (_pages.hasClients) _pages.jumpToPage(0);
      unawaited(_syncPending());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel saved. Sharing in the background.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ReelsService.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_reels.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _loading
                    ? 'Loading reels…'
                    : _loadError ?? 'Add a video to start your reels.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
        else
          PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: (index) {
              setState(() => _active = index);
              if (index >= _reels.length - 2 && _cursor != null) {
                _load(more: true);
              }
            },
            itemBuilder: (context, index) {
              final reel = _reels[index];
              return _ReelCard(
                key: ValueKey(reel.id),
                reel: reel,
                active: index == _active && _foreground && !_uploading,
                liked: widget.state.likedReels.contains(reel.id),
                onLike: () => widget.state.update(() {
                  if (!widget.state.likedReels.add(reel.id)) {
                    widget.state.likedReels.remove(reel.id);
                  }
                }),
                onRetryUpload: _syncPending,
              );
            },
          ),
        Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (!widget.immersive)
                        IconButton(
                          tooltip: 'Open posts',
                          onPressed: () => widget.state.open('Home'),
                          icon: const Icon(
                            Icons.article_outlined,
                            color: Colors.white,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Refresh reels',
                        onPressed: _loading || _uploading
                            ? null
                            : () {
                                _syncPending();
                                _load();
                              },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: widget.immersive
                            ? 'Exit full screen'
                            : 'Full screen',
                        onPressed: widget.onToggleImmersive,
                        icon: Icon(
                          widget.immersive
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilledButton.icon(
                          onPressed: _uploading ? null : _upload,
                          icon: const Icon(Icons.add),
                          label: Text(_uploading ? 'Saving…' : 'Add video'),
                        ),
                      ),
                    ],
                  ),
                  if (_uploading) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptionDialog extends StatefulWidget {
  const _CaptionDialog();
  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  final _caption = TextEditingController();
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Share a reel'),
    content: TextField(
      controller: _caption,
      maxLength: 500,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Caption',
        helperText: 'Videos can be up to 60 seconds.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _caption.text.trim()),
        child: const Text('Share reel'),
      ),
    ],
  );
}

class _ReelCard extends StatefulWidget {
  const _ReelCard({
    super.key,
    required this.reel,
    required this.active,
    required this.liked,
    required this.onLike,
    required this.onRetryUpload,
  });
  final Reel reel;
  final bool active;
  final bool liked;
  final VoidCallback onLike, onRetryUpload;
  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  VideoPlayerController? _video;
  bool _failed = false, _paused = false, _muted = true;
  void _onVideoChanged() {
    if (mounted && _video?.value.hasError == true && !_failed) {
      setState(() => _failed = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _paused = false;
      _sync();
    }
  }

  Future<void> _sync() async {
    if (widget.reel.type != 'video') return;
    if (!widget.active) {
      final old = _video;
      _video = null;
      await old?.dispose();
      return;
    }
    if (_video != null) return;
    _failed = false;
    final url = widget.reel.url;
    final controller = url.startsWith('assets/')
        ? VideoPlayerController.asset(url)
        : url.startsWith('file:')
        ? localReelPlayer(url)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    _video = controller;
    controller.addListener(_onVideoChanged);
    try {
      await controller.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || _video != controller || !widget.active) return;
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted || _video != controller || !widget.active) return;
      await controller.play();
      if (mounted) setState(() => _failed = false);
    } catch (_) {
      if (mounted && _video == controller) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.reel.type == 'image')
          Image.network(
            widget.reel.url,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => const Center(
              child: Text(
                'Image unavailable',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else if (_failed)
          Center(
            child: TextButton(
              onPressed: () async {
                final old = _video;
                _video = null;
                await old?.dispose();
                if (!mounted) return;
                setState(() => _failed = false);
                _sync();
              },
              child: const Text('Playback failed. Tap to retry'),
            ),
          )
        else if (_video?.value.isInitialized == true)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox.fromSize(
                size: _video!.value.size,
                child: VideoPlayer(_video!),
              ),
            ),
          )
        else if (widget.active)
          const Center(child: CircularProgressIndicator()),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 72,
          bottom: 18 + MediaQuery.paddingOf(context).bottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.reel.author,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.reel.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              if (widget.reel.pending) ...[
                Text(
                  widget.reel.uploadError ?? 'Saved on this device. Sharing…',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (widget.reel.uploadError != null &&
                    !widget.reel.needsAttention)
                  TextButton(
                    onPressed: widget.onRetryUpload,
                    child: const Text(
                      'Retry upload',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
              if (_video?.value.isInitialized == true)
                Row(
                  children: [
                    IconButton(
                      tooltip: _paused ? 'Play reel' : 'Pause reel',
                      onPressed: () {
                        setState(() => _paused = !_paused);
                        _paused ? _video!.pause() : _video!.play();
                      },
                      icon: Icon(
                        _paused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: _muted ? 'Unmute reel' : 'Mute reel',
                      onPressed: () {
                        setState(() => _muted = !_muted);
                        _video!.setVolume(_muted ? 0 : 1);
                      },
                      icon: Icon(
                        _muted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 18 + MediaQuery.paddingOf(context).bottom,
          child: IconButton.filledTonal(
            tooltip: widget.liked ? 'Unlike reel' : 'Like reel',
            onPressed: widget.onLike,
            icon: Icon(
              widget.liked ? Icons.favorite : Icons.favorite_border,
              color: widget.liked ? Colors.redAccent : Colors.white,
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ),
      ],
    ),
  );
}
