#!/usr/bin/julia

using Pkg

function get_deps(pkgdir)
    try
        projfile = joinpath(pkgdir, "Project.toml")
        isfile(projfile) &&
            return String[dep for (dep, id) in Pkg.Types.read_project(projfile).deps]
    catch
    end
    try
        reqfile = joinpath(pkgdir, "REQUIRE")
        if isfile(reqfile)
            res = String[]
            for line in readlines(reqfile)
                line = strip(line)
                if isempty(line) || startswith(line, '#')
                    continue
                end
                pkg = split(split(line)[1], "#")[1]
                if !isempty(pkg) && pkg != "julia"
                    push!(res, pkg)
                end
            end
            return res
        end
    catch
    end
    return String[]
end

for pkg in get_deps(ARGS[1])
    println(pkg)
end
