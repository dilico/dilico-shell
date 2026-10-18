#!/bin/sh
# Runs the offscreen QML tests in this directory. components/, config/, utils/
# and the island's own widgets load here; services need the qs binary, so
# tests/fakes/services stands in for them, and windows are checked in the
# running shell instead. Extra arguments go to qmltestrunner, e.g. -functions
# to list the tests.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
runner=$(command -v qmltestrunner || echo /usr/lib/qt6/bin/qmltestrunner)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# A qs module tree like the one Quickshell synthesizes (conventions §3): one
# qmldir per directory, singletons known by their pragma. It is thrown away
# afterwards; the config itself never holds a qmldir.
module() {
    dir=$1 source=$2
    mkdir -p "$work/qs/$dir"
    printf 'module qs.%s\n' "$(echo "$dir" | tr / .)" > "$work/qs/$dir/qmldir"
    for file in "$source"/[A-Z]*.qml; do
        name=$(basename "$file" .qml)
        ln -s "$file" "$work/qs/$dir/$name.qml"
        if grep -q '^pragma Singleton' "$file"; then
            echo "singleton $name 1.0 $name.qml"
        else
            echo "$name 1.0 $name.qml"
        fi >> "$work/qs/$dir/qmldir"
    done
}

for dir in components config utils modules/island/components modules/island/panels; do
    module "$dir" "$root/$dir"
done
module services "$root/tests/fakes/services"

# Quickshell's plugin only loads inside qs. What loads here uses two things
# from it: Singleton, only for properties and functions, and ScriptModel,
# which here rebuilds its rows rather than keeping them across a change.
mkdir -p "$work/Quickshell"
printf 'module Quickshell\nSingleton 1.0 Singleton.qml\nScriptModel 1.0 ScriptModel.qml\n' > "$work/Quickshell/qmldir"
cat > "$work/Quickshell/Singleton.qml" <<'QML'
import QtQuick

QtObject {
    default property list<QtObject> data
}
QML
cat > "$work/Quickshell/ScriptModel.qml" <<'QML'
import QtQuick

ListModel {
    property var values: []

    dynamicRoles: true
    onValuesChanged: {
        clear();
        for (const value of values)
            append({ modelData: value });
    }
}
QML

QT_QPA_PLATFORM=offscreen "$runner" -import "$work" -input "$root/tests" "$@"
