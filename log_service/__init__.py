import os
import sys
import importlib

if __name__ == "__main__":
    import_path = os.path.abspath(__file__)
    sys.path.append(import_path)
    importlib.import_module("fc_logging")
    
    sys.modules["FCLogger"] = FCLogger(20)