import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    CalendarScreen(),
    ExploreScreen(), // ⭐ 활성화됨
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _MinimalNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
///  Minimal Bottom Navigation — Aesop/Hermès 영감
/// ═══════════════════════════════════════════════════════════
class _MinimalNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MinimalNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: '홈',
    ),
    _NavItemData(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: '캘린더',
    ),
    _NavItemData(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: '탐색',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '내 정보',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (i) {
              return _NavTab(
                data: _items[i],
                isActive: currentIndex == i,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavTab extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 상단 점 인디케이터
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 0,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: const BoxDecoration(
                  color: AppColors.wine,
                  shape: BoxShape.circle,
                ),
              ),

              // ── 아이콘
              Icon(
                isActive ? data.activeIcon : data.icon,
                size: 21,
                color: isActive ? AppColors.wine : AppColors.textTertiary,
              ),

              const SizedBox(height: 4),

              // ── 라벨
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.wine : AppColors.textTertiary,
                  letterSpacing: 0.2,
                ),
                child: Text(data.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}