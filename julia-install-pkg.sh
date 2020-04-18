#!/bin/bash

jlname=$1
pkgdir=$2
pkgname=$3

site_dir=$(julia --startup-file=no -e "print(Sys.STDLIB)")
dest_dir="${pkgdir}/${site_dir}/${jlname}/"

install -dm755 "${dest_dir}"
# This should ignore the .* files automatically
for f in *; do
    case "$f" in
        LICENSE*)
            cp -a "$f" "${dest_dir}"
            install -dm755 "${pkgdir}/usr/share/licenses/$pkgname/"
            ln -sf "../../../..${site_dir}/${jlname}/$f" \
               "${pkgdir}/usr/share/licenses/$pkgname/"
            ;;
        appveyor.yml)
            true
            ;;
        *)
            cp -a "$f" "${dest_dir}"
            ;;
    esac
done
rm -rf "${dest_dir}/deps/"build.jl

ver=$(julia --startup-file=no \
            -e 'print(VERSION.major, ".", VERSION.minor, ".", VERSION.patch)')
depends+=("julia=2:$ver")
