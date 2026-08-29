import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_colors.dart';

/// Data model for an item in the [LottieBottomNavBar].
class LottieBottomNavBarItem {
  final String label;
  final String lottieAsset;
  final IconData fallbackIcon;
  final IconData selectedFallbackIcon;
  final int badgeCount;
  final bool isCenter;

  const LottieBottomNavBarItem({
    required this.label,
    required this.lottieAsset,
    required this.fallbackIcon,
    required this.selectedFallbackIcon,
    this.badgeCount = 0,
    this.isCenter = false,
  });
}

/// A custom, high-impact Neo-Brutalist bottom navigation bar powered by Lottie animations.
class LottieBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final int unreadCount;

  const LottieBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    final List<LottieBottomNavBarItem> items = [
      const LottieBottomNavBarItem(
        label: 'Home',
        lottieAsset: 'assets/lottie/nav_home.json',
        fallbackIcon: Icons.home_outlined,
        selectedFallbackIcon: Icons.home_rounded,
      ),
      const LottieBottomNavBarItem(
        label: 'Requests',
        lottieAsset: 'assets/lottie/nav_requests.json',
        fallbackIcon: Icons.receipt_long_outlined,
        selectedFallbackIcon: Icons.receipt_long_rounded,
      ),
      const LottieBottomNavBarItem(
        label: 'New',
        lottieAsset: 'assets/lottie/nav_new.json',
        fallbackIcon: Icons.add_circle_outline_rounded,
        selectedFallbackIcon: Icons.add_circle_rounded,
        isCenter: true,
      ),
      LottieBottomNavBarItem(
        label: 'Alerts',
        lottieAsset: 'assets/lottie/nav_alerts.json',
        fallbackIcon: Icons.notifications_outlined,
        selectedFallbackIcon: Icons.notifications_rounded,
        badgeCount: unreadCount,
      ),
      const LottieBottomNavBarItem(
        label: 'Profile',
        lottieAsset: 'assets/lottie/nav_profile.json',
        fallbackIcon: Icons.person_outline_rounded,
        selectedFallbackIcon: Icons.person_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.neoBorder,
            offset: const Offset(0, -4),
            blurRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 2.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: _LottieNavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => onItemTapped(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _LottieNavItemWidget extends StatefulWidget {
  final LottieBottomNavBarItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LottieNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_LottieNavItemWidget> createState() => _LottieNavItemWidgetState();
}

class _LottieNavItemWidgetState extends State<_LottieNavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLottieLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _LottieNavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    if (_isLottieLoaded) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark ? Colors.white : AppColors.neoBorder;
    final activeTextColor = widget.isDark ? AppColors.neoYellow : AppColors.neoBorder;
    final inactiveTextColor = widget.isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF64748B);

    if (widget.item.isCenter) {
      return GestureDetector(
        onTap: () {
          _playAnimation();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.isSelected ? AppColors.neoYellow : AppColors.neoPink,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: widget.isSelected ? const Offset(1, 1) : const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Lottie.asset(
                  widget.item.lottieAsset,
                  controller: _controller,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    setState(() {
                      _isLottieLoaded = true;
                    });
                    if (widget.isSelected) {
                      _playAnimation();
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      widget.isSelected
                          ? widget.item.selectedFallbackIcon
                          : widget.item.fallbackIcon,
                      color: AppColors.neoBorder,
                      size: 22,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.item.label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: widget.isSelected ? activeTextColor : inactiveTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        _playAnimation();
        widget.onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? (widget.isDark ? AppColors.neoYellow.withValues(alpha: 0.25) : AppColors.neoYellow)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isSelected
                  ? Border.all(color: borderColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: borderColor,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Lottie.asset(
                    widget.item.lottieAsset,
                    controller: _controller,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                      setState(() {
                        _isLottieLoaded = true;
                      });
                      if (widget.isSelected) {
                        _playAnimation();
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        widget.isSelected
                            ? widget.item.selectedFallbackIcon
                            : widget.item.fallbackIcon,
                        color: widget.isSelected ? activeTextColor : inactiveTextColor,
                        size: 24,
                      );
                    },
                  ),
                ),
                if (widget.item.badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejected,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 9,
                        minHeight: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w700,
              color: widget.isSelected ? activeTextColor : inactiveTextColor,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.item.label),
            ),
          ),
        ],
      ),
    );
  }
}
