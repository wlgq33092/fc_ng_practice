from fc_logging import FCLogger

logger = FCLogger(30, "./test_py.log")
logger.set_debug()
logger.log_print("hello, default log!\n")
logger.log_error("hello, log error!\n")
logger.log_debug("hello, log debug!\n")
