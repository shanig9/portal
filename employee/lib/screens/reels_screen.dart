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
    this.fullScreen = false,
    this.pageController,
  });
  final EmployeeController state;
  final bool fullScreen;
  final PageController? pageController;
  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final _service = ReelsService();
  final _reels = <Reel>[];
  late final PageController _pages;
  bool _loading = false, _uploading = false, _foreground = true;
  String? _error, _cursor;
  int _active = 0;
  Timer? _syncTimer;
  Future<void> _syncPending() async {
    try {
      await _service.syncPending();
    } catch (_) {
      // Keep saved videos queued until a later foreground retry.
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = widget.pageController ?? PageController();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _syncPending();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) _syncPending();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.pageController == null) _pages.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!more) {
        final device = await _service.deviceReels();
        if (!mounted) return;
        setState(() {
          _reels
            ..clear()
            ..addAll(device);
          _active = 0;
          _cursor = null;
        });
      }
      final page = await _service.list(cursor: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        if (!more) {
          _active = 0;
        }
        _reels.addAll(
          page.items.where((item) => !_reels.any((r) => r.id == item.id)),
        );
        _cursor = page.nextCursor;
      });
      if (!more && _pages.hasClients) _pages.jumpToPage(0);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _reels.isEmpty
              ? 'Choose a video to start your device library. Online reels are temporarily unavailable.'
              : 'Showing saved reels. Online reels will return when connected.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _foreground = false;
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
      _syncPending();
      if (!mounted) return;
      setState(() {
        _reels.insert(0, reel);
        _active = 0;
        _error = null;
      });
      if (_pages.hasClients) _pages.jumpToPage(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved on your phone. Will post when connected.'),
        ),
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
          _foreground = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Career Connect Reels\nYour device library + online reels',
              ),
              IconButton(
                tooltip: 'Refresh reels',
                onPressed: _loading || _uploading ? null : () => _load(),
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.icon(
                onPressed: _uploading || _loading ? null : _upload,
                icon: const Icon(Icons.add),
                label: Text(_uploading ? 'Saving...' : 'Add video'),
              ),
            ],
          ),
        ),
        if (_uploading || _loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(_error!),
                TextButton(
                  onPressed: () => _load(more: _reels.isNotEmpty),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _reels.isEmpty
              ? Center(
                  child: Text(
                    _loading
                        ? 'Loading reels...'
                        : _error != null
                        ? 'Reels could not be loaded.'
                        : 'No reels yet. Share your first image or video.',
                  ),
                )
              : PageView.builder(
                  key: ValueKey(_reels.first.id),
                  controller: _pages,
                  scrollDirection: Axis.vertical,
                  itemCount: _reels.length,
                  onPageChanged: (index) {
                    setState(() => _active = index);
                    if (index >= _reels.length - 2 && _cursor != null) {
                      _load(more: true);
                    }
                  },
                  itemBuilder: (context, index) => _ReelCard(
                    key: ValueKey(_reels[index].id),
                    reel: _reels[index],
                    active: index == _active && _foreground && !_uploading,
                  ),
                ),
        ),
        if (_cursor != null && !_loading)
          TextButton(
            onPressed: () => _load(more: true),
            child: const Text('Load more reels'),
          ),
      ],
    );
    if (!widget.fullScreen) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Career Connect Reels')),
      body: content,
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
        helperText:
            'Saved on your phone, then posted when connected. Max 60 seconds.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _caption.text.trim()),
        child: const Text('Save on device'),
      ),
    ],
  );
}

class _ReelCard extends StatefulWidget {
  const _ReelCard({super.key, required this.reel, required this.active});
  final Reel reel;
  final bool active;
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
            fit: BoxFit.contain,
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
          Center(
            child: AspectRatio(
              aspectRatio: _video!.value.aspectRatio,
              child: VideoPlayer(_video!),
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
          right: 20,
          bottom: 24,
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
              const Text(
                'Swipe up for more',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
