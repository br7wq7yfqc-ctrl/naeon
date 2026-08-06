import threading
import bpy

from .ws_server import Server
from ..utils.logger import logger

task_manager = None


class TaskManager:

    def __init__(self):
        self.ws_server = None
        self.ws_thread = None

    def start(self):
        if self.ws_server is None:
            self.ws_server = Server(port=60600)
            self.ws_thread = threading.Thread(target=self.ws_server.run, daemon=True)
            self.ws_thread.start()
            logger.info("WebSocket server started on port 60600")

    def stop(self):
        if self.ws_server:
            try:
                self.ws_server._direct_close()
                logger.info("WebSocket server stop requested")
            except Exception as e:
                logger.error(f"Error stopping WebSocket server: {e}")
            self.ws_server = None

        if self.ws_thread and self.ws_thread.is_alive():
            self.ws_thread.join(timeout=2.0)
            if self.ws_thread.is_alive():
                logger.warning("WebSocket thread did not exit cleanly (timeout)")
        self.ws_thread = None


def register():
    global task_manager
    if task_manager is None:
        task_manager = TaskManager()
        task_manager.start()


def unregister():
    global task_manager
    if task_manager:
        task_manager.stop()
        task_manager = None