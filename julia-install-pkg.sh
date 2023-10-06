#!/bin/bash

jlname=$1
pkgdir=$2
pkgname=$3
julia_ver=${4:-julia}

if [[ -n $JULIA_INSTALL_SRCPKG ]]; then
    site_dir=/usr/share/julia/arch-site
else
    site_dir=$(julia --startup-file=no -e "print(Sys.STDLIB)")
fi
dest_dir="${pkgdir}/${site_dir}/${jlname}/"

install -dm755 "${dest_dir}"
found_project_toml=0
# This should ignore the .* files automatically
for f in *; do
    case "$f" in
        LICENSE*|License*)
            cp -a "$f" "${dest_dir}"
            install -dm755 "${pkgdir}/usr/share/licenses/$pkgname/"
            ln -sf "../../../..${site_dir}/${jlname}/$f" \
               "${pkgdir}/usr/share/licenses/$pkgname/"
            ;;
        appveyor.yml)
            true
            ;;
        Project.toml)
            # Strip out these two dependencies by default since we shouldn't really need them
            # If there's really a need we'll add a flag to override this.
            sed -i -e '/^JLLWrapper/d' -e '/^BinaryProvider/d' Project.toml
            cp -a Project.toml "${dest_dir}"
            found_project_toml=1
            ;;
        *)
            cp -a "$f" "${dest_dir}"
            ;;
    esac
done
rm -rf "${dest_dir}/deps/"build.jl

if [[ $found_project_toml = 0 ]]; then
    echo "Cannot find Project.toml" && false
    return 1
fi

if [[ -z $JULIA_INSTALL_SRCPKG ]] && [[ -z $JULIA_INSTALL_FORCE_VERSION_DEP ]]; then
    ver1=$(julia --startup-file=no \
                 -e 'print(VERSION.major, ".", VERSION.minor)')
    ver2=$(julia --startup-file=no \
                 -e 'print(VERSION.major, ".", VERSION.minor + 1)')
    depends+=("julia>=2:$ver1" "julia<2:$ver2")
fi

if [[ -n $JULIA_INSTALL_SRCPKG ]]; then
    _deps_suffix=-src
else
    _deps_suffix=
fi

for deps in $(julia "$(dirname ${BASH_SOURCE})/julia-list-deps.jl" .); do
    depends+=("${julia_ver}-${deps,,}${_deps_suffix}")
done

if [[ -n $JULIA_INSTALL_SRCPKG ]] && [[ -z $JULIA_INSTALL_SKIP_TIMESTAMP_FIX ]]; then
    install=.pkg-${jlname,,}.install
    (cd "${pkgdir}"

     "$(dirname ${BASH_SOURCE})/julia-gen-timestamp-fix.sh" "${site_dir##/}/${jlname}/"

     echo "post_install() {"
     echo "  timestamps-fix"
     echo "}"

     echo "post_upgrade() {"
     echo "  timestamps-fix"
     echo "}"
    ) > "${startdir}/$install"
fi
