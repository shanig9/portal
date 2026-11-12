import '../widgets/employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../theme.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({
    super.key,
    required this.state,
    this.fullScreen = false,
    this.pageController,
  });
  final EmployeeController state;
  final bool fullScreen;
  final PageController? pageController;

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => _ReelViewer(state: state, initialIndex: index),
      ),
    );
  }

  static const _reels = [
    (
      category: 'Interview',
      title: 'Your next interview.\nYour best first impression.',
      description:
          'Prepare your story. Research the company. Ask thoughtful questions.',
      icon: Icons.record_voice_over,
    ),
    (
      category: 'Job Tips',
      title: 'Make your resume\nstand out.',
      description: 'Highlight your results. Tailor your skills to the role. Keep it clear.',
      icon: Icons.description_outlined,
    ),
    (
      category: 'Career',
      title: 'Build skills.\nOpen new doors.',
      description:
          'Learn something new. Put it into practice. Share your progress.',
      icon: Icons.trending_up,
    ),
    (
      category: 'Interview',
      title: 'Tell your story\nwith confidence.',
      description:
          'Describe the situation, your actions, and the impact you made.',
      icon: Icons.chat_bubble_outline,
    ),
    (
      category: 'Job Tips',
      title: 'Find a role\nthat fits you.',
      description:
          'Explore the team, understand the role, and ask about growth.',
      icon: Icons.work_outline,
    ),
    (
      category: 'Career',
      title: 'Grow your\nprofessional network.',
      description: 'Start a conversation. Exchange ideas. Stay connected.',
      icon: Icons.people_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final category = state.data['reelCategory'] ?? 'For You';
    final reels = _reels
        .where((reel) => category == 'For You' || reel.category == category)
        .toList();
    final content = Column(
      children: [
        if (!fullScreen)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              spacing: 8,
              children: ['For You', 'Job Tips', 'Interview', 'Career']
                  .map(
                    (name) => ChoiceChip(
                      label: Text(name),
                      selected: category == name,
                      onSelected: (_) =>
                          state.update(() => state.data['reelCategory'] = name),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: PageView.builder(
            key: ValueKey(category),
            controller: pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              final likeKey = 'reelLiked:${reel.title}';
              final liked = state.data[likeKey] == 'true';
              return GestureDetector(
                onTap: fullScreen ? null : () => _openViewer(context, index),
                child: Padding(
                  padding: fullScreen
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(fullScreen ? 0 : 24),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/career_mentor.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Color(0x990B2340),
                          BlendMode.darken,
                        ),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF142B4B), blue],
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              fullScreen
                                  ? MediaQuery.paddingOf(context).top + 64
                                  : 24,
                              24,
                              fullScreen
                                  ? MediaQuery.paddingOf(context).bottom + 24
                                  : 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${reel.category} · CAREER CLASS',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${index + 1} / ${reels.length}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      EmployeeIcon(
                                        reel.icon,
                                        size: 64,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        reel.title,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        reel.description,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Career Connect',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: liked
                                              ? 'Unlike reel'
                                              : 'Like reel',
                                          onPressed: () => state.update(
                                            () => state.data[likeKey] = (!liked)
                                                .toString(),
                                          ),
                                          icon: EmployeeIcon(
                                            liked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => state.update(
                                        () =>
                                            state.following = !state.following,
                                      ),
                                      icon: EmployeeIcon(
                                        state.following
                                            ? Icons.check
                                            : Icons.add,
                                      ),
                                      label: Text(
                                        state.following
                                            ? 'Following Career Connect'
                                            : 'Follow Career Connect',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      !fullScreen
                                          ? 'Tap to open full screen'
                                          : index < reels.length - 1
                                          ? 'Swipe up for next reel'
                                          : 'Swipe down for previous reel',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!fullScreen)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Illustrated previews. Video playback needs a connected media source.',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
    if (!fullScreen) return content;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              tooltip: 'Back to reels',
              onPressed: () => Navigator.of(context).pop(),
              icon: const EmployeeIcon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelViewer extends StatefulWidget {
  const _ReelViewer({required this.state, required this.initialIndex});
  final EmployeeController state;
  final int initialIndex;

  @override
  State<_ReelViewer> createState() => _ReelViewerState();
}

class _ReelViewerState extends State<_ReelViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) => ReelsScreen(
      state: widget.state,
      fullScreen: true,
      pageController: _controller,
    ),
  );
}
