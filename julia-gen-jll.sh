#!/bin/bash

pkgname=$1

read_soname=$(dirname "${BASH_SOURCE}")/julia-read-soname.sh

names=()
libs=()

for arg in "${@:2}"; do
    if [[ $arg =~ (.*)=(.*) ]]; then
        name=${BASH_REMATCH[1]}
        lib=${BASH_REMATCH[2]}
    else
        name=$arg
        lib=$arg
    fi
    case "$lib" in
        /*)
            if [ -f "$lib" ]; then
                :
            elif [ -f "$lib.so" ]; then
                lib="$lib.so"
            else
                echo "Cannot find library $lib"
                exit 1
            fi
            ;;
        *)
            if [ -f "/usr/lib/$lib" ]; then
                lib="/usr/lib/$lib"
            elif [ -f "/usr/lib/lib$lib" ]; then
                lib="/usr/lib/lib$lib"
            elif [ -f "/usr/lib/$lib.so" ]; then
                lib="/usr/lib/$lib.so"
            elif [ -f "/usr/lib/lib$lib.so" ]; then
                lib="/usr/lib/lib$lib.so"
            else
                echo "Cannot find library $lib"
                exit 1
            fi
            ;;
    esac
    lib=$($read_soname "$lib")
    names=("${names[@]}" "$name")
    libs=("${libs[@]}" "$lib")
done

gen_file() {
    echo "module $pkgname"
    echo -n "export "
    (IFS=','; echo "${names[*]}")
    echo "const PATH_list = String[]"
    echo "const LIBPATH_list = String[]"
    for ((i = 0; i < ${#names[@]}; i++)); do
        echo "const ${names[i]} = \"${libs[i]}\""
    done
    echo "end"
}

gen_file > src/$pkgname.jl
rm -rf src/wrappers/ >& /dev/null
rm Artifacts.toml >& /dev/null
