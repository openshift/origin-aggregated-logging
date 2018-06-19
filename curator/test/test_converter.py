#!/usr/bin/python

import os
import filecmp
import unittest
from mock import patch
from oalconverter.convert import LegacyConfigConverter

class TestConverter(unittest.TestCase):

    LEGACY_CONFIG               = 'CURATOR_CONF_LOCATION'
    ACTIONS_FILE                = 'CURATOR_ACTIONS_FILE'
    TEST_DIR                    = os.getcwd() + '/test/'
    ACTIONS_FILE_WRITE_LOCATION = os.getenv('HOME') + '/actions.yaml'

    def tearDown(self):
        if os.path.isfile(self.ACTIONS_FILE_WRITE_LOCATION):
            os.remove(self.ACTIONS_FILE_WRITE_LOCATION)

    @patch.dict('os.environ', { LEGACY_CONFIG : TEST_DIR + 'empty-cfg.yaml' })
    def test_empty_config(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 1, "Exit code 1 expected on successful convertion")
        self.assertTrue(filecmp.cmp(self.ACTIONS_FILE_WRITE_LOCATION, self.TEST_DIR + 'empty-cfg-result.yaml', shallow=False))

    @patch.dict('os.environ', { LEGACY_CONFIG : TEST_DIR + 'basic-cfg.yaml' })
    def test_basic_config(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 1, "Exit code 1 expected on successful convertion")
        self.assertTrue(filecmp.cmp(self.ACTIONS_FILE_WRITE_LOCATION, self.TEST_DIR + 'basic-cfg-result.yaml', shallow=False))

    @patch.dict('os.environ', { LEGACY_CONFIG : TEST_DIR + 'regex-cfg.yaml' })
    def test_regex_config(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 1, "Exit code 1 expected on successful convertion")
        self.assertTrue(filecmp.cmp(self.ACTIONS_FILE_WRITE_LOCATION, self.TEST_DIR + 'regex-cfg-result.yaml', shallow=False))

    @patch.dict('os.environ', { LEGACY_CONFIG : TEST_DIR + 'name-too-long-cfg.yaml' })
    def test_name_too_long(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 2, "Exit code 2 expected on error")

    @patch.dict('os.environ', { LEGACY_CONFIG : TEST_DIR + 'name-invalid-cfg.yaml' })
    def test_name_invalid(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 2, "Exit code 2 expected on error")

    @patch.dict('os.environ', { ACTIONS_FILE : TEST_DIR + 'basic-cfg-result.yaml' })
    def test_actions_exists(self):
        ret = LegacyConfigConverter().convert()
        self.assertEqual(ret, 0, "Exit code 0 expected when actions file already exists")

if __name__ == '__main__':
    unittest.main()
