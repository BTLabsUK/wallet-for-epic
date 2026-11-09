// SPDX-License-Identifier: Apache-2.0
/// Linux's tray: a StatusNotifierItem with its menu over com.canonical.dbusmenu, on the session
/// bus, through the dbus package the app already has. KDE, Xfce, Cinnamon, MATE, LXQt and GNOME
/// with the AppIndicator extension show it; a desktop without a StatusNotifierWatcher (GNOME as
/// shipped) has no tray, and the window's close quits as before.
library;

import 'dart:async';
import 'dart:io' show pid;

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../../../log.dart';
import 'tray_host.dart';
import 'tray_menu.dart';

const _watcher = 'org.kde.StatusNotifierWatcher';
final _watcherPath = DBusObjectPath('/StatusNotifierWatcher');
const _itemIf = 'org.kde.StatusNotifierItem';
const _menuIf = 'com.canonical.dbusmenu';
final _itemPath = DBusObjectPath('/StatusNotifierItem');
final _menuPath = DBusObjectPath('/MenuBar');
const _limit = Duration(seconds: 3);

class LinuxTray extends TrayHost {
  LinuxTray._(this._client);

  /// The session bus's tray; null without a session bus.
  static Future<LinuxTray?> start() async {
    final DBusClient client;
    try {
      client = DBusClient.session();
    } on Object catch (e) {
      logWarn('tray', 'no session bus (${e.runtimeType})');
      return null;
    }
    final tray = LinuxTray._(client);
    await tray.check();
    tray._watch();
    return tray;
  }

  final DBusClient _client;
  late final _item = _Item(this);
  late final _menu = _Menu(this);
  final _available = ValueNotifier(false);
  bool _objects = false;
  bool _shown = false;
  TrayView? _view;
  int _revision = 1;

  String get _name => 'org.kde.StatusNotifierItem-$pid-1';

  @override
  ValueListenable<bool> get available => _available;

  @override
  Future<bool> check() async {
    var ok = false;
    try {
      if (await _client.nameHasOwner(_watcher).timeout(_limit)) {
        final r = await _client
            .callMethod(
              destination: _watcher,
              path: _watcherPath,
              interface: 'org.freedesktop.DBus.Properties',
              name: 'Get',
              values: [const DBusString(_watcher), const DBusString('IsStatusNotifierHostRegistered')],
              replySignature: DBusSignature('v'),
            )
            .timeout(_limit);
        ok = r.values.first.asVariant().asBoolean();
      }
    } on Object catch (e) {
      logWarn('tray', 'watcher not asked (${e.runtimeType})');
    }
    _available.value = ok;
    return ok;
  }

  void _watch() {
    // A panel that restarts comes back with a new watcher: register with it again.
    _client.nameOwnerChanged.where((e) => e.name == _watcher).listen((e) async {
      await check();
      if (_shown && e.newOwner != null) await _register();
    });
    for (final name in ['StatusNotifierHostRegistered', 'StatusNotifierHostUnregistered']) {
      DBusSignalStream(_client, interface: _watcher, name: name).listen((_) => unawaited(check()));
    }
  }

  Future<void> _register() async {
    try {
      await _client
          .callMethod(
            destination: _watcher,
            path: _watcherPath,
            interface: _watcher,
            name: 'RegisterStatusNotifierItem',
            values: [DBusString(_name)],
            replySignature: DBusSignature(''),
          )
          .timeout(_limit);
    } on Object catch (e) {
      logWarn('tray', 'not registered with the watcher (${e.runtimeType})');
      rethrow;
    }
  }

  @override
  Future<({List<int> icons, int menu})> sizes() async => (icons: const [16, 24, 32, 48, 64], menu: 16);

  @override
  Future<void> show(TrayView view) async {
    final before = _view;
    _view = view;
    if (!_objects) {
      await _client.registerObject(_item);
      await _client.registerObject(_menu);
      _objects = true;
    }
    if (!_shown || before == null) {
      await _client.requestName(_name, flags: {DBusRequestNameFlag.doNotQueue}).timeout(_limit);
      _shown = true;
      try {
        await _register();
      } on Object {
        await remove();
        rethrow;
      }
      return;
    }
    if (!listEquals(before.icons, view.icons)) {
      await _item.emitSignal(_itemIf, 'NewIcon');
      await _item.emitSignal(_itemIf, 'NewAttentionIcon');
    }
    if (before.title != view.title) await _item.emitSignal(_itemIf, 'NewTitle');
    if (before.tooltip != view.tooltip) await _item.emitSignal(_itemIf, 'NewToolTip');
    if (before.attention != view.attention) await _item.emitSignal(_itemIf, 'NewStatus', [DBusString(_status(view))]);
    if (!listEquals(before.items, view.items) || !mapEquals(before.marks, view.marks)) {
      _revision++;
      await _menu.emitSignal(_menuIf, 'LayoutUpdated', [DBusUint32(_revision), const DBusInt32(0)]);
    }
  }

  @override
  Future<void> remove() async {
    if (!_shown) return;
    _shown = false;
    // The watcher drops an item whose name goes.
    try {
      await _client.releaseName(_name).timeout(_limit);
    } on Object catch (e) {
      logWarn('tray', 'name not released (${e.runtimeType})');
    }
  }
}

String _status(TrayView v) => v.attention ? 'NeedsAttention' : 'Active';

final _pixmaps = Expando<DBusValue>();

/// SNI's icons: (width, height, ARGB32 in network order) per size.
DBusValue _pixmapsOf(List<TrayImage> icons) => DBusArray(DBusSignature('(iiay)'), [
  for (final i in icons) _pixmaps[i] ??= DBusStruct([DBusInt32(i.width), DBusInt32(i.height), DBusArray.byte(_argb(i.rgba))]),
]);

Uint8List _argb(Uint8List rgba) {
  final out = Uint8List(rgba.length);
  for (var p = 0; p + 3 < rgba.length; p += 4) {
    out[p] = rgba[p + 3];
    out[p + 1] = rgba[p];
    out[p + 2] = rgba[p + 1];
    out[p + 3] = rgba[p + 2];
  }
  return out;
}

DBusArgumentDirection get _in => DBusArgumentDirection.in_;
DBusArgumentDirection get _out => DBusArgumentDirection.out;

class _Item extends DBusObject {
  _Item(this.tray) : super(_itemPath);

  final LinuxTray tray;

  Map<String, DBusValue> _props() {
    final v = tray._view;
    final title = v?.title ?? '';
    final tip = v?.tooltip ?? '';
    final cut = tip.indexOf('\n');
    final icons = v?.icons ?? const <TrayImage>[];
    return {
      'Category': const DBusString('ApplicationStatus'),
      'Id': const DBusString('epic-cash-desktop'),
      'Title': DBusString(title),
      'Status': DBusString(v == null ? 'Active' : _status(v)),
      'WindowId': const DBusInt32(0),
      'IconName': const DBusString(''),
      'IconThemePath': const DBusString(''),
      'IconPixmap': _pixmapsOf(icons),
      'OverlayIconName': const DBusString(''),
      'OverlayIconPixmap': _pixmapsOf(const []),
      'AttentionIconName': const DBusString(''),
      'AttentionIconPixmap': _pixmapsOf(icons),
      'AttentionMovieName': const DBusString(''),
      'ToolTip': DBusStruct([
        const DBusString(''),
        _pixmapsOf(const []),
        DBusString(cut < 0 ? tip : tip.substring(0, cut)),
        DBusString(cut < 0 ? '' : tip.substring(cut + 1)),
      ]),
      'ItemIsMenu': const DBusBoolean(false),
      'Menu': _menuPath,
    };
  }

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      _itemIf,
      methods: [
        for (final m in ['Activate', 'SecondaryActivate', 'ContextMenu'])
          DBusIntrospectMethod(m, args: [DBusIntrospectArgument(DBusSignature('i'), _in, name: 'x'), DBusIntrospectArgument(DBusSignature('i'), _in, name: 'y')]),
        DBusIntrospectMethod('Scroll', args: [DBusIntrospectArgument(DBusSignature('i'), _in, name: 'delta'), DBusIntrospectArgument(DBusSignature('s'), _in, name: 'orientation')]),
      ],
      signals: [
        for (final s in ['NewTitle', 'NewIcon', 'NewAttentionIcon', 'NewOverlayIcon', 'NewToolTip']) DBusIntrospectSignal(s),
        DBusIntrospectSignal('NewStatus', args: [DBusIntrospectArgument(DBusSignature('s'), _out, name: 'status')]),
      ],
      properties: [for (final e in _props().entries) DBusIntrospectProperty(e.key, e.value.signature, access: DBusPropertyAccess.read)],
    ),
  ];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != _itemIf) return DBusMethodErrorResponse.unknownInterface();
    switch (call.name) {
      case 'Activate' || 'SecondaryActivate':
        tray.onClick?.call();
        return DBusMethodSuccessResponse();
      case 'ContextMenu' || 'Scroll':
        // The host shows the menu from /MenuBar itself.
        return DBusMethodSuccessResponse();
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final v = interface == _itemIf ? _props()[name] : null;
    return v == null ? DBusMethodErrorResponse.unknownProperty() : DBusGetPropertyResponse(v);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async =>
      DBusGetAllPropertiesResponse(interface == _itemIf ? _props() : const {});
}

class _Menu extends DBusObject {
  _Menu(this.tray) : super(_menuPath);

  final LinuxTray tray;

  List<TrayItem> get _items => tray._view?.items ?? const [];

  /// dbusmenu reads "_" as the access key's mark.
  static String _escape(String s) => s.replaceAll('_', '__');

  /// Item n of the menu has id n + 1; 0 is the menu itself.
  Map<String, DBusValue> _propsOf(int id) {
    if (id == 0) return {'children-display': const DBusString('submenu')};
    final items = _items;
    if (id < 1 || id > items.length) return const {};
    final it = items[id - 1];
    if (it.kind == TrayItemKind.separator) return {'type': const DBusString('separator')};
    final png = tray._view?.marks[it.mark]?.png;
    return {
      'label': DBusString(_escape(it.label)),
      'enabled': DBusBoolean(it.enabled && it.kind == TrayItemKind.item),
      'visible': const DBusBoolean(true),
      if (it.checked != null) ...{
        'toggle-type': const DBusString('checkmark'),
        'toggle-state': DBusInt32(it.checked! ? 1 : 0),
      },
      if (png != null) 'icon-data': DBusArray.byte(png),
    };
  }

  DBusValue _layout(int id, int depth) => DBusStruct([
    DBusInt32(id),
    DBusDict.stringVariant(_propsOf(id)),
    DBusArray(DBusSignature('v'), [
      if (id == 0 && depth != 0) for (var i = 1; i <= _items.length; i++) DBusVariant(_layout(i, depth - 1)),
    ]),
  ]);

  void _event(int id, String event) {
    if (event != 'clicked' || id < 1 || id > _items.length) return;
    final it = _items[id - 1];
    if (it.id.isEmpty || !it.enabled) return;
    // After the host's own reply: the menu is closing.
    scheduleMicrotask(() => tray.onActivate?.call(it.id));
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    DBusIntrospectArgument a(String sig, DBusArgumentDirection d, String name) => DBusIntrospectArgument(DBusSignature(sig), d, name: name);
    return [
      DBusIntrospectInterface(
        _menuIf,
        methods: [
          DBusIntrospectMethod('GetLayout', args: [a('i', _in, 'parentId'), a('i', _in, 'recursionDepth'), a('as', _in, 'propertyNames'), a('u', _out, 'revision'), a('(ia{sv}av)', _out, 'layout')]),
          DBusIntrospectMethod('GetGroupProperties', args: [a('ai', _in, 'ids'), a('as', _in, 'propertyNames'), a('a(ia{sv})', _out, 'properties')]),
          DBusIntrospectMethod('GetProperty', args: [a('i', _in, 'id'), a('s', _in, 'name'), a('v', _out, 'value')]),
          DBusIntrospectMethod('Event', args: [a('i', _in, 'id'), a('s', _in, 'eventId'), a('v', _in, 'data'), a('u', _in, 'timestamp')]),
          DBusIntrospectMethod('EventGroup', args: [a('a(isvu)', _in, 'events'), a('ai', _out, 'idErrors')]),
          DBusIntrospectMethod('AboutToShow', args: [a('i', _in, 'id'), a('b', _out, 'needUpdate')]),
          DBusIntrospectMethod('AboutToShowGroup', args: [a('ai', _in, 'ids'), a('ai', _out, 'updatesNeeded'), a('ai', _out, 'idErrors')]),
        ],
        signals: [
          DBusIntrospectSignal('ItemsPropertiesUpdated', args: [a('a(ia{sv})', _out, 'updatedProps'), a('a(ias)', _out, 'removedProps')]),
          DBusIntrospectSignal('LayoutUpdated', args: [a('u', _out, 'revision'), a('i', _out, 'parent')]),
          DBusIntrospectSignal('ItemActivationRequested', args: [a('i', _out, 'id'), a('u', _out, 'timestamp')]),
        ],
        properties: [for (final e in _props.entries) DBusIntrospectProperty(e.key, e.value.signature, access: DBusPropertyAccess.read)],
      ),
    ];
  }

  Map<String, DBusValue> get _props => {
    'Version': const DBusUint32(3),
    'TextDirection': const DBusString('ltr'),
    'Status': const DBusString('normal'),
    'IconThemePath': DBusArray.string(const []),
  };

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != _menuIf) return DBusMethodErrorResponse.unknownInterface();
    final v = call.values;
    switch (call.name) {
      case 'GetLayout':
        return DBusMethodSuccessResponse([DBusUint32(tray._revision), _layout(v[0].asInt32(), v[1].asInt32())]);
      case 'GetGroupProperties':
        final asked = v[0].asInt32Array().toList();
        final ids = asked.isEmpty ? [for (var i = 0; i <= _items.length; i++) i] : asked;
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('(ia{sv})'), [for (final id in ids) DBusStruct([DBusInt32(id), DBusDict.stringVariant(_propsOf(id))])]),
        ]);
      case 'GetProperty':
        final p = _propsOf(v[0].asInt32())[v[1].asString()];
        return p == null ? DBusMethodErrorResponse.invalidArgs() : DBusMethodSuccessResponse([DBusVariant(p)]);
      case 'Event':
        _event(v[0].asInt32(), v[1].asString());
        return DBusMethodSuccessResponse();
      case 'EventGroup':
        for (final e in v[0].asArray()) {
          final s = e.asStruct();
          _event(s[0].asInt32(), s[1].asString());
        }
        return DBusMethodSuccessResponse([DBusArray.int32(const [])]);
      case 'AboutToShow':
        return DBusMethodSuccessResponse([const DBusBoolean(false)]);
      case 'AboutToShowGroup':
        return DBusMethodSuccessResponse([DBusArray.int32(const []), DBusArray.int32(const [])]);
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final v = interface == _menuIf ? _props[name] : null;
    return v == null ? DBusMethodErrorResponse.unknownProperty() : DBusGetPropertyResponse(v);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async => DBusGetAllPropertiesResponse(interface == _menuIf ? _props : const {});
}
