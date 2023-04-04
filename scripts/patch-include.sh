#!/bin/bash

filename="~/klipper/klippy/configfile.py"
search="glob\.glob\(include_glob\)"
replace="glob.glob(include_glob, recursive=True)"

grep -q $search $filename &&
    sed -i "s/$search/$replace/" $filename &&
    echo RESTART > /tmp/printer
