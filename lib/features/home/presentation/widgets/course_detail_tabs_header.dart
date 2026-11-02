import 'package:flutter/material.dart';

/// Capture geometry at construction: ScreenUtil may change during rotation.
class CourseDetailTabsHeader extends SliverPersistentHeaderDelegate {
  CourseDetailTabsHeader(this.tabBar)
    : extent = tabBar.preferredSize.height.ceilToDouble();

  final TabBar tabBar;
  final double extent;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(
    child: ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    ),
  );

  @override
  bool shouldRebuild(CourseDetailTabsHeader oldDelegate) =>
      extent != oldDelegate.extent || tabBar != oldDelegate.tabBar;
}
