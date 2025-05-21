import 'package:flutter_test/flutter_test.dart';
import 'package:su_credit/utils/favoriteCourses.dart';

void main() {
  group('FavoriteCourses', () {
    test('should clear favorites', () {
      // Set up some favorites
      favoriteCourses.value = ['CS101', 'CS102'];
      
      // Call the clear function
      clearFavorites();
      
      // Check that favorites are cleared
      expect(favoriteCourses.value, isEmpty);
    });
    
    test('should add and remove favorites correctly', () {
      // Start with empty favorites
      clearFavorites();
      
      // Add favorites
      favoriteCourses.value = [...favoriteCourses.value, 'CS201'];
      expect(favoriteCourses.value, contains('CS201'));
      
      // Add another favorite
      favoriteCourses.value = [...favoriteCourses.value, 'CS202'];
      expect(favoriteCourses.value.length, 2);
      expect(favoriteCourses.value, containsAll(['CS201', 'CS202']));
      
      // Remove a favorite
      favoriteCourses.value = favoriteCourses.value.where((course) => course != 'CS201').toList();
      expect(favoriteCourses.value.length, 1);
      expect(favoriteCourses.value, contains('CS202'));
      expect(favoriteCourses.value, isNot(contains('CS201')));
    });
  });
}
