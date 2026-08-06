"""多语言支持模块"""
import bpy
from .dictionary import dictionary

def get_blender_language():
    try:
        prefs = bpy.context.preferences
        view = prefs.view
        lang = view.language
        return lang
    except Exception as e:
        print(f"Error getting Blender language: {e}")
        return 'en_US'


def is_language_supported(lang_code):
    """检查语言是否被支持"""
    return lang_code in dictionary


def register():
    try:
        current_lang = get_blender_language()
        
        if current_lang != 'en_US' and is_language_supported(current_lang):
            bpy.app.translations.register(__name__, dictionary)
            
    except Exception as e:
        print(f"Tripo bridge: Failed to register translations: {e}")


def unregister():
    try:
        bpy.app.translations.unregister(__name__)
    except Exception as e:
        pass

