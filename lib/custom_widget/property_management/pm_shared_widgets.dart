import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/property_management/pm_store.dart';
import '../../model/property_management/pm_models.dart';
import '../../model/my_data_models.dart';

/// Property Management "theme pack" - one shared, color-coded design
/// system so every owner/tenant screen looks like one cohesive premium
/// product instead of flat white-on-navy. Each module (rent, tenants,
/// vehicles, documents, maintenance, notices, reports, buildings) gets
/// its own accent color used consistently for icons, chips, buttons and
/// card tints - this is what makes the app scannable at a glance.

const pmNavy = Color(0xFF0A0E27); // deep navy base (richer than flat #001234)
const pmNavyDeep = Color(0xFF060A1A);
const pmCardNavy = Color(0xFF131A3A);
const pmCardNavyLight = Color(0xFF1B2448);

/// Light-mode counterparts of the dark navy palette above - used when
/// the Property Management module's own light/dark toggle (stored in
/// [PmStore.isDark], scoped to this module only - the rest of the app
/// has no dark mode and is untouched) is switched to light.
const pmLightBg = Color(0xFFF2F4FA);
const pmLightBgDeep = Color(0xFFE7EAF3);
const pmLightCard = Color(0xFFFFFFFF);
const pmLightCardSoft = Color(0xFFF7F8FC);
const pmLightTextPrimary = Color(0xFF12152B);

/// Semantic, theme-aware colors every PM screen should use instead of
/// hardcoding `pmNavy` / `Colors.white` directly, so the whole module
/// reacts instantly to [PmStore.isDark]. Accent colors (PmColors.*)
/// never change with theme - they're the "green=money, blue=people"
/// language that stays constant; only neutral bg/card/text do.
class PmTheme {
  static bool get isDark => PmStore.instance.isDark;

  static Color get bg => isDark ? pmNavy : pmLightBg;
  static Color get bgDeep => isDark ? pmNavyDeep : pmLightBgDeep;
  static Color get card => isDark ? pmCardNavyLight : pmLightCard;
  static Color get cardSoft => isDark ? pmCardNavy : pmLightCardSoft;
  static Color get cardBorder =>
      isDark ? Colors.white.withOpacity(0.08) : pmLightTextPrimary.withOpacity(0.07);
  static Color get divider =>
      isDark ? Colors.white.withOpacity(0.08) : pmLightTextPrimary.withOpacity(0.08);
  static Color get textPrimary => isDark ? Colors.white : pmLightTextPrimary;
  static Color get textSecondary =>
      isDark ? Colors.white.withOpacity(0.65) : pmLightTextPrimary.withOpacity(0.62);
  static Color get textMuted =>
      isDark ? Colors.white.withOpacity(0.45) : pmLightTextPrimary.withOpacity(0.40);
  static Color get iconMuted =>
      isDark ? Colors.white.withOpacity(0.55) : pmLightTextPrimary.withOpacity(0.45);
}

/// Small sun/moon pill that flips [PmStore.isDark] - drop into any PM
/// app bar's actions. Self-contained: reads/writes the store directly,
/// no parameters needed.
class PmThemeToggle extends StatelessWidget {
  const PmThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = PmTheme.isDark;
    // Deliberately a bare GestureDetector + Icon - no IconButton, no
    // Material, no InkWell, no Tooltip wrapping. Those can each carry
    // their own ambient IconTheme/ColorScheme merge logic; this has
    // NOTHING between the tap target and the Icon that could ever
    // recolor it, so the color below is exactly what renders.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => PmStore.instance.toggleTheme(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: Colors.orange,
          size: 22,
        ),
      ),
    );
  }
}


/// Module accent colors - used everywhere that module appears, so the
/// user learns "green = money, blue = people, orange = vehicles..."
/// within seconds instead of reading every label.
class PmColors {
  static const rent = Color(0xFF22C55E); // green - money/rent
  static const rentSoft = Color(0xFF34D399);
  static const pending = Color(0xFFF5A623); // amber - needs action
  static const overdue = Color(0xFFFF5C5C); // red - urgent
  static const tenant = Color(0xFF4F9DFF); // blue - people
  static const vehicle = Color(0xFFFF9F43); // orange - vehicles
  static const document = Color(0xFFB084F5); // purple - documents
  static const maintenance = Color(0xFFFF7A7A); // coral - maintenance
  static const notice = Color(0xFFFF5C93); // pink - notices/move-out
  static const reports = Color(0xFF22D3EE); // cyan - reports/insights
  static const building = Color(0xFF2DD4BF); // teal - buildings/property
  static const expense = Color(0xFFFF9F43); // orange - expenses
  static const agreement = Color(0xFF5C6BC0); // indigo - rental agreement
  static const verification = Color(0xFF26A69A); // teal-green - police/ID verification
  static const insurance = Color(0xFF42A5F5); // sky blue - insurance
  static const utility = Color(0xFF8D6E63); // brown - utility meter/bills

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// The amber "this is sample/demo data" banner used across every PM
/// screen that shows anything not confirmed to be real.
class PmPreviewBanner extends StatelessWidget {
  final String text;
  const PmPreviewBanner({
    super.key,
    this.text = 'DESIGN PREVIEW - SAMPLE/DEMO DATA (not connected to any backend)',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PmColors.pending.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PmColors.pending.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: PmColors.pending, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: PmColors.pending.withOpacity(0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big gradient "hero" card for the headline number on a dashboard
/// (e.g. scheduled rent) - the aurora-gradient treatment from the
/// reference mockups, used sparingly (one per screen) so it stays
/// special instead of noisy.
class PmHeroCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  const PmHeroCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon = Icons.account_balance_wallet_outlined,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: PmColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PmGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  const PmGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: PmTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent != null ? accent!.withOpacity(0.25) : PmTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(PmTheme.isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PmSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool? dark;
  /// A custom widget for the top-right corner (e.g. a [PmShowMoreButton])
  /// - takes priority over [actionLabel]/[onAction] when provided, so a
  /// section can show something other than a plain TextButton up there.
  final Widget? trailing;
  const PmSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.dark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? PmTheme.isDark;
    final color = isDark ? Colors.white : PmTheme.textPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? color, size: 17),
              const SizedBox(width: 6),
            ],
            Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// A stat tile with a small colored icon badge - replaces the old plain
/// grey chip so the overview grid reads at a glance (green=money,
/// blue=people, orange=vehicles...).
class PmStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool? dark;
  const PmStatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = PmColors.building,
    this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? PmTheme.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: isDark ? Colors.white : PmTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.55) : PmTheme.textSecondary, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class PmStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const PmStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// A colored quick-action button (icon in a gradient-filled circle) -
/// replaces the old flat grey-icon-on-grey-box buttons.
class PmActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  /// True for an action backed by real synced data (My Buildings,
  /// Agreement, Insurance) rather than the sample portfolio - draws a
  /// small "LIVE" corner badge so it reads differently from the demo
  /// actions at a glance.
  final bool live;
  const PmActionButton({super.key, required this.icon, required this.label, required this.color, required this.onTap, this.live = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                if (live)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: PmColors.rent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PmTheme.card, width: 1.5),
                      ),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: PmTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

enum PmAttentionLevel { info, warning, critical }

Color pmAttentionColor(PmAttentionLevel level) {
  switch (level) {
    case PmAttentionLevel.critical:
      return PmColors.overdue;
    case PmAttentionLevel.warning:
      return PmColors.pending;
    case PmAttentionLevel.info:
      return PmColors.tenant;
  }
}

/// A colored-background attention row (red tint for urgent, amber for
/// needs-review, blue for informational) - replaces the old plain glass
/// row so the owner's eye jumps straight to what's urgent.
class PmAttentionRow extends StatelessWidget {
  final IconData icon;
  final PmAttentionLevel level;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  const PmAttentionRow({
    super.key,
    required this.icon,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = pmAttentionColor(level);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: PmTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: PmTheme.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 6)),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class PmEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool? dark;
  const PmEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? PmTheme.isDark;
    final faint = isDark ? Colors.white.withOpacity(0.35) : PmTheme.textPrimary.withOpacity(0.22);
    final text = isDark ? Colors.white.withOpacity(0.55) : PmTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: faint, size: 30),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 12.5)),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// App-wide bottom-sheet convention (matches Service_Page.dart,
/// Booking_form.dart, My_service.dart etc.): white container, rounded
/// top, drag handle, SafeArea.
Future<T?> pmShowSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  double initialSize = 0.6,
  double maxSize = 0.92,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.35,
      maxChildSize: maxSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void pmShowComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$what is coming in a later milestone - not available yet.'),
      duration: const Duration(seconds: 2),
    ),
  );
}

void pmShowSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

/// ---------------------------------------------------------------------
/// Generic elevated "entity" card - replaces every plain ListTile row
/// across the PM module (buildings, flats, expenses, family members,
/// vehicles, documents) with one consistent, theme-aware, modern card:
/// gradient icon badge, title, optional subtitle, an optional extra
/// slot (e.g. an occupancy progress bar), an optional row of small
/// detail chips, and a trailing widget (defaults to a chevron).
/// ---------------------------------------------------------------------
class PmEntityCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final List<Widget>? details;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PmEntityCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.extra,
    this.details,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: PmTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(PmTheme.isDark ? 0.16 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.55)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(color: accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: PmTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(subtitle!, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
                        ],
                        if (extra != null) ...[
                          const SizedBox(height: 6),
                          extra!,
                        ],
                        if (details != null && details!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 10, runSpacing: 4, children: details!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ?? Icon(Icons.chevron_right, color: PmTheme.iconMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small detail chip used inside [PmEntityCard.details] - a tiny icon +
/// text pairing (e.g. "2 BHK", "Floor 3", "₹500") that keeps supporting
/// info scannable instead of a dense paragraph.
class PmCardDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const PmCardDetail({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? PmTheme.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Show more / Show less - same interaction and label/arrow convention
/// as the "Connect with us" (Social Links) section on the Profile page
/// (lib/Screens/profile.dart): a text-link toggle, instant show/hide,
/// no animation. Re-themed to a PmTheme-aware accent instead of a
/// hardcoded Colors.blue, since this module (unlike Profile) has its
/// own dark/light toggle that the link color must stay legible under.
/// ---------------------------------------------------------------------
class PmShowMoreButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const PmShowMoreButton({super.key, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        expanded ? 'Show less ▲' : 'Show more ▼',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PmColors.tenant),
      ),
    );
  }
}

/// A [Wrap] that shows only the first [visibleCount] children by
/// default, with a [PmShowMoreButton] beneath it to reveal the rest -
/// the exact Show More/Show Less pattern requested for Quick Actions
/// and Property Overview, built as one reusable, state-driven widget
/// so any future section can opt in with a single line.
class PmExpandableWrap extends StatefulWidget {
  final List<Widget> children;
  final int visibleCount;
  final double spacing;
  final double runSpacing;
  const PmExpandableWrap({
    super.key,
    required this.children,
    this.visibleCount = 3,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  @override
  State<PmExpandableWrap> createState() => _PmExpandableWrapState();
}

class _PmExpandableWrapState extends State<PmExpandableWrap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.children.length > widget.visibleCount;
    final shown = (_expanded || !hasMore) ? widget.children : widget.children.take(widget.visibleCount).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: widget.spacing, runSpacing: widget.runSpacing, children: shown),
        if (hasMore) ...[
          const SizedBox(height: 10),
          PmShowMoreButton(expanded: _expanded, onTap: () => setState(() => _expanded = !_expanded)),
        ],
      ],
    );
  }
}


// ---------------------------------------------------------------------
// Tenant contact actions - Call / WhatsApp / Message. Every one of
// these checks for a stored phone number first (PmFlat.tenantPhone,
// still nullable - never guessed, see pm_models.dart) and shows a
// plain snackbar instead of a broken link when it's not been provided
// yet, rather than failing silently or crashing on a null.
// ---------------------------------------------------------------------
Future<void> pmLaunchPhoneCall(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    pmShowSnack(context, 'No phone number on record for this tenant yet.');
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone.trim());
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    pmShowSnack(context, 'Could not open the dialer.');
  }
}

Future<void> pmLaunchWhatsApp(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    pmShowSnack(context, 'No phone number on record for this tenant yet.');
    return;
  }
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri.parse('https://wa.me/$digits');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    pmShowSnack(context, 'Could not open WhatsApp.');
  }
}

Future<void> pmLaunchSms(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    pmShowSnack(context, 'No phone number on record for this tenant yet.');
    return;
  }
  final uri = Uri(scheme: 'sms', path: phone.trim());
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    pmShowSnack(context, 'Could not open Messages.');
  }
}

/// ---------------------------------------------------------------------
/// Circular avatar showing initials on a colored background - used
/// anywhere the app would otherwise need a tenant/person photo it has
/// no storage for (Building Detail's flat rows, Flat Detail's header).
/// ---------------------------------------------------------------------
class PmInitialsAvatar extends StatelessWidget {
  final String? name;
  final Color color;
  final double radius;
  final IconData fallbackIcon;
  const PmInitialsAvatar({
    super.key,
    required this.name,
    required this.color,
    this.radius = 22,
    this.fallbackIcon = Icons.person_outline,
  });

  String get _initials {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.18),
      child: initials.isEmpty
          ? Icon(fallbackIcon, color: color, size: radius)
          : Text(initials, style: TextStyle(color: color, fontSize: radius * 0.75, fontWeight: FontWeight.w800)),
    );
  }
}

/// ---------------------------------------------------------------------
/// Compact "My Buildings" card - colored icon badge, title, flats/rented
/// counts, scheduled rent, and a few icon detail rows (caretaker, meter
/// type, lift/parking). Detail rows are built only from fields the
/// owner actually provided on [PmBuilding] - anything left null/unknown
/// is simply omitted, never guessed (same rule as the rest of this
/// module's data model).
/// ---------------------------------------------------------------------
class PmBuildingSummaryCard extends StatelessWidget {
  final PmBuilding building;
  final Color accent;
  final bool amountsHidden;
  final VoidCallback? onTap;
  const PmBuildingSummaryCard({
    super.key,
    required this.building,
    required this.accent,
    this.amountsHidden = false,
    this.onTap,
  });

  List<Widget> _detailRows() {
    final rows = <Widget>[];
    if (building.caretaker != null && building.caretaker!.trim().isNotEmpty) {
      rows.add(_row(Icons.person_outline, '${building.caretaker} - Caretaker'));
    }
    switch (building.meterType) {
      case MeterType.individualSubMeter:
        final rate = building.subMeterRatePerUnit;
        rows.add(_row(
          Icons.bolt_outlined,
          rate != null ? 'Sub-meters - Rs ${rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2)}/unit' : 'Individual sub-meters',
        ));
        break;
      case MeterType.governmentMeter:
        rows.add(_row(Icons.bolt_outlined, 'Government/discom meter'));
        break;
      case MeterType.unknown:
        break; // not provided - never guessed
    }
    final parking = building.parkingCapacity != null && building.parkingCapacity! > 0;
    if (building.hasLift == true) {
      rows.add(_row(Icons.elevator_outlined, parking ? 'Lift - Parking' : 'Lift'));
    } else if (building.hasLift == false) {
      rows.add(_row(Icons.block_outlined, 'No lift'));
      if (parking) rows.add(_row(Icons.local_parking_outlined, 'Parking'));
    } else if (parking) {
      rows.add(_row(Icons.local_parking_outlined, 'Parking'));
    }
    return rows;
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 12.5, color: PmTheme.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmTheme.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: PmTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(PmTheme.isDark ? 0.16 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, accent.withOpacity(0.55)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 19),
              ),
              const SizedBox(height: 10),
              Text(building.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmTheme.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${building.unitCount} flats - ${building.rentedCount} rented', style: TextStyle(color: PmTheme.textSecondary, fontSize: 11.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded, size: 13, color: PmColors.rentSoft),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      amountsHidden ? 'Monthly rent *****' : 'Monthly rent ${pmFormatInr(building.scheduledRent)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: PmColors.rentSoft, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              ..._detailRows(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Pill-style tab bar - a rounded track (PmTheme.cardSoft) holding a
/// TabBar whose selected tab gets a solid-color pill indicator, matching
/// the reference design's tab look. Implements PreferredSizeWidget so it
/// drops straight into Scaffold.appBar.bottom.
/// ---------------------------------------------------------------------
class PmPillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> labels;
  final Color accent;
  final bool isScrollable;
  const PmPillTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.accent = PmColors.building,
    this.isScrollable = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: PmTheme.cardSoft,
          borderRadius: BorderRadius.circular(21),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: isScrollable,
          tabAlignment: isScrollable ? TabAlignment.start : null,
          indicator: BoxDecoration(borderRadius: BorderRadius.circular(18), color: accent),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(18),
          labelColor: Colors.white,
          unselectedLabelColor: PmTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          tabs: [for (final l in labels) Tab(text: l)],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Proper flat card with an image slot - a square, photo-style tile
/// (no real photos are stored anywhere in the app yet, so this is a
/// styled illustrated placeholder: a gradient block with a large
/// home/door icon, colored by status/accent) plus title/subtitle/status,
/// used wherever the app lists flats (Building Detail's Flats tab, the
/// tenant "Switch flat" picker) instead of a plain ListTile row.
/// ---------------------------------------------------------------------
class PmFlatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String? statusLabel;
  final VoidCallback? onTap;
  /// true when this card renders inside [pmShowSheet] - that sheet is
  /// ALWAYS white regardless of the PM module's own dark/light toggle
  /// (an app-wide convention, see pmShowSheet's doc comment), so the
  /// card must use fixed light-safe colors here instead of PmTheme,
  /// which would otherwise draw a navy card on a white sheet whenever
  /// the module is in dark mode.
  final bool light;
  const PmFlatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.statusLabel,
    this.onTap,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = light ? Colors.white : PmTheme.card;
    final cardShadowOpacity = light ? 0.06 : (PmTheme.isDark ? 0.16 : 0.05);
    final titleColor = light ? Colors.black87 : PmTheme.textPrimary;
    final subtitleColor = light ? Colors.black54 : PmTheme.textSecondary;
    final chevronColor = light ? Colors.black38 : PmTheme.iconMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(cardShadowOpacity), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Illustrated "image" placeholder - stands in for a real
                // flat photo, which the app has no upload/storage for yet.
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.85), accent.withOpacity(0.45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subtitleColor, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (statusLabel != null) PmStatusBadge(label: statusLabel!, color: accent),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right, color: chevronColor, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------
// Live API data screens (reached from Quick Actions - My Buildings,
// Agreement, Insurance - never shown wholesale on the dashboard itself):
// these reuse the exact data layer that used to back the standalone "My
// Data" screen reached from Profile (my_data_service.dart /
// my_data_models.dart): 5 real endpoints scoped to the owner's stored
// mobile number (Future Property, Under-Construction Flats, Live Flats,
// Agreements, Insurance). See pm_live_list_screens.dart for the actual
// pages; everything below is shared presentation - restyled to match
// this module's own PmTheme instead of the main app's hardcoded
// white/#001234 look.
// ---------------------------------------------------------------------

/// Best-effort classification of a field's semantic kind, purely from
/// its key (e.g. "monthly_rent" -> money, "expiry_date" -> date) - used
/// to pick a sensible icon/color for list cards and detail rows without
/// needing the exact, confirmed field name for every one of these
/// endpoints (see my_data_models.dart's header on why exact names aren't
/// confirmed for all of them yet). A field that matches nothing
/// recognizable still renders - just with a neutral icon/color - so
/// nothing is ever hidden, only de-emphasized.
enum PmFieldKind { money, date, phone, status, location, measurement, count, generic }

class PmFieldClassifier {
  const PmFieldClassifier._();

  static const Map<PmFieldKind, List<String>> _hints = {
    PmFieldKind.money: ['price', 'rent', 'amount', 'fee', 'cost', 'charge', 'premium', 'deposit'],
    PmFieldKind.date: ['date', 'expiry', 'expires', 'since', 'till', 'until', 'start', 'end', 'created', 'updated'],
    PmFieldKind.phone: ['phone', 'mobile', 'contact', 'whatsapp'],
    PmFieldKind.status: ['status', 'stage', 'state', 'progress'],
    PmFieldKind.location: ['address', 'location', 'city', 'place', 'area', 'pincode', 'pin_code', 'sector', 'zone'],
    PmFieldKind.measurement: ['floor', 'bhk', 'room', 'sqft', 'sq_ft', 'size'],
    PmFieldKind.count: ['count', 'total', 'number_of', 'no_of', 'qty', 'quantity', 'units'],
  };

  static PmFieldKind classify(String key) {
    final k = key.toLowerCase();
    for (final entry in _hints.entries) {
      if (entry.value.any((hint) => k.contains(hint))) return entry.key;
    }
    return PmFieldKind.generic;
  }

  static IconData iconFor(PmFieldKind kind) {
    switch (kind) {
      case PmFieldKind.money:
        return Icons.currency_rupee_rounded;
      case PmFieldKind.date:
        return Icons.event_outlined;
      case PmFieldKind.phone:
        return Icons.call_outlined;
      case PmFieldKind.status:
        return Icons.flag_outlined;
      case PmFieldKind.location:
        return Icons.place_outlined;
      case PmFieldKind.measurement:
        return Icons.straighten_outlined;
      case PmFieldKind.count:
        return Icons.tag_outlined;
      case PmFieldKind.generic:
        return Icons.info_outline;
    }
  }

  static Color colorFor(PmFieldKind kind) {
    switch (kind) {
      case PmFieldKind.money:
        return PmColors.rent;
      case PmFieldKind.date:
        return PmColors.tenant;
      case PmFieldKind.phone:
        return PmColors.verification;
      case PmFieldKind.status:
        return PmColors.pending;
      case PmFieldKind.location:
        return PmColors.vehicle;
      case PmFieldKind.measurement:
        return PmColors.document;
      case PmFieldKind.count:
        return PmColors.building;
      case PmFieldKind.generic:
        return Colors.blueGrey;
    }
  }
}

/// Full-width "professional" record card for the live list screens
/// (pm_live_list_screens.dart) - a photo, the record's title/subtitle, a
/// colored status pill when one of its fields looks like a status, and
/// up to 3 more fields shown as small colored icon chips picked by
/// [PmFieldClassifier] - instead of a bare list of every "LABEL: value"
/// pair. Tapping it is entirely up to the caller via [onTap].
class PmSmartRecordCard extends StatelessWidget {
  final DataRecord record;
  final Color accent;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const PmSmartRecordCard({
    super.key,
    required this.record,
    required this.accent,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fields = record.fields;
    MapEntry<String, String>? statusField;
    final chipFields = <MapEntry<String, String>>[];
    for (final field in fields) {
      final kind = PmFieldClassifier.classify(field.key);
      if (kind == PmFieldKind.status && statusField == null) {
        statusField = field;
      } else if (chipFields.length < 3) {
        chipFields.add(field);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PmTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(PmTheme.isDark ? 0.16 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _PmApiRecordImage(
                    candidates: record.resolvedImageUrls,
                    fallbackIcon: fallbackIcon,
                    backgroundTint: accent.withOpacity(0.15),
                    iconColor: accent,
                    height: 64,
                    width: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmTheme.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)),
                          ),
                          if (statusField != null) ...[
                            const SizedBox(width: 6),
                            _statusPill(statusField.value),
                          ],
                        ],
                      ),
                      if (record.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 12, color: PmTheme.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(record.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                      if (chipFields.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final f in chipFields) _fieldChip(f)],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: PmTheme.iconMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String value) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: PmColors.pending.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmColors.pending, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _fieldChip(MapEntry<String, String> field) {
    final kind = PmFieldClassifier.classify(field.key);
    final color = PmFieldClassifier.colorFor(kind);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PmFieldClassifier.iconFor(kind), size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(field.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: PmTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Renders a [DataRecord]'s image by trying each of
/// [DataRecord.resolvedImageUrls] in order - several of these record
/// types have more than one confirmed static base path (the field app
/// never consolidated them into one constant either, see
/// my_data_models.dart), so a 404/load failure on the first candidate
/// falls through to the next one instead of giving up immediately. Once
/// every candidate has failed (or none were confirmed at all), shows a
/// themed icon placeholder rather than a broken-image glyph.
class _PmApiRecordImage extends StatefulWidget {
  final List<String> candidates;
  final IconData fallbackIcon;
  final Color backgroundTint;
  final Color iconColor;
  final double height;
  final double? width;

  const _PmApiRecordImage({
    required this.candidates,
    required this.fallbackIcon,
    required this.backgroundTint,
    required this.iconColor,
    required this.height,
    this.width,
  });

  @override
  State<_PmApiRecordImage> createState() => _PmApiRecordImageState();
}

class _PmApiRecordImageState extends State<_PmApiRecordImage> {
  int _index = 0;

  @override
  void didUpdateWidget(_PmApiRecordImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundTint,
        child: Icon(widget.fallbackIcon, color: widget.iconColor, size: widget.height >= 60 ? 26 : 22),
      );
    }
    return CachedNetworkImage(
      key: ValueKey(widget.candidates[_index]),
      imageUrl: widget.candidates[_index],
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      placeholder: (context, url) => Container(width: widget.width, height: widget.height, color: widget.backgroundTint),
      errorWidget: (context, url, error) {
        // This candidate base path didn't resolve - try the next one (if
        // any) instead of giving up on the first wrong guess.
        Future.microtask(() {
          if (mounted) setState(() => _index++);
        });
        return Container(width: widget.width, height: widget.height, color: widget.backgroundTint);
      },
    );
  }
}

/// Shared gradient "hero" header for one live API record - photo/icon
/// badge, title, subtitle, a LIVE pill, and a back button. Used by
/// [PmApiRecordDetailScreen] (the record IS the whole page) and by
/// PmBuildingFlatsScreen in pm_live_list_screens.dart (the record is
/// just context for the flats listed below it).
class PmApiRecordHeroHeader extends StatelessWidget {
  final DataRecord record;
  final String sectionTitle;
  final IconData icon;
  final Color accent;

  const PmApiRecordHeroHeader({
    super.key,
    required this.record,
    required this.sectionTitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sectionTitle.toUpperCase(),
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _PmApiRecordImage(
                  candidates: record.resolvedImageUrls,
                  fallbackIcon: icon,
                  backgroundTint: Colors.white.withOpacity(0.18),
                  iconColor: Colors.white,
                  height: 64,
                  width: 64,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (record.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.subtitle!,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-page detail view for one live API record (a building, a flat, an
/// agreement, an insurance policy, ...) - the proper Navigator.push
/// destination that replaced the old pmShowSheet-based popup per the
/// "never use plain bottom sheets for this, show it in a proper detail
/// page with attractive theme & UI/UX" direction. Gradient hero header
/// (photo or icon badge, title, subtitle, a LIVE pill marking this as a
/// real synced record) followed by every other field the API returned,
/// laid out as clean, theme-aware detail rows instead of a plain sheet.
class PmApiRecordDetailScreen extends StatelessWidget {
  final DataRecord record;
  final String sectionTitle;
  final IconData icon;
  final Color accent;

  const PmApiRecordDetailScreen({
    super.key,
    required this.record,
    required this.sectionTitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fields = record.fields;
    return Scaffold(
      backgroundColor: PmTheme.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            PmApiRecordHeroHeader(record: record, sectionTitle: sectionTitle, icon: icon, accent: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PmSectionHeader(title: 'Details', icon: Icons.list_alt_outlined, iconColor: accent),
                  const SizedBox(height: 12),
                  if (fields.isEmpty)
                    const PmEmptyState(
                      icon: Icons.info_outline,
                      message: 'No further details were returned for this record.',
                    )
                  else
                    for (final field in fields) _fieldRow(field),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(MapEntry<String, String> field) {
    final kind = PmFieldClassifier.classify(field.key);
    final color = PmFieldClassifier.colorFor(kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PmTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PmTheme.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
              child: Icon(PmFieldClassifier.iconFor(kind), size: 14, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.key.toUpperCase(), style: TextStyle(color: PmTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  if (kind == PmFieldKind.status)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(field.value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                    )
                  else
                    Text(field.value, style: TextStyle(color: PmTheme.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
