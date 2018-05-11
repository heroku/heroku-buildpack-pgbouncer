#!/usr/bin/env bash

env -i TERM=$TERM bash -c "bats ./test/*.bats"
