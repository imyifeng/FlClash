import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverridesView extends ConsumerStatefulWidget {
  const OverridesView({super.key});

  @override
  ConsumerState<OverridesView> createState() => _OverridesViewState();
}

class _OverridesViewState extends ConsumerState<OverridesView> {
  late final OverridesAction _overridesAction;

  @override
  void initState() {
    super.initState();
    _overridesAction = ref.read(overridesActionProvider.notifier);
  }

  Future<void> _handleDelete(OverrideItem override) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.override),
      ),
      destructive: true,
      confirmText: appLocalizations.delete,
    );
    if (res != true || !mounted) {
      return;
    }
    await _overridesAction.removeOverride(override);
  }

  Widget _buildContent(
    List<OverrideItem> overrides, {
    required bool isLoading,
  }) {
    final appLocalizations = context.appLocalizations;
    return NullStatusSwitcher(
      isLoading: isLoading,
      isEmpty: overrides.isEmpty,
      nullStatus: NullStatus(
        illustration: NullStatusIllustration.scripts,
        label: appLocalizations.nullTip(appLocalizations.override),
      ),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(
          16,
        ).copyWith(top: context.contentTopPadding),
        buildDefaultDragHandles: false,
        itemCount: overrides.length,
        itemBuilder: (_, index) => _buildItem(overrides, index),
        proxyDecorator: (_, index, animation) {
          return commonProxyDecorator(
            _buildItem(overrides, index),
            index,
            animation,
          );
        },
        onReorderItem: ref.read(overridesProvider.notifier).order,
      ),
    );
  }

  List<CommonPopupMenuItem> _buildMenuItems(OverrideItem override) {
    final appLocalizations = context.appLocalizations;
    return [
      CommonPopupMenuItem(
        glyph: AppGlyphs.edit,
        label: appLocalizations.edit,
        onPressed: () {
          _handleToEditor(override);
        },
      ),
      if (override.url != null) ...[
        CommonPopupMenuItem(
          glyph: AppGlyphs.link,
          label: appLocalizations.url,
          onPressed: () {
            _handleEditUrl(override);
          },
        ),
        CommonPopupMenuItem(
          glyph: AppGlyphs.sync,
          label: appLocalizations.sync,
          onPressed: () {
            _handleUpdate(override);
          },
        ),
      ],
      CommonPopupMenuItem(
        glyph: AppGlyphs.pin,
        checked: override.global,
        label: appLocalizations.global,
        onPressed: () {
          _overridesAction.putOverride(
            override.copyWith(global: !override.global),
          );
        },
      ),
      CommonPopupMenuItem(
        danger: true,
        glyph: AppGlyphs.delete,
        label: appLocalizations.delete,
        onPressed: () {
          _handleDelete(override);
        },
      ),
    ];
  }

  String _buildSubtitle(OverrideItem override) {
    final appLocalizations = context.appLocalizations;
    return [
      override.ext == OverrideType.javascript ? 'JavaScript' : 'YAML',
      override.url != null ? appLocalizations.remote : appLocalizations.local,
      if (override.global) appLocalizations.global,
    ].join(' · ');
  }

  Widget _buildItem(List<OverrideItem> overrides, int index) {
    final override = overrides[index];
    return SortableItem(
      key: ValueKey(override.id),
      index: index,
      child: Consumer(
        builder: (_, ref, child) => ContextMenuRegion(
          menuItems: ref.watch(isUpdatingProvider(override.updatingKey))
              ? null
              : _buildMenuItems(override),
          child: child!,
        ),
        child: ItemPositionProvider(
          position: ItemPosition.get(index, overrides.length),
          child: DecorationListItem(
            contentPadding: const EdgeInsets.only(left: 16),
            title: Text(
              override.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_buildSubtitle(override)),
            trailing: _OverrideTrailing(item: override),
            onPressed: () {
              _handleToEditor(override);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditUrl(OverrideItem override) async {
    final url = await dialogs.showUrlInput(
      title: context.appLocalizations.url,
      value: override.url ?? '',
    );
    if (url == null || url == override.url) {
      return;
    }
    await _handleUpdate(override.copyWith(url: url));
  }

  Future<void> _handleUpdate(OverrideItem override) async {
    await globalState.safeRun(
      () => _overridesAction.updateOverride(override),
      title: override.label,
    );
  }

  List<OverrideItem> get _overrides => ref.read(overridesProvider).value ?? [];

  String? _validateName(String? value, {OverrideItem? override}) {
    final appLocalizations = context.appLocalizations;
    final label = value?.trim() ?? '';
    if (label.isEmpty) {
      return appLocalizations.emptyTip(appLocalizations.name);
    }
    if (_overrides.hasLabel(label, except: override)) {
      return appLocalizations.existsTip(appLocalizations.name);
    }
    return null;
  }

  Future<String?> _showNameDialog({OverrideItem? override}) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showCommonDialog<String>(
      child: InputDialog(
        title: appLocalizations.save,
        value: '',
        hintText: appLocalizations.pleaseEnterOverrideName,
        inputFormatters: TextInputLimits.limit(TextInputLimits.name),
        validator: (value) => _validateName(value, override: override),
      ),
    );
    return res?.trim().value;
  }

  Future<void> _handleEditorSave(
    BuildContext _,
    String title,
    String content, {
    OverrideItem? override,
  }) async {
    final appLocalizations = context.appLocalizations;
    var label = title.trim();
    if (label.isEmpty) {
      final res = await _showNameDialog(override: override);
      if (res == null) {
        return;
      }
      label = res;
    }
    if (_overrides.hasLabel(label, except: override)) {
      unawaited(
        dialogs.showMessage(
          message: TextSpan(
            text: appLocalizations.existsTip(appLocalizations.name),
          ),
        ),
      );
      return;
    }
    final newOverride =
        await (override?.copyWith(label: label) ??
                OverrideItem.create(
                  label: label,
                  ext: _ext ?? OverrideType.yaml,
                ))
            .save(content);
    _overridesAction.putOverride(newOverride);
    _ext = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _handleEditorPop(
    BuildContext _,
    String title,
    String content,
    String raw, {
    OverrideItem? override,
  }) async {
    final appLocalizations = context.appLocalizations;
    if (content == raw && title == (override?.label ?? '')) {
      return true;
    }
    final res = await dialogs.showMessage(
      message: TextSpan(text: appLocalizations.saveChanges),
    );
    if (res == null) {
      return false;
    }
    if (res && mounted) {
      unawaited(_handleEditorSave(context, title, content, override: override));
    } else {
      return true;
    }
    return false;
  }

  /// The type of an override that only exists once the editor saves.
  OverrideType? _ext;

  void _handleToEditor([OverrideItem? override]) {
    final ext = override?.ext ?? _ext;
    final isJavaScript = ext == OverrideType.javascript;
    late final String raw;
    unawaited(
      BaseNavigator.push(
        context,
        EditorPage(
          titleEditable: true,
          title: override?.label ?? '',
          onSave: (context, title, content) =>
              _handleEditorSave(context, title, content, override: override),
          onPop: (context, title, content) {
            return _handleEditorPop(
              context,
              title,
              content,
              raw,
              override: override,
            );
          },
          language: isJavaScript ? Language.javaScript : Language.yaml,
          schema: EditorSchema.config,
          load: () async =>
              raw = (await override?.content) ?? _templateOf(isJavaScript),
        ),
      ),
    );
  }

  String _templateOf(bool isJavaScript) =>
      isJavaScript ? scriptTemplate : overrideYamlTemplate;

  Future<void> _handleImport(
    String content, {
    String? url,
    required String fileName,
  }) async {
    final label = _overrides.uniqueLabel(
      fileName.fileStem,
      fallback: context.appLocalizations.override,
    );
    final ext = fileName.endsWith('.js')
        ? OverrideType.javascript
        : OverrideType.yaml;
    final override = await OverrideItem.create(
      label: label,
      ext: ext,
      url: url,
    ).save(content);
    _overridesAction.putOverride(override);
  }

  Future<void> _handleImportFromUrl() async {
    final appLocalizations = context.appLocalizations;
    final url = await dialogs.showUrlInput(title: appLocalizations.importUrl);
    if (url == null) {
      return;
    }
    final res = await globalState.loadingRun(
      () => request.getTextResponseForUrl(url),
      title: appLocalizations.importUrl,
      tag: LoadingTag.overrides,
    );
    if (res == null || !mounted) {
      return;
    }
    final fileName =
        Uri.tryParse(
          url,
        )?.pathSegments.lastWhereOrNull((it) => it.isNotEmpty) ??
        '';
    await _handleImport(res.data ?? '', url: url, fileName: fileName);
  }

  Future<void> _handleImportFromFile() async {
    final file = await globalState.safeRun(picker.pickerFile);
    if (file == null) {
      return;
    }
    final content = await globalState.safeRun(
      () async => utf8.decode(await file.readBytes()),
    );
    if (content == null || !mounted) {
      return;
    }
    await _handleImport(content, fileName: file.name);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final overridesState = ref.watch(overridesProvider);
    final overrides = overridesState.value ?? [];
    final isLoading = ref.watch(loadingProvider(LoadingTag.overrides));
    return CommonScaffold(
      canSort: overrides.length > 1,
      isLoading: isLoading,
      actions: [
        CommonPopupBox(
          targetBuilder: (open) {
            return IconButton(
              tooltip: appLocalizations.add,
              onPressed: open,
              icon: const GlyphIcon(AppGlyphs.addCircle),
            );
          },
          popupBuilder: (_) => CommonPopupMenu(
            items: [
              CommonPopupMenuItem(
                glyph: AppGlyphs.compose,
                label: appLocalizations.newYamlOverride,
                onPressed: () {
                  _ext = OverrideType.yaml;
                  _handleToEditor();
                },
              ),
              CommonPopupMenuItem(
                glyph: AppGlyphs.code,
                label: appLocalizations.newJavaScriptOverride,
                onPressed: () {
                  _ext = OverrideType.javascript;
                  _handleToEditor();
                },
              ),
              CommonPopupMenuItem(
                glyph: AppGlyphs.cloudDownload,
                label: appLocalizations.importUrl,
                onPressed: _handleImportFromUrl,
              ),
              CommonPopupMenuItem(
                glyph: AppGlyphs.importFile,
                label: appLocalizations.importFile,
                onPressed: _handleImportFromFile,
              ),
            ],
          ),
        ),
      ],
      body: _buildContent(overrides, isLoading: overridesState.isLoading),
      title: appLocalizations.override,
    );
  }
}

class _OverrideTrailing extends ConsumerWidget {
  const _OverrideTrailing({required this.item});

  final OverrideItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(isUpdatingProvider(item.updatingKey));
    // Inset here, not in the row, so the sort handle that replaces it sits flush.
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: AnimatedSwitcher(
        duration: context.motionDuration(commonDuration),
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.centerEnd,
          children: [...previous, ?current],
        ),
        child: isUpdating
            ? const CommonCircleLoading(key: ValueKey('loading'), size: 24)
            : LastUpdateTimeText(
                key: const ValueKey('time'),
                lastUpdateDate: item.lastUpdateTime,
                compact: true,
                style: context.listCaptionStyle,
              ),
      ),
    );
  }
}
