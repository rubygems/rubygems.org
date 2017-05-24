#!/bin/bash

echo '**************'
echo './script/setup'
./script/setup

echo '*****************'
echo 'Running toxiproxy'
echo 'Press Ctrl-C to stop'
echo '********************'
toxiproxy
