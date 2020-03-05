import unittest
import test_py_context
from test_py_context import TestFlowControlContextConfig, TestPyServerContext

suite = unittest.TestSuite()
loader = unittest.TestLoader()

suite.addTest(loader.loadTestsFromTestCase(TestFlowControlContextConfig))
suite.addTest(loader.loadTestsFromTestCase(TestPyServerContext))

# with open("./test_result", 'w', encoding="utf-8") as result_file:
#     pass

unittest.main()