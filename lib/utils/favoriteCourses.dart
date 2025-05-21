import 'package:flutter/material.dart';

final favoriteCourses = ValueNotifier<List<String>>([]);

/// Clears the favorite courses list
void clearFavorites() {
  favoriteCourses.value = [];
}