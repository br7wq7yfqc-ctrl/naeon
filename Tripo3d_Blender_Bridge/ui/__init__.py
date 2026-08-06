import bpy

modules = ("sidebar_panel",)

register, unregister = bpy.utils.register_submodule_factory(__package__, modules)
