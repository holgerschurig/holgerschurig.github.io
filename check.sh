#!/bin/sh
rg EXPORT_FILE_NAME |grep -Fv .md
find -name "*.org" | xargs grep -n 'relref([^,]*)'
hugo

