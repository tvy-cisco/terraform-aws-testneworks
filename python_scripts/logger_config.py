import logging


# Configure the logger
def setup_logger():
    # Create a custom logger
    logger = logging.getLogger("network_switch")
    logger.setLevel(logging.DEBUG)

    # Create handlers
    console_handler = logging.StreamHandler()

    # Set logging levels for handlers
    console_handler.setLevel(logging.INFO)

    # Create formatters and add them to the handlers
    console_format = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    console_handler.setFormatter(console_format)

    # Add handlers to the logger
    logger.addHandler(console_handler)

    return logger


# Initialize the logger
logger = setup_logger()
