import 'package:flutter/material.dart';

import 'package:speakeasy/core/routing/app_routes.dart';
import 'package:speakeasy/pages/achievements_page.dart';
import 'package:speakeasy/pages/edit_profile_page.dart';
import 'package:speakeasy/pages/favorites_page.dart';
import 'package:speakeasy/features/interview/interview_practice_page.dart';
import 'package:speakeasy/pages/learning_report_page.dart';
import 'package:speakeasy/pages/offline_content_page.dart';
import 'package:speakeasy/pages/privacy_policy_page.dart';
import 'package:speakeasy/pages/terms_of_service_page.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = _builderFor(settings.name);
    if (builder == null) {
      return null;
    }
    return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
  }

  static WidgetBuilder? _builderFor(String? routeName) {
    return switch (routeName) {
      AppRoutes.privacyPolicy =>
        (BuildContext context) => const PrivacyPolicyPage(),
      AppRoutes.termsOfService =>
        (BuildContext context) => const TermsOfServicePage(),
      AppRoutes.editProfile =>
        (BuildContext context) => const EditProfilePage(),
      AppRoutes.learningReport =>
        (BuildContext context) => const LearningReportPage(),
      AppRoutes.favorites => (BuildContext context) => const FavoritesPage(),
      AppRoutes.offlineContent =>
        (BuildContext context) => const OfflineContentPage(),
      AppRoutes.achievements =>
        (BuildContext context) => const AchievementsPage(),
      AppRoutes.interviewPractice =>
        (BuildContext context) => const InterviewPracticePage(),
      _ => null,
    };
  }
}
