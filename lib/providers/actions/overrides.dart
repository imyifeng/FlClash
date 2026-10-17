part of '../action.dart';

@Riverpod(keepAlive: true)
class OverridesAction extends _$OverridesAction {
  @override
  void build() {}

  void putOverride(OverrideItem override) {
    ref.read(overridesProvider.notifier).put(override);
    _applyIfAffected(override);
  }

  Future<void> updateOverride(OverrideItem override) async {
    final updatingKeys = ref.read(updatingKeysProvider.notifier);
    final operation = updatingKeys.start(override.updatingKey);
    try {
      putOverride(await override.update());
    } finally {
      updatingKeys.stop(override.updatingKey, operation);
    }
  }

  Future<void> removeOverride(OverrideItem override) async {
    ref.read(overridesProvider.notifier).del(override.id);
    final path = await override.path;
    await File(path).safeDelete();
    _applyIfAffected(override);
  }

  void _applyIfAffected(OverrideItem override) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null || profile.type == ProfileType.custom) {
      return;
    }
    if (override.global || profile.overrideIds.contains(override.id)) {
      ref
          .read(setupActionProvider.notifier)
          .applyProfileDebounce(silence: true);
    }
  }
}
