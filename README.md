Simple Resource loading using `await`.
This is useful for loading assets without freezing the game.

Basic Usage:
```GDScript
var icon := await AsyncResourceLoadManager.load_resource_async_simple("res://icon.svg") as Texture2D
```

For advanced use cases, see `AsyncResourceLoadHandle.gd` and `AsyncResourceLoadManager.gd`.
