import os
import logging


def _init_logger():
    _logger = logging.getLogger("tripo_addon")
    _logger.setLevel(logging.INFO)

    import tempfile
    log_dir = tempfile.gettempdir()
    log_file = os.path.join(log_dir, "tripo3d_blender_bridge.log")
    print(f"[Tripo3D] Log file: {log_file}")

    try:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.DEBUG)

        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - [%(filename)s:%(lineno)d] - %(levelname)s - %(message)s",
            datefmt="%H:%M:%S"
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)

        _logger.addHandler(file_handler)
        _logger.addHandler(console_handler)

    except PermissionError:
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            datefmt="%H:%M:%S"
        )
        console_handler.setFormatter(formatter)
        _logger.addHandler(console_handler)
        print("Warning: Could not create log file. Logging to console only.")
    
    return _logger

logger = _init_logger()

