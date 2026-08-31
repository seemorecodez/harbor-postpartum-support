typedef RemoveVisibilityLockListener = void Function();

RemoveVisibilityLockListener registerVisibilityLock(void Function() onHidden) {
  return () {};
}
