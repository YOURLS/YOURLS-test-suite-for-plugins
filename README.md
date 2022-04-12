# YOURLS test suite for plugins

> A PHPUnit tool for YOURLS plugins.


## About

The **YOURLS test suite for plugins** is a tool to test YOURLS plugins with standard PHPUnit tests.

This tool assumes basic knowledge of command line tools and of the [PHPUnit](https://phpunit.de/ "PHPUnit") framework.

## Usage

0. **Have a plugin with tests**   
    See the short guide about writing unit tests for YOURLS plugins.

1. **Install the YOURLS test suite for plugins**   
    In `my-cool-plugin/` :
    ```shell
    $ git clone https://github.com/YOURLS/YOURLS-test-suite-for-plugins test-suite
    ```

2. **Install the YOURLS test suite and the testing database**   
    ```shell
    $ bash test-suite/src/install-test-suite.sh <db-name> <db-user> <db-password> [db-host, default localhost] [YOURLS version, default master]
    ```
    Examples  :
    ```shell
    $ bash test-suite/src/install-test-suite.sh yourlstest root ""
    $ bash test-suite/src/install-test-suite.sh yourlstest mydbuser mydbpassword mysql.myserver.com:666 1.8.2
    ```

3. **Run your plugin unit tests**   
    Once you have written unit tests, run them :
    ```sh
    $ phpunit -c ./test-suite/src/phpunit.xml
    ```
    Expected result would be something like :
    ```sh
    $ phpunit -c ./test-suite/src/phpunit.xml
    YOURLS installed, starting PHPUnit

    Plugin Loaded : My cool plugin by Joe (my-cool-plugin/plugin.php)

    PHPUnit 9.5.2 by Sebastian Bergmann and contributors.

    ......                                                              3 / 3 (100%)

    Time: 00:00.007, Memory: 22.00 MB

    OK (3 tests, 6 assertions)
    $
    ```


## License

Free software. Do whatever the hell you want with it.   
YOURLS is released under the [MIT license](LICENSE).
