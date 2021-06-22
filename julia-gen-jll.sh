#!/bin/bash

pkgname=$1

read_soname=$(dirname "${BASH_SOURCE}")/julia-read-soname.sh

libnames=()
libs=()
binnames=()
bins=()

isbin=0
hasextra=

if [[ $2 = "-e" ]]; then
    hasextra=$3
    shift 2
fi

for arg in "${@:2}"; do
    if [[ $arg =~ (.*)=(.*) ]]; then
        name=${BASH_REMATCH[1]}
        lib=${BASH_REMATCH[2]}
    else
        name=$arg
        lib=$arg
    fi
    case "$lib" in
        -b)
            isbin=1
            continue
            ;;
        /*)
            if [ -f "$lib" ]; then
                :
            elif [ -f "$lib.so" ]; then
                lib="$lib.so"
            elif ((isbin)); then
                echo "Cannot find binary $lib"
                exit 1
            else
                echo "Cannot find library $lib"
                exit 1
            fi
            ;;
        *)
            if ((isbin)); then
                if ! lib=$(which "$lib" 2> /dev/null); then
                    echo "Cannot find binary $lib"
                    exit 1
                fi
            else
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
                soname=$($read_soname "$lib")
                if [[ -n $soname ]]; then
                    lib=$soname
                fi
            fi
            ;;
    esac
    if ((isbin)); then
        isbin=0
        binnames=("${binnames[@]}" "$name")
        bins=("${bins[@]}" "$lib")
    else
        libnames=("${libnames[@]}" "$name")
        libs=("${libs[@]}" "$lib")
    fi
done

names=("${libnames[@]}" "${binnames[@]}")

gen_file() {
    echo "module $pkgname"
    echo -n "export "
    (IFS=','; echo "${names[*]}")
    echo "const PATH_list = String[]"
    echo "const LIBPATH_list = String[]"
    for ((i = 0; i < ${#libnames[@]}; i++)); do
        echo "const ${libnames[i]} = \"${libs[i]}\""
    done
    for ((i = 0; i < ${#binnames[@]}; i++)); do
        echo "${binnames[i]}(f::Function; kw...) = f(\"${bins[i]}\")"
    done
    if [[ -n $hasextra ]]; then
        if [[ $hasextra = - ]]; then
            hasextra=/dev/stdin
        fi
        cat "$hasextra"
    fi
    echo "end"
}

gen_file > src/$pkgname.jl
rm -rf src/wrappers/ >& /dev/null
rm Artifacts.toml >& /dev/null
