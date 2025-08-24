import 'package:flutter/material.dart';

/// Enumeration of application categories for household management.
///
/// Provides a comprehensive set of categories that cover the broad spectrum
/// of applications users might request for household management. Each category
/// is associated with an appropriate Material Design icon for consistent
/// visual representation throughout the application.
///
/// Categories are organized by common household needs and activities,
/// ensuring that any reasonable user request can be properly categorized.
enum ApplicationCategory {
  /// Home management applications including maintenance, cleaning, and organization.
  ///
  /// Examples: Chore trackers, maintenance schedules, inventory management,
  /// cleaning routines, home automation controls.
  homeManagement,

  /// Financial applications for budgeting, expense tracking, and money management.
  ///
  /// Examples: Budget trackers, expense managers, bill reminders, savings goals,
  /// investment trackers, family allowance systems.
  finance,

  /// Planning and scheduling applications for family coordination.
  ///
  /// Examples: Family calendars, event planners, meal planning, vacation planning,
  /// appointment schedulers, task coordinators.
  planning,

  /// Health and fitness applications for family wellness.
  ///
  /// Examples: Fitness trackers, meal planners, medical record keepers,
  /// exercise routines, health goal trackers, medication reminders.
  healthAndFitness,

  /// Educational applications for learning and skill development.
  ///
  /// Examples: Study schedulers, homework trackers, skill learning apps,
  /// reading lists, educational games, progress trackers.
  education,

  /// Entertainment applications for family fun and leisure.
  ///
  /// Examples: Game organizers, movie lists, book clubs, hobby trackers,
  /// family activity planners, media libraries.
  entertainment,

  /// Utility applications for everyday household tools.
  ///
  /// Examples: Calculators, converters, timers, weather trackers,
  /// shopping lists, quick reference tools, measurement tools.
  utilities,

  /// Communication applications for family coordination and contact management.
  ///
  /// Examples: Family message boards, contact organizers, emergency contacts,
  /// family newsletters, announcement systems, group chat organizers.
  communication,

  /// Security applications for home and family safety.
  ///
  /// Examples: Security system monitors, emergency preparedness, safety checklists,
  /// password managers, backup systems, privacy tools.
  security,

  /// Shopping applications for purchasing and inventory management.
  ///
  /// Examples: Shopping lists, price comparisons, coupon organizers,
  /// grocery planners, purchase trackers, wishlist managers.
  shopping,

  /// Transportation applications for family travel and vehicle management.
  ///
  /// Examples: Trip planners, vehicle maintenance trackers, fuel logs,
  /// carpool organizers, public transit helpers, travel itineraries.
  transportation,

  /// Pet care applications for managing family pets.
  ///
  /// Examples: Pet care schedules, veterinary records, feeding trackers,
  /// exercise logs, grooming reminders, pet health monitors.
  petCare,

  /// Garden and outdoor applications for yard and garden management.
  ///
  /// Examples: Garden planners, plant care schedules, weather trackers,
  /// harvest logs, outdoor project managers, landscaping tools.
  gardenAndOutdoor,

  /// Recipe and cooking applications for meal preparation and kitchen management.
  ///
  /// Examples: Recipe organizers, meal planners, cooking timers,
  /// ingredient trackers, nutrition calculators, kitchen inventory.
  recipesAndCooking,

  /// Work and productivity applications for home office and career management.
  ///
  /// Examples: Home office organizers, productivity trackers, goal setters,
  /// time managers, project planners, skill development trackers.
  workAndProductivity,

  /// Other applications that don't fit into predefined categories.
  ///
  /// Serves as a catch-all for unique or specialized applications that
  /// don't clearly belong in any other category. Should be used sparingly.
  other;

  /// Returns the display label for this category.
  ///
  /// Provides human-readable category names suitable for display in the UI.
  /// Labels are consistent with existing sidebar category constants.
  String get displayName {
    switch (this) {
      case ApplicationCategory.homeManagement:
        return 'Home Management';
      case ApplicationCategory.finance:
        return 'Finance';
      case ApplicationCategory.planning:
        return 'Planning';
      case ApplicationCategory.healthAndFitness:
        return 'Health & Fitness';
      case ApplicationCategory.education:
        return 'Education';
      case ApplicationCategory.entertainment:
        return 'Entertainment';
      case ApplicationCategory.utilities:
        return 'Utilities';
      case ApplicationCategory.communication:
        return 'Communication';
      case ApplicationCategory.security:
        return 'Security';
      case ApplicationCategory.shopping:
        return 'Shopping';
      case ApplicationCategory.transportation:
        return 'Transportation';
      case ApplicationCategory.petCare:
        return 'Pet Care';
      case ApplicationCategory.gardenAndOutdoor:
        return 'Garden & Outdoor';
      case ApplicationCategory.recipesAndCooking:
        return 'Recipes & Cooking';
      case ApplicationCategory.workAndProductivity:
        return 'Work & Productivity';
      case ApplicationCategory.other:
        return 'Other';
    }
  }

  /// Returns the Material Design icon associated with this category.
  ///
  /// Provides consistent visual representation for each category throughout
  /// the application. Icons are chosen to be immediately recognizable and
  /// clearly represent the category's purpose.
  IconData get icon {
    switch (this) {
      case ApplicationCategory.homeManagement:
        return Icons.home;
      case ApplicationCategory.finance:
        return Icons.calculate;
      case ApplicationCategory.planning:
        return Icons.calendar_today;
      case ApplicationCategory.healthAndFitness:
        return Icons.fitness_center;
      case ApplicationCategory.education:
        return Icons.school;
      case ApplicationCategory.entertainment:
        return Icons.movie;
      case ApplicationCategory.utilities:
        return Icons.build;
      case ApplicationCategory.communication:
        return Icons.chat;
      case ApplicationCategory.security:
        return Icons.security;
      case ApplicationCategory.shopping:
        return Icons.shopping_cart;
      case ApplicationCategory.transportation:
        return Icons.directions_car;
      case ApplicationCategory.petCare:
        return Icons.pets;
      case ApplicationCategory.gardenAndOutdoor:
        return Icons.local_florist;
      case ApplicationCategory.recipesAndCooking:
        return Icons.restaurant;
      case ApplicationCategory.workAndProductivity:
        return Icons.work;
      case ApplicationCategory.other:
        return Icons.folder;
    }
  }

  /// Parses a string value into an ApplicationCategory enum.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid category values. Supports both enum names and display names.
  ///
  /// @param value The string value to parse
  /// @returns The corresponding ApplicationCategory enum value
  /// @throws ArgumentError if the value doesn't match any category
  static ApplicationCategory fromString(String value) {
    final String normalizedValue = value.toLowerCase().replaceAll(' ', '').replaceAll('&', '');

    switch (normalizedValue) {
      case 'homemanagement':
        return ApplicationCategory.homeManagement;
      case 'finance':
        return ApplicationCategory.finance;
      case 'planning':
        return ApplicationCategory.planning;
      case 'healthfitness':
      case 'healthandfitness':
        return ApplicationCategory.healthAndFitness;
      case 'education':
        return ApplicationCategory.education;
      case 'entertainment':
        return ApplicationCategory.entertainment;
      case 'utilities':
        return ApplicationCategory.utilities;
      case 'communication':
        return ApplicationCategory.communication;
      case 'security':
        return ApplicationCategory.security;
      case 'shopping':
        return ApplicationCategory.shopping;
      case 'transportation':
        return ApplicationCategory.transportation;
      case 'petcare':
        return ApplicationCategory.petCare;
      case 'gardenoutdoor':
      case 'gardenandoutdoor':
        return ApplicationCategory.gardenAndOutdoor;
      case 'recipescooking':
      case 'recipesandcooking':
        return ApplicationCategory.recipesAndCooking;
      case 'workproductivity':
      case 'workandproductivity':
        return ApplicationCategory.workAndProductivity;
      case 'other':
        return ApplicationCategory.other;
      default:
        throw ArgumentError('Invalid application category: $value');
    }
  }

  /// Returns all available category display names as a list.
  ///
  /// Useful for validation, dropdown lists, or other scenarios where
  /// all category names are needed.
  static List<String> get allDisplayNames {
    return ApplicationCategory.values.map((category) => category.displayName).toList();
  }

  /// Returns all available category enum names as a list.
  ///
  /// Useful for JSON serialization or API communication where
  /// enum names are preferred over display names.
  static List<String> get allEnumNames {
    return ApplicationCategory.values.map((category) => category.name).toList();
  }
}
