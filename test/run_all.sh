#!/usr/bin/env bash

env -i TERM="${TERM}" PATH="${PATH}" bash -c "bats ./test/*.bats"

rm -f nohup.out
