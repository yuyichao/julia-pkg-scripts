#!/usr/bin/julia

using Pkg.TOML
using Base.Filesystem

if length(ARGS) == 2
    const pkgname = ARGS[1]
    const config_file = ARGS[2]
    const pkgdir = pwd()
elseif length(ARGS) == 3
    const pkgname = ARGS[1]
    const config_file = ARGS[2]
    const pkgdir = ARGS[3]
else
    @error "Wrong number of arguments for julia-gen-jll.jl, require 2 or 3, got $(length(ARGS))"
    exit(1)
end

const PATHs = split(get(ENV, "PATH", "/usr/bin:/bin"), ":", keepempty=false)

const read_soname = joinpath(@__DIR__, "julia-read-soname.sh")

@info "Generating JLL package $(pkgname) in $(pkgdir) based on $(config_file)"
if !isfile(config_file)
    @error "Config file does not exist"
    exit(1)p
end
const config = TOML.parsefile(config_file)
jlpath = joinpath(pkgdir, "src")
if !isdir(jlpath)
    mkpath(jlpath)
end

function check_library(name, options)
    for path in options
        isfile(path) && return path
    end
    @error "Cannot find library $(name)"
    exit(1)
end

function check_binary(name, options)
    for path in options
        if !isfile(path)
            continue
        end
        if stat(path).mode & 0o111 != 0
            return path
        end
    end
    @error "Cannot find binary $(name)"
    exit(1)
end

function check_file(name, options)
    for path in options
        if !ispath(path) # ironically, file isn't required to be a file
            continue
        end
        return path
    end
    @error "Cannot find file $(name)"
    exit(1)
end

open(joinpath(jlpath, "$(pkgname).jl"), "w") do fh
    global_config = get(config, "global", Dict{String,Any}())
    println(fh, "module $(pkgname)")
    println(fh, "using Libdl")
    for dep in get(config, "depends", [])
        println(fh, "using $(dep)")
    end
    available = get(global_config, "available", true)
    println(fh, "is_available() = $(available ? "true" : "false")")
    println(fh, "find_artifact_dir() = \"/usr\"")
    println(fh, "artifact_dir = \"/usr\"")
    println(fh, "const PATH_list = String[]")
    println(fh, "const LIBPATH_list = String[]")
    println(fh, "const PATH = Ref(\"\")")
    println(fh, "const LIBPATH = Ref(\"\")")
    println(fh, "const LIBPATH_env = \"LD_LIBRARY_PATH\"")
    init_func = IOBuffer()
    for lib in get(config, "library", [])
        name = lib["name"]
        file = get(lib, "file", name)
        if file[1] == '/'
            # Full path
            path = check_library(file, (file, file * ".so"))
        elseif '/' in file
            # Relative path
            path = check_library(file, (joinpath("/usr/lib", file),
                                        joinpath("/usr/lib", file * ".so")))
        else
            path = check_library(file, (joinpath("/usr/lib", file),
                                        joinpath("/usr/lib", file * ".so"),
                                        joinpath("/usr/lib", "lib" * file),
                                        joinpath("/usr/lib", "lib" * file * ".so")))
        end
        use_soname = get(lib, "use_soname", true)
        dir = dirname(path)
        soname = use_soname ? strip(read(`$read_soname $path`, String)) : ""
        if !isempty(soname) && isfile(joinpath(dir, soname))
            path = joinpath(dir, soname)
            file = soname
        else
            file = basename(path)
        end
        println(fh, "export $(name)")
        println(fh, "const $(name)_path = $(repr(path))")
        println(fh, "$(name)_handle = C_NULL")
        if dir == "/usr/lib" || dir == "/usr/local/lib" || dir == "/usr/lib/julia"
            println(fh, "const $(name) = $(repr(file))")
        else
            println(fh, "const $(name) = $(repr(path))")
        end
        if get(lib, "dlopen_global", false)
            println(init_func, "    global $(name)_handle = dlopen($(name)_path, RTLD_LAZY | RTLD_DEEPBIND | RTLD_GLOBAL)")
        else
            println(init_func, "    global $(name)_handle = dlopen($(name)_path)")
        end
    end
    for bin in get(config, "binary", [])
        name = bin["name"]
        file = get(bin, "file", name)
        if file[1] == '/'
            # Full path
            path = check_binary(file, (file,))
        else
            path = check_binary(file, [joinpath(P, file) for P in PATHs])
        end
        println(fh, "export $(name)")
        println(fh, "const $(name)_path = $(repr(path))")
        println(fh, "$(name)(f::Function; kw...) = f($(name)_path)")
    end
    for f in get(config, "file", [])
        name = f["name"]
        file = get(f, "file", name)
        if get(f, "literal", false)
            path = file
        elseif file[1] == '/'
            # Full path
            path = check_file(file, (file,))
        else # Assume searching in PATH for now
            path = check_file(file, [joinpath(P, file) for P in PATHs])
        end
        println(fh, "export $(name)")
        println(fh, "const $(name)_path = $(repr(path))")
        println(fh, "const $(name) = $(name)_path")
        println(fh, "get_$(name)() = $(name)_path")
    end
    init_body = String(take!(init_func))
    if !isempty(init_body)
        println(fh, "function __init__()")
        write(fh, init_body)
        println(fh, "end")
    end
    println(fh, "end")
end

rm(joinpath(pkgdir, "src/wrappers"), recursive=true, force=true)
rm(joinpath(pkgdir, "Artifacts.toml"), recursive=true, force=true)
