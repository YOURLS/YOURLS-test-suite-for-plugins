#!/usr/bin/env bash

#
# YOURLS test suite for plugins - bash script to install the test suite
# @link https://github.com/YOURLS/YOURLS-test-suite-for-plugins
# @author Ozh
# @author YOURLS contributors
#

# Make sure the needed commands are available, or exit
NEEDED_CMDS=("git" "mysqladmin")
for cmd in ${NEEDED_CMDS[@]}; do
    type "$cmd" >/dev/null 2>&1 || {
        echo >&2 "Script requires $cmd but it's not installed. Aborting."
        exit 1
    }
done

# Script usage shown when less than 3 arguments
if [ $# -lt 3 ]; then
    echo "Usage: $(basename $0) <db-name> <db-user> <db-pass> [db-host (default: localhost)] [yourls-version (default: master)]"
    echo "Examples :"
    echo "    $(basename $0) testyourls testuser testpass"
    echo "    $(basename $0) testyourls root \"\" localhost 1.8.1"
    exit 1
fi

DB_NAME=$1
DB_USER=$2
DB_PASS=$3
DB_HOST=${4-localhost}
YOURLS_VERSION=${5-master}

# Get working directory
#                                    ↓ install-test-suite.sh
#                         ↓ src/
#              ↓ test-suite/
WORKING_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"
echo "Working directory: $WORKING_DIR"

# Exit script as soon as a command fails, and print all commands.
set -ex

install_db() {
    # Parse DB_HOST for port or socket references. Hat tip: WP-CLI install script
    local PARTS=(${DB_HOST//\:/ })
    local DB_HOSTNAME=${PARTS[0]}
    local DB_SOCK_OR_PORT=${PARTS[1]}
    local EXTRA=""

    if ! [ -z $DB_HOSTNAME ]; then
        if [ $(echo $DB_SOCK_OR_PORT | grep -e '^[0-9]\{1,\}$') ]; then
            EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
        elif ! [ -z $DB_SOCK_OR_PORT ]; then
            EXTRA=" --socket=$DB_SOCK_OR_PORT"
        elif ! [ -z $DB_HOSTNAME ]; then
            EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
        fi
    fi

    mysqladmin create $DB_NAME --user="$DB_USER" --password="$DB_PASS"$EXTRA
}

install_yourls() {
    # Shallow clone YOURLS at expected version
    git clone --depth 1 --branch $YOURLS_VERSION --progress https://github.com/YOURLS/YOURLS "$WORKING_DIR/YOURLS"

    # Portable in-place argument for both GNU sed and Mac OSX sed
    if [[ $(uname -s) == 'Darwin' ]]; then
        local ioption='-i .bak'
    else
        local ioption='-i'
    fi

    # copy YOURLS/tests/data/config/yourls-tests-config-sample.php to YOURLS/user/config.php and edit default values
    YOURLS_CONFIG="$WORKING_DIR/YOURLS/user/config.php"
    cp "$WORKING_DIR/YOURLS/tests/data/config/yourls-tests-config-sample.php" $YOURLS_CONFIG
    sed $ioption "s:/home/you/yourls_directory:$WORKING_DIR/YOURLS:" $YOURLS_CONFIG
    sed $ioption "s/DB name for tests -- an empty one/$DB_NAME/" $YOURLS_CONFIG
    sed $ioption "s/your DB username/$DB_USER/" $YOURLS_CONFIG
    sed $ioption "s/your DB password/$DB_PASS/" $YOURLS_CONFIG
    sed $ioption "s|localhost|${DB_HOST}|" $YOURLS_CONFIG
}

install_yourls
install_db

echo "All done. Now you can run the tests with: $ phpunit -c ./$(basename $WORKING_DIR)/src/phpunit.xml"
