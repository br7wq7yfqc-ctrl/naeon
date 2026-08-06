bl_info = {
    "name": "Tripo Bridge",
    "author": "Tripo AI",
    "version": (1, 0, 21),
    "blender": (4, 1, 0),
    "location": "View3D > Sidebar > Tripo Bridge",
    "description": "AI-Powered 3D Model Generation Addon",
    "category": "3D View",
    "doc_url": "https://www.tripo3d.ai/blog/tripo-dcc-bridge-for-blender",
}

import bpy
from .utils.logger import logger
modules = [
    "i18n",
    "core",
    "utils",
    "ui",
]

reg, unreg = bpy.utils.register_submodule_factory(__package__, modules)


def register():
    logger.debug(f"{bl_info['name']}: register")
    reg()


def unregister():
    logger.debug(f"{bl_info['name']}: unregister")
    # Blender 4.1 has a bug with register_submodule_factory unregister
    # Manually unregister submodules in reverse order to avoid AttributeError
    import sys
    for module_name in reversed(["ui", "utils", "core", "i18n"]):
        full_name = f"{__package__}.{module_name}"
        if full_name in sys.modules:
            try:
                mod = sys.modules[full_name]
                if hasattr(mod, 'unregister'):
                    mod.unregister()
            except Exception as e:
                logger.debug(f"Error unregistering {module_name}: {e}")
