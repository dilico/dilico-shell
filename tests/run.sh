#!/bin/sh
# Runs the offscreen QML tests in this directory. Only components/, config/
# and utils/ load here; services and windows need the qs binary, so they are
# checked in the running shell instead. Extra arguments go to qmltestrunner,
# e.g. -functions to list the tests.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
runner=$(command -v qmltestrunner || echo /usr/lib/qt6/bin/qmltestrunner)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# A qs module tree like the one Quickshell synthesizes (conventions §3): one
# qmldir per directory, singletons known by their pragma. It is thrown away
# afterwards; the config itself never holds a qmldir.
for dir in components config utils; do
    mkdir -p "$work/qs/$dir"
    printf 'module qs.%s\n' "$dir" > "$work/qs/$dir/qmldir"
    for file in "$root/$dir"/[A-Z]*.qml; do
        name=$(basename "$file" .qml)
        ln -s "$file" "$work/qs/$dir/$name.qml"
        if grep -q '^pragma Singleton' "$file"; then
            echo "singleton $name 1.0 $name.qml"
        else
            echo "$name 1.0 $name.qml"
        fi >> "$work/qs/$dir/qmldir"
    done
done

# Quickshell's plugin only loads inside qs. Those three directories use one
# thing from it, Singleton, and only for properties and functions.
mkdir -p "$work/Quickshell"
printf 'module Quickshell\nSingleton 1.0 Singleton.qml\n' > "$work/Quickshell/qmldir"
cat > "$work/Quickshell/Singleton.qml" <<'QML'
import QtQuick

QtObject {
    default property list<QtObject> data
}
QML

QT_QPA_PLATFORM=offscreen "$runner" -import "$work" -input "$root/tests" "$@"
