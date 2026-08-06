import bpy
import bpy.utils.previews
import os
from ..core.status_manager import status, ConnectionState
from ..utils.logger import logger
from .. import bl_info

STUDIO_URL = "https://studio.tripo3d.ai/workspace/generate"
TUTORIAL_URL = bl_info.get("doc_url", "")

_custom_icons = None


class VIEW3D_PT_TripoPanel(bpy.types.Panel):
    bl_label = "Tripo bridge"
    bl_idname = "VIEW3D_PT_tripo"
    bl_space_type = 'VIEW_3D'         # 所属空间：3D 视图
    bl_region_type = 'UI'             # 区域类型：Sidebar
    bl_category = "Tripo"             # 标签页名（右侧栏标签）

    def draw(self, context):
        layout = self.layout

        # Tripo Studio 链接
        box = layout.box()
        row = box.row(align=True)

        global _custom_icons
        if _custom_icons and "tripo_icon" in _custom_icons:
            icon = _custom_icons["tripo_icon"].icon_id
            op = row.operator("wm.url_open", text=bpy.app.translations.pgettext("Open Tripo Studio"), icon_value=icon)
        else:
            op = row.operator("wm.url_open", text=bpy.app.translations.pgettext("Open Tripo Studio"), icon='WORLD')
        op.url = STUDIO_URL  # type: ignore

        # 教程链接问号图标
        if TUTORIAL_URL:
            op = row.operator("wm.url_open", text="", icon='QUESTION')
            op.url = TUTORIAL_URL

        # 连接状态
        box = layout.box()
        box.label(text=bpy.app.translations.pgettext("Connection Status:"))
        row = box.row()
        if status.state == ConnectionState.CONNECTED:
            connected_text = bpy.app.translations.pgettext_iface("Connected", "Tripo bridge")
            row.alert = False
            row.label(text=f"{connected_text}", icon='WORLD_DATA')
        elif status.state == ConnectionState.LISTENING:
            row.alert = False
            row.label(text=bpy.app.translations.pgettext_iface("Waiting for connection", "Tripo bridge"), icon='REC')
        else:
            row.alert = True
            row.label(text=bpy.app.translations.pgettext_iface("Disconnected", "Tripo bridge"), icon='CANCEL')

        if status.last_log:
            box.label(text=bpy.app.translations.pgettext("Last Log:"))
            # 分行显示长文本
            log_text = status.last_log[:120]
            box.label(text=log_text)

classes = (
    VIEW3D_PT_TripoPanel,
)


def register():
    global _custom_icons
    _custom_icons = bpy.utils.previews.new()
    
    addon_dir = os.path.dirname(os.path.dirname(__file__))
    icons_dir = os.path.join(addon_dir, "assets")
    icon_path = os.path.join(icons_dir, "logo.png")
    
    if os.path.exists(icon_path):
        _custom_icons.load("tripo_icon", icon_path, 'IMAGE')
        logger.debug(f"Custom icon loaded: {icon_path}")
    else:
        logger.warning(f"Icon file not found: {icon_path}")
    
    for cls in classes:
        bpy.utils.register_class(cls)
    logger.debug("Sidebar panel registered.")


def unregister():
    global _custom_icons
    if _custom_icons:
        bpy.utils.previews.remove(_custom_icons)
        _custom_icons = None
    
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
    logger.debug("Sidebar panel unregistered.")
