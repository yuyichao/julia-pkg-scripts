project(julia-pkg-scripts)

## Setup
cmake_minimum_required(VERSION 3.0)
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}"
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(GNUInstallDirs)

install(FILES julia-read-soname.sh julia-gen-timestamp-fix.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
  WORLD_READ WORLD_EXECUTE
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/julia/")

install(FILES julia-install-pkg.sh julia-list-deps.jl julia-gen-jll.jl
  PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/julia/")
