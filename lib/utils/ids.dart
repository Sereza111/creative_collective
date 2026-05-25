/// API возвращает UUID строками — не парсим в int.
String idFromJson(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
