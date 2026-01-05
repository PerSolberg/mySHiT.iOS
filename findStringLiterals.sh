#!/bin/ksh
find . -name "*.swift" -exec grep -nHE "\"[^\"]*\"" {} \; | grep -vE "\.swift(:[0-9]+)?:[ \t]*(os_log|//|fatalError|assert|NSLog|case +[a-zA-Z0-9_]+ *=|static let)" | sed 's/""/<EMPTY>/g' | grep "\""
