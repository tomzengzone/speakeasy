import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:speakeasy/models/app_models.dart';

abstract class ContentRepository {
  Future<List<ExpressionCardData>> loadExpressionCards();
}

class AssetContentRepository implements ContentRepository {
  const AssetContentRepository();

  @override
  Future<List<ExpressionCardData>> loadExpressionCards() async {
    final String raw = await rootBundle.loadString(
      'assets/data/expression_cards.json',
    );
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (dynamic e) => ExpressionCardData.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}

class ContentRepositoryScope extends InheritedWidget {
  const ContentRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final ContentRepository repository;

  static ContentRepository of(BuildContext context) {
    final ContentRepositoryScope? scope = context
        .dependOnInheritedWidgetOfExactType<ContentRepositoryScope>();
    assert(scope != null, 'ContentRepositoryScope not found in context');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(ContentRepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
