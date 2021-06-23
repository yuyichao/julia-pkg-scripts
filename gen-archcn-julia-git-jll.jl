#!/usr/bin/julia

jlname = ARGS[1]
archname = lowercase(jlname)

mkpath("julia-git-$(archname)-git")

open("julia-git-$(archname)-git/PKGBUILD", "w") do fh
    write(fh, """
pkgname=julia-git-$(archname)-git
pkgver=0
pkgrel=1
pkgdesc="$(jlname).jl"
url="https://github.com/JuliaBinaryWrappers/$(jlname).jl"
arch=('any')
license=('MIT')
makedepends=(git julia-pkg-scripts)
depends=(julia-git)
provides=(julia-git-$(archname))
source=(git://github.com/JuliaBinaryWrappers/$(jlname).jl
        jll.toml)
md5sums=('SKIP')

pkgver() {
  cd $(jlname).jl

  git describe --tags | sed -e 's/^[^0-9]*//' -e 's/-/.0./' -e 's/-/./g'
}

build() {
  cd $(jlname).jl

  julia /usr/lib/julia/julia-gen-jll.jl $(jlname) ../jll.toml
}

package() {
  cd $(jlname).jl

  . /usr/lib/julia/julia-install-pkg.sh $(jlname) "\${pkgdir}" "\${pkgname}" julia-git
}
""")
end

open("julia-git-$(archname)-git/jll.toml", "w") do fh
end

if length(ARGS) >= 2 && !isempty(ARGS[2])
    maintainer = ARGS[2]
    open("julia-git-$(archname)-git/lilac.yaml", "w") do fh
        write(fh, """
maintainers:
  - github: $(maintainer)

build_prefix: extra-x86_64

pre_build: vcs_update
post_build: git_pkgbuild_commit

repo_depends:
  - julia-git
  - openspecfun-git
  - openblas-lapack-git: openblas-git
  - openblas-lapack-git
  - libutf8proc-git
  - openlibm-git
  - llvm-julia: llvm-libs-julia
  - libgit2-julia
  - julia-pkg-scripts

update_on:
  - source: vcs
  - alias: alpm-lilac
    alpm: julia-git
    from_pattern: ^(\\d+\\.\\d+).*
    to_pattern: \\1
  - source: manual
    manual: 1
""")
    end
end
