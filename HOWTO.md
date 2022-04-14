
# How to write Unit Tests for YOURLS plugins

Here are some tips, examples and guidance about writing simple yet proper unit tests for your YOURLS plugins.

## What are unit tests, the short story :

In two points :
* Split your code in small pieces (make it "atomic") : one function should do one thing ;
* Write simple tests to make sure that every single function returns expected results.

This may sound stupid and useless at first, because, well, you just wrote that simple piece of code, so you know for sure that it does work expectedly ?!
But the thing is, your functions probably use YOURLS internals, or other parts of your own plugin, and in the future any of these elements may change, in a way that could break your function.

Writing unit tests for your plugin is a simple and effective way to test that :
* your code works as expected throughout the evolution of your plugin,
* at any point, your plugin works correctly with the current version of YOURLS,

Even better : if you [automate](WORKFLOWS.md) the tests, you will be able to :
* test your plugin automatically on every commit or pull request,
* test your plugin automatically whenever YOURLS releases a new version,
* and test everything against different versions of PHP.


## For starters : directory structure, file naming, code convention

In your plugin's directory, say `my-cool-plugin`, create a `tests` folder where your unit tests will live. They should be prefixed with `test-`.

In the end the directory structure would be :
```bash
<YOURLS ROOT>
    ↳ user/
        ↳ plugins/
            ↳ my-cool-plugin/
                ↳ plugin.php
                  uninstall.php
                  maybe-another-file.php
                  tests/
                      ↳ test-something.php
                        test-something-else.php
```

The anatomy of a test file would along the lines of :
```php
<?php
/**
 * Test that specific feature
 */

class ThatSpecificFeatureTest extends PHPUnit\Framework\TestCase {

    function test_something() {
        // do stuff, prepare things
        $thing = do_stuff();
        $this->assertEquals( 'expected result', $thing );
    }

    function test_something_else() {
        ...
    }
}
```
Each `test...()` methods contain one or several PHPUnit [assertions](https://phpunit.readthedocs.io/en/latest/assertions.html) in the form of `$this->assertSomething(...)`.


> :information_source:  Unit tests shall be :
> * PHP files starting with `test-` in a folder named `tests`
> * containing a class extending `PHPUnit\Framework\TestCase`
> * with methods prefixed with `test`(`test_plugin_is_loaded()` or `testPluginIsLoaded()`, whatever suits your habits)

## Real life practical example

### The plugin
As a case study, we'll use [@dgw](https://github.com/dgw/)'s simple plugin [Don't track admins](https://github.com/dgw/yourls-dont-track-admins).

This typical YOURLS plugin -- simple task, simple code -- is something like :

```php
<?php
/*
Plugin Name: Don't Track Admins
Plugin URI: https://github.com/dgw/yourls-dont-track-admins
Description: Don't count clicks on short URLs if user is logged in
*/

// when there's a short URL redirection, perform the check
yourls_add_action('redirect_shorturl', 'dgw_dont_track_admins_init');

// if user is logged in : don't update click count and traffic logging
function dgw_dont_track_admins_init() {
	if( yourls_is_valid_user() === true ) {
		yourls_add_filter( 'shunt_update_clicks', 'yourls_return_true' );
		yourls_add_filter( 'shunt_log_redirect', 'yourls_return_true' );
	}
}
```
How are we supposed to test that the plugin works as expected ? With every current and future YOURLS versions, we want to test that :
1. the plugin is proper PHP code (and doesn't break the whole YOURLS install -- a typical case of *"I commit a simple update but forgot a trailing semi-colon somewhere"*)
2. when a redirection occurs and the user is logged in, the function `yourls_return_true()` is hooked to `'shunt_update_clicks'` and `'shunt_log_redirect'`
3. when a redirection occurs and the user is NOT logged in, these two hooks have no filter.
4. when no redirection occurs, these two hooks have no filter, *ie* the plugin doesn't blindly add filters.

What we DON'T want to test is that, when a redirection occurs, the number of clicks is incremented on a given short URL is the user is not logged in and vice-versa. Why ? Because that would be testing the inner working of YOURLS and YOURLS already has tests for this.

> :information_source: Pro tip: don't test YOURLS itself, we already do it.
> Focus on testing only the simplest manifestation of your plugin expected behavior.

### The tests

Let's write some tests !

#### 1. testing that the plugin is proper PHP code

There is nothing special to do here, simply running the tests will do the job. If the plugin isn't valid PHP code, the tests will not start and you will see a message such as :

```sh
$ phpunit -c ./test-suite/src/phpunit.xml
YOURLS installed, starting PHPUnit

Failed to activate plugin. Error was: Plugin generated unexpected output. Error was: <br/><pre>Unclosed '{' on line 31</pre>
```

#### 2. testing a redirection with a logged in user

First, to simulate that a user is logged in, we will simply [bypass all the whole user authentication](https://github.com/YOURLS/YOURLS/blob/7067e9412b3e8ee8c28007df0dd4adb164ca37fd/includes/functions-auth.php#L26-L30) and make it always return `true`.
Then, to simulate a redirection, we will simply trigger the `'redirect_shorturl'` [action](https://github.com/YOURLS/YOURLS/blob/7067e9412b3e8ee8c28007df0dd4adb164ca37fd/includes/functions.php#L265).

```php
yourls_add_filter('shunt_is_valid_user', 'yourls_return_true');
yourls_do_action('pre_redirect');
```

Now we can check if the two hooks have the expected function, we retrieve the filters and make sure they have a key named `'yourls_return_true'`. Basically we want to make sure that the following is true:
```php
array_key_first(yourls_get_filters('shunt_update_clicks')[10]) === 'yourls_return_true';
array_key_first(yourls_get_filters('shunt_log_redirect')[10])  === 'yourls_return_true';
```

To do so, we'll use PHPUnit's assertion `assertSame()`.

Each test should be independent from the others, so any YOURLS behavior altered must be reverted. To do so, we'll use PHPUnit's [fixture `tearDown()`](https://phpunit.readthedocs.io/en/latest/fixtures.html), which is called after each test, to remove all filters that have been set in this test :

```php
yourls_remove_all_filters('shunt_is_valid_user'); // the one to simulate logged in user,
yourls_remove_all_filters('shunt_update_clicks'); // and the ones set by the plugin
yourls_remove_all_filters('shunt_log_redirect');  //
```

> :information_source: Always remember to revert any default behaviour your test function has created. Each of your tests should pass independently from the others and in any order.
> In case you have to chain tests in a particular order, you can use PHPUnit's annotation [`@depends`](https://phpunit.readthedocs.io/en/latest/annotations.html#depends).


#### 3. testing a redirection with an unlogged user

We will now simulate that a user is not logged in, and a redirection occurs : similarly, trigger the action and check that `yourls_get_filters('shunt_update_clicks')` returns this time an empty array.

#### 4. testing that no filter is defined when no redirection occurs

This time even shorter : without triggering the  `'redirect_shorturl'` action, we'll check that `'shunt_log_redirect'` and `'shunt_update_clicks'`  have no filter attached.

### Unit tests, wrapped up

The complete unit tests would be :

```php
<?php

/**
 * Test correct behaviors of the plugin.
 */
class PluginTest extends PHPUnit\Framework\TestCase {

    protected function tearDown(): void {
        // remove all filters
        yourls_remove_all_filters('shunt_is_valid_user');
        yourls_remove_all_filters('shunt_update_clicks');
        yourls_remove_all_filters('shunt_log_redirect');
    }

    function test_redirection_with_logged_in_user() {
        yourls_add_filter('shunt_is_valid_user', 'yourls_return_true');
        yourls_do_action('redirect_shorturl');

        $this->assertSame( array_key_first(yourls_get_filters('shunt_update_clicks')[10]), 'yourls_return_true' );
        $this->assertSame( array_key_first(yourls_get_filters('shunt_log_redirect')[10]), 'yourls_return_true' );
    }

    function test_redirection_with_unlogged_user() {
        yourls_add_filter('shunt_is_valid_user', 'yourls_return_false');
        yourls_do_action('redirect_shorturl');

        $this->assertSame( [], yourls_get_filters('shunt_update_clicks') );
        $this->assertSame( [], yourls_get_filters('shunt_log_redirect') );
    }

    function test_when_no_redirection() {
        $this->assertSame( [], yourls_get_filters('shunt_update_clicks') );
        $this->assertSame( [], yourls_get_filters('shunt_log_redirect') );
    }

}
```

Now run PHPUnit to check everything runs fine :
```sh
$ phpunit -c ./test-suite/src/phpunit.xml
YOURLS installed, starting PHPUnit

Plugin Loaded : Don't Track Admins by dgw (dont-track-admins/plugin.php)

PHPUnit 9.5.2 by Sebastian Bergmann and contributors.

...                                                                 3 / 3 (100%)

Time: 00:00.008, Memory: 22.00 MB

OK (3 tests, 6 assertions)
```

Hurray  :sparkles: :pizza: :clinking_glasses: :1st_place_medal: :tada: :-)

## Further reading

We have a guide here about setting up [Github workflows](WORKFLOWS.md) to automate tests whenever your plugin code changes, or when there is a new version of YOURLS released.

If you want to expand your PHPUnit practical knowledge, don't miss the following resources :
* PHPUnit excellent documentation : https://phpunit.readthedocs.io/
* YOURLS own test suite : all the tests can be found in [YOURLS](https://github.com/YOURLS/YOURLS)/[tests](https://github.com/YOURLS/YOURLS/tree/master/tests)/[tests](https://github.com/YOURLS/YOURLS/tree/master/tests/tests)/

Happy testing !
