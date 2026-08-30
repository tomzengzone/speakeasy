import '../generated/api/speakeasy_api.dart';

const String defaultCefrLevel = 'A2';

final Set<String> cefrLevels = Set<String>.unmodifiable(
  LevelCode.values.map((LevelCode level) => level.wireValue),
);

bool isCefrLevel(Object? value) => LevelCode.tryParse(value) != null;

String requireCefrLevel(Object? value, {String fieldName = 'level'}) {
  if (isCefrLevel(value)) {
    return value as String;
  }
  throw FormatException(
    '$fieldName must be one of ${cefrLevels.join(', ')}; received $value',
  );
}

String cefrLevelLabel(Object? value, {String fieldName = 'level'}) {
  return switch (requireCefrLevel(value, fieldName: fieldName)) {
    'A2' => 'A2 基础',
    'B1' => 'B1 中级',
    'B2' => 'B2 中高级',
    final String level => level,
  };
}
