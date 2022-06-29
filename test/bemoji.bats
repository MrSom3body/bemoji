#!/usr/bin/env bash

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # make bemoji executable from anywhere relative to current testfile
    TEST_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$TEST_DIR/..:$PATH"

    # mock out interactive picker for static emoji return
    export BEMOJI_PICKER_CMD="echo ❤️"

    # set up small default set of test emoji for each test
    export BEMOJI_DB_LOCATION="$BATS_TEST_TMPDIR/database"
    export BEMOJI_CACHE_LOCATION="$BATS_TEST_TMPDIR/cache"
    mkdir -p "$BEMOJI_DB_LOCATION" "$BEMOJI_CACHE_LOCATION"
    cat "$BATS_TEST_DIRNAME/resources/test_emoji.txt" > "$BEMOJI_DB_LOCATION/emoji.txt"
}

@test "test can run script" {
    export BEMOJI_CLIP_CMD="echo clip test only"
    # closing FD3 manually to prevent hangs, see
    # https://bats-core.readthedocs.io/en/stable/writing-tests.html#file-descriptor-3-read-this-if-bats-hangs
    run bemoji 3>&-
    assert_success
}

@test "test receives custom picker mock output" {
    run bemoji -e 3>&-
    assert_output "❤️"
}

@test "-v prints correct version number" {
    the_version=$(grep 'bm_version=' $(which bemoji))

    run bemoji -v
    assert_output --partial "v${the_version#bm_version=}"
}

@test "sets XDG directory for db by default" {
    unset BEMOJI_DB_LOCATION
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/xdb-db"
    run bemoji -v
    assert_output --regexp "
database=$BATS_TEST_TMPDIR/xdb-db/bemoji
"
}

@test "sets XDG directory for cache by default" {
    unset BEMOJI_CACHE_LOCATION
    export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/xdb-cache"
    run bemoji -v
    assert_output --regexp "
history=$BATS_TEST_TMPDIR/xdb-cache/bemoji-history.txt$"
}

@test "BEMOJI_DB_LOCATION sets correct db directory" {
    run bemoji -v
    assert_output --regexp "
database=$BATS_TEST_TMPDIR/database
"
}

@test "BEMOJI_CACHE_LOCATION sets correct cache directory" {
    run bemoji -v
    assert_output --regexp "
history=$BATS_TEST_TMPDIR/cache/bemoji-history.txt$"
}
