import 'package:flutter/material.dart';

enum MioDestination {
  home(label: '首页', icon: Icons.home_outlined),
  discover(label: '发现', icon: Icons.travel_explore_outlined),
  schedule(label: '日程', icon: Icons.calendar_month_outlined),
  library(label: '追番', icon: Icons.bookmark_outline);

  const MioDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
