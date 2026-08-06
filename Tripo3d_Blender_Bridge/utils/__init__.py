import bpy

modules = ()

register, unregister = bpy.utils.register_submodule_factory(__package__, modules)