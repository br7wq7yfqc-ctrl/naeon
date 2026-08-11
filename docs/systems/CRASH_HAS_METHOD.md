# Crash: Object::has_method SIGSEGV (0.3.20)

## Stack
Object::has_method → GDScript call → Node::_notification → SceneTree process

## Cause
Calling has_method / methods on queue_freed SurfaceWalker after F board/exit.
SoftNetSession / SoftScanCache / deferred timers held stale refs.

## Fix (0.3.21)
- _safe_free_walker: unbind SoftNet/SoftENet/ScanCache, remove_child, then queue_free
- SoftNetSession._capture revalidates; no has_method on dead
- SoftScanCache.invalidate_player
- _call_if / is_instance_valid guards
- surface settle ticks abort on dead player
