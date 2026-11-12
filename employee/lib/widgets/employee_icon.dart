import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Uses the supplied artwork while retaining Material fallbacks for other actions.
class EmployeeIcon extends StatelessWidget {
  const EmployeeIcon(this.icon, {super.key, this.size, this.color});
  final IconData? icon;
  final double? size;
  final Color? color;

  static final files = <IconData, String>{
    Icons.work_outline: 'briefcase-business.svg',
    Icons.work_outline_rounded: 'briefcase-business.svg',
    Icons.school_outlined: 'graduation-cap.svg',
    Icons.stars_outlined: 'star.svg',
    Icons.description_outlined: 'file-text.svg',
    Icons.card_giftcard: 'gift.svg',
    Icons.bookmark_border: 'bookmark-check.svg',
    Icons.person_outline: 'person_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.home_outlined: 'home_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.notifications_none: 'bell-dot.svg',
    Icons.video_library_outlined: 'clapperboard.svg',
    Icons.chat_bubble_outline: 'message-circle-more.svg',
    Icons.search: 'search_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.mail_outline: 'mail.svg',
    Icons.lock_outline: 'lock.svg',
    Icons.arrow_back: 'arrow_back_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.arrow_forward:
        'arrow_forward_ios_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.add_circle_outline: 'circle-plus.svg',
    Icons.upload_file: 'upload.svg',
    Icons.picture_as_pdf: 'pdf.svg',
    Icons.play_circle_outline: 'tv-minimal-play.svg',
    Icons.people_outline: 'building-complex.svg',
  };

  @override
  Widget build(BuildContext context) {
    final file = files[icon];
    if (file == null) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    // Input decorations give prefix icons a minimum 48px slot. Keep the
    // artwork at the requested size inside that slot, like Material Icon.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SvgPicture.asset(
        'assets/icons/$file',
        width: size ?? theme.size ?? 24,
        height: size ?? theme.size ?? 24,
        colorFilter: ColorFilter.mode(
          color ?? theme.color ?? const Color(0xFF14243C),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
