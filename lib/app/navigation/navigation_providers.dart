import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the scan tab inside the home navigation shell.
const int scanTabIndex = 0;

/// Holds the index of the currently visible tab in the home navigation shell.
final currentHomeTabProvider = StateProvider<int>((ref) => scanTabIndex);