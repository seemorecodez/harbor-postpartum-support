import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef RemoveVisibilityLockListener = void Function();

RemoveVisibilityLockListener registerVisibilityLock(void Function() onHidden) {
  void handleVisibilityChange(web.Event? _) {
    if (web.document.visibilityState == 'hidden') {
      onHidden();
    }
  }

  void handleWindowBlur(web.Event? _) => onHidden();

  final visibilityListener = handleVisibilityChange.toJS;
  final blurListener = handleWindowBlur.toJS;
  web.document.addEventListener('visibilitychange', visibilityListener);
  web.window.addEventListener('blur', blurListener);
  return () {
    web.document.removeEventListener('visibilitychange', visibilityListener);
    web.window.removeEventListener('blur', blurListener);
  };
}
