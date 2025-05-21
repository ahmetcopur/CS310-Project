// This file contains utility functions to determine course types for different majors
// based on university curriculum requirements.

import 'package:su_credit/models/course.dart';

/// Determines whether a course is a core, area, or free elective for a specific major
String getCourseTypeForMajor(Course course, String major) {
  // Convert to lowercase for case-insensitive comparison
  final String majorLower = major.toLowerCase();
  final List<String> reqLower = course.requirements.map((r) => r.toLowerCase()).toList();

  // Check if course is specifically marked for this major
  if (major.isNotEmpty) {
    // Core courses - required for the specific major
    if (reqLower.contains(majorLower) || 
        reqLower.contains('${majorLower}_core') ||
        reqLower.any((r) => r.startsWith('${majorLower}_required'))) {
      return 'core';
    }
    
    // Area courses - electives within the major's field
    if (reqLower.contains('area') || 
        reqLower.contains('${majorLower}_area') ||
        reqLower.any((r) => r.contains('${majorLower}_elective'))) {
      return 'area';
    }
  }
  
  // Free electives - courses from any department
  if (reqLower.contains('free') || 
      reqLower.contains('free_elective') ||
      reqLower.contains('general_education')) {
    return 'free';
  }
  
  // If no specific requirement matches, use additional logic for common cases
  
  // CS Major specific logic
  if (majorLower == 'cs') {
    if (course.code.startsWith('CS') || course.code.startsWith('MATH')) {
      return 'core';
    }
    if (course.code.startsWith('IE') || course.code.startsWith('EE')) {
      return 'area';
    }
  }
  
  // IE Major specific logic
  else if (majorLower == 'ie') {
    if (course.code.startsWith('IE') || course.code.startsWith('MATH')) {
      return 'core';
    }
    if (course.code.startsWith('CS') || course.code.startsWith('OPER')) {
      return 'area';
    }
  }
  
  // PSY Major specific logic
  else if (majorLower == 'psy') {
    if (course.code.startsWith('PSY')) {
      return 'core';
    }
    if (course.code.startsWith('SOC') || course.code.startsWith('PHIL')) {
      return 'area';
    }
  }
  
  // Default: consider as free elective if can't determine otherwise
  return 'free';
}

/// Returns the required credits for graduation based on major
Map<String, int> getGraduationRequirements(String major) {
  switch (major.toUpperCase()) {
    case 'CS':
      return {
        'total': 49,
        'core': 31,
        'area': 9,
        'free': 9,
      };
    case 'IE':
      return {
        'total': 49,
        'core': 34,
        'area': 9,
        'free': 6,
      };
    case 'PSY':
      return {
        'total': 49,
        'core': 28,
        'area': 12,
        'free': 9,
      };
    default:
      // Default requirements
      return {
        'total': 49,
        'core': 31,
        'area': 9,
        'free': 9,
      };
  }
}
