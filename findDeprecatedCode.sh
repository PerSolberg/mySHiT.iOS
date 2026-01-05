#!/bin/ksh
find . -name "*.swift" -exec grep -nHE "(^ {0,2}//)|/\*[^ ]*\*/" {} \; | grep -vE "\.swift:1?[0-9]:"
