
# Setting up Github workflows

How to automate all the things : run tests every time
* you commit new code,
* someone opens a pull request
* YOURLS releases a new version

# Run tests on every code change

In your plugin repository, create and commit `.github/workflows/tests.yml` with the following code :

```yml
name: Tests

on:
  # Allow manual trigger of the workflow
  workflow_dispatch:
  # Run on every push and pull request on `master`
  push:
  pull_request:
    branches: [ master ]

jobs:
  test:
    name: PHP
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        php: ['8.0', '8.1']
        phpunit: ['latest']
        include:
          - php: '7.4'
            phpunit: '8.5.13'

    services:
      mysql:
        image: mariadb
        ports:
          - 3306:3306
        env:
          MYSQL_ALLOW_EMPTY_PASSWORD: yes
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v3

      - name: Use PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@2
        with:
          php-version: ${{ matrix.php }}
          extensions: mbstring, curl, zip, dom, simplexml, intl, pdo_mysql
          tools: phpunit:${{ matrix.phpunit }}

      - name: Install the YOURLS test suite for plugins
        run: |
          git clone --depth 1 https://github.com/YOURLS/YOURLS-test-suite-for-plugins test-suite
          bash test-suite/src/install-test-suite.sh yourls_tests root '' 127.0.0.1

      - name: Check files
        run: |
          echo "Working directory: $(pwd)"
          ls -la

      - name: Run the tests
        run: phpunit -c ./test-suite/src/phpunit.xml
```

This workflow will run every time a commit or a pull request is made ; you can also run it manually.

What it does :
* install PHP and the needed dependencies
* run multiple jobs against PHP `7.4`, `8.0` and `8.1` (YOURLS requirements at the time of writing)
* install and run the YOURLS test suite for plugins

# Automatically check if there's a new YOURLS release

Maybe your plugin is fine as-is and you won't update it for years. But maybe a future YOURLS version will change something and break it ? Here's how to find out.

Create and commit two files :
* An empty `.github/.latest-yourls-release`, that will contain the latest [YOURLS release](https://github.com/YOURLS/YOURLS/releases), eg `1.8.2`
* A workflow named `.github/workflows/check-yourls-release.yml` with the following code :

```yml
name: Check if new YOURLS release

on:
  # Run every Monday
  schedule:
    - cron:  '37 13 * * 1'
  # Also allow manually triggering the workflow.
  workflow_dispatch:

jobs:
  get-version:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Fetch release version
        run: |
          curl -sL https://api.github.com/repos/yourls/yourls/releases/latest | \
          jq -r ".tag_name" > .github/.latest-yourls-release
          
      - name: Commit and push if change
        id: commit-if-new
        run: |
          git diff
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add -A
          git commit -m "New YOURLS release" && echo "::set-output name=NEWVERSION::new"
          git push
          
      - name: Create Issue on new release
        if: steps.commit-if-new.outputs.NEWVERSION == 'new'
        uses: mrdoodles/open-issue@v1.0.0
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          title: New YOURLS release !
          body: |
            There is a new YOURLS release available: https://github.com/YOURLS/YOURLS/releases

            Please check if your plugin is compatible with this release !
```

What it does :
* Runs manually and automatically once a week (given the release pace of YOURLS, you could even safely run this once a month), and downloads the latest YOURLS tag
* Updates `.github/.latest-yourls-release` if there's a new release
* Opens a new issue if there's a new release, as a reminder to check things

Happy automating !
