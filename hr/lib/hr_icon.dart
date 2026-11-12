import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared artwork stays centered at 24px even inside a 48px input slot.
class HrIcon extends StatelessWidget {
  const HrIcon(this.icon, {super.key, this.size, this.color});
  final IconData? icon;
  final double? size;
  final Color? color;

  static final files = <IconData, String>{
    Icons.work_outline: 'briefcase-business.svg',
    Icons.business: 'building.svg',
    Icons.business_outlined: 'building.svg',
    Icons.layers_outlined: 'layers.svg',
    Icons.calendar_month: 'calendar-days.svg',
    Icons.location_on_outlined: 'map-pin.svg',
    Icons.phone_outlined: 'phone-call.svg',
    Icons.mail_outline: 'mail.svg',
    Icons.lock_outline: 'lock.svg',
    Icons.description_outlined: 'file-text.svg',
    Icons.add_circle: 'circle-plus.svg',
    Icons.notifications_none: 'bell-dot.svg',
    Icons.school_outlined: 'graduation-cap.svg',
    Icons.workspace_premium_outlined: 'award.svg',
    Icons.currency_rupee: 'indian-rupee.svg',
    Icons.numbers: 'hash.svg',
    Icons.laptop_mac: 'laptop-minimal.svg',
    Icons.delete_outline: 'trash.svg',
    Icons.upload_file: 'upload.svg',
    Icons.search: 'search_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.home_outlined: 'home_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.person_outline: 'person_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.arrow_back: 'arrow_back_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.chevron_right:
        'arrow_forward_ios_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.edit_outlined: 'edit_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
    Icons.logout: 'logout_24dp_1F1F1F_FILL0_wght400_GRAD0_opsz24.svg',
  };

  @override
  Widget build(BuildContext context) {
    final file = files[icon];
    if (file == null) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    final extent = size ?? theme.size ?? 24;
    return Semantics(
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SvgPicture.asset(
          file,
          package: 'career_connect_assets',
          width: extent,
          height: extent,
          colorFilter: ColorFilter.mode(
            color ?? theme.color ?? const Color(0xFF10133F),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

IconData hrFieldIcon(String label) {
  final text = label.toLowerCase();
  if (text.contains('password') || text.contains('code')) {
    return Icons.lock_outline;
  }
  if (text.contains('email')) return Icons.mail_outline;
  if (text.contains('phone') || text.contains('mobile')) {
    return Icons.phone_outlined;
  }
  if (text.contains('location') || text.contains('area')) {
    return Icons.location_on_outlined;
  }
  if (text.contains('year') || text.contains('date')) {
    return Icons.calendar_month;
  }
  if (text.contains('size') || text.contains('opening')) {
    return Icons.people_outline;
  }
  if (text.contains('industry')) return Icons.layers_outlined;
  if (text.contains('website')) return Icons.language;
  if (text.contains('salary')) return Icons.currency_rupee;
  if (text.contains('experience')) return Icons.workspace_premium_outlined;
  if (text.contains('qualification')) return Icons.school_outlined;
  if (text.contains('mode')) return Icons.laptop_mac;
  if (text.contains('description') || text.contains('about')) {
    return Icons.description_outlined;
  }
  if (text.contains('company')) return Icons.business_outlined;
  return Icons.work_outline;
}
