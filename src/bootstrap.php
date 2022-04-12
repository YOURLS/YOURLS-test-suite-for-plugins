<?php
/**
 * YOURLS test suite for plugins - bootstrap file
 * @link https://github.com/YOURLS/YOURLS-test-suite-for-plugins
 * @author Ozh
 * @author YOURLS contributors
 */

/**
 * Paths to YOURLS root that will be checked out with Git in this directory.
 * We're not using the current YOURLS root the tested plugin belongs to, as the test suite may be missing or out of date.
 */
define('YOURLS_ABSPATH', dirname(__DIR__).'/YOURLS');

/**
 * Other paths belong to current YOURLS root - otherwise we would not be able to load the plugin
 * we're testing since the YOURLS test suite locates plugins in <YOURLS ROOT>/tests/data/
 */
define('YOURLS_PARENT_USER', dirname(dirname(dirname(dirname(__DIR__)))));
define('YOURLS_PLUGINDIR',   YOURLS_PARENT_USER.'/plugins/');
define('YOURLS_PAGEDIR',     YOURLS_PARENT_USER.'/pages/');
define('YOURLS_LANG_DIR',    YOURLS_PARENT_USER.'/languages/');

// YOURLS Unit tests use a sample language file to test translations - don't use it here
define('YOURLS_LANG', '');

// Get error reporting level & suppress warnings triggered by YOURLS test suite when redefining constants
$errorReportingLevel = error_reporting();
error_reporting(E_ALL & ~E_WARNING);

// Load YOURLS and its test suite
if(!file_exists(dirname(__DIR__) . '/YOURLS/tests/bootstrap.php')) {
    die("YOURLS test suite not found. Please run script `install-test-suite.sh`\n");
}
require_once dirname(__DIR__) . '/YOURLS/tests/bootstrap.php';

// Restore error reporting level
error_reporting($errorReportingLevel);

// Load plugin
$plugin = dirname(dirname(__DIR__)).'/plugin.php';
$plugin_data = yourls_get_plugin_data($plugin);
$activate = yourls_activate_plugin($plugin);
if( $activate !== true ) {
    die("Failed to activate plugin. Error was: $activate\n");
}
printf("Plugin Loaded : %s by %s (%s)\n\n",
    yourls_kses_decode_entities($plugin_data['Plugin Name']),
    yourls_kses_decode_entities($plugin_data["Author"]),
    basename(dirname($plugin))."/plugin.php");

// The plugin tests will now start
