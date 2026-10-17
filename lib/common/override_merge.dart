import 'package:fl_clash/common/exception.dart';

import 'yaml.dart';

/// Applies a Clash Party style YAML override document onto a profile config.
///
/// A key is read left to right: a leading `+` prepends the value to the target
/// list, a trailing `+` appends it, a trailing `!` replaces the target without
/// merging, and a body wrapped in `<>` is the literal key of a name that would
/// otherwise read as an operator. A plain key deep-merges maps and replaces
/// every other value, arrays included.
enum _OverrideOp { merge, replace, prepend, append }

Map<String, dynamic> applyOverrideYaml(
  Map<String, dynamic> config,
  String content,
) {
  final parsed = loadPlainYaml(content);
  if (parsed == null) {
    return config;
  }
  if (parsed is! Map<String, dynamic>) {
    throw const MessageException('override must be a mapping');
  }
  return _mergeMap(config, parsed);
}

Map<String, dynamic> _mergeMap(
  Map<String, dynamic> base,
  Map<String, dynamic> patch,
) {
  final next = Map<String, dynamic>.of(base);
  for (final MapEntry(:key, :value) in patch.entries) {
    final (op, name) = _parseKey(key);
    if (name.isEmpty) {
      continue;
    }
    switch (op) {
      case _OverrideOp.merge:
        final current = next[name];
        next[name] = current is Map<String, dynamic> && value is Map
            ? _mergeMap(current, Map<String, dynamic>.from(value))
            : value;
      case _OverrideOp.replace:
        next[name] = value;
      case _OverrideOp.prepend || _OverrideOp.append:
        final items = value is List
            ? List<Object?>.from(value)
            : <Object?>[value];
        final current = next[name];
        next[name] = current is List
            ? op == _OverrideOp.prepend
                  ? [...items, ...current]
                  : [...current, ...items]
            : items;
    }
  }
  return next;
}

(_OverrideOp, String) _parseKey(String key) {
  var op = _OverrideOp.merge;
  var name = key;
  if (name.startsWith('+') && name.length > 1) {
    op = _OverrideOp.prepend;
    name = name.substring(1);
  } else if (name.endsWith('+') && name.length > 1) {
    op = _OverrideOp.append;
    name = name.substring(0, name.length - 1);
  }
  if (name.endsWith('!') && name.length > 1) {
    if (op == _OverrideOp.merge) {
      op = _OverrideOp.replace;
    }
    name = name.substring(0, name.length - 1);
  }
  if (name.startsWith('<') && name.endsWith('>') && name.length > 2) {
    name = name.substring(1, name.length - 1);
  }
  return (op, name);
}
