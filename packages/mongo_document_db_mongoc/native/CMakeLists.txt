cmake_minimum_required(VERSION 3.18)
project(mongo_document_db_mongoc C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_library(mongo_document_db_mongoc SHARED
  src/mongo_document_db_mongoc.c
)

target_include_directories(mongo_document_db_mongoc PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set(MDD_MONGOC_TARGET "")

# Prefer CMake config packages (works well with vcpkg on Windows).
foreach(_pkg libmongoc-1.0 mongoc-1.0 mongoc mongo-c-driver)
  if(NOT MDD_MONGOC_TARGET)
    find_package(${_pkg} CONFIG QUIET)
  endif()
endforeach()

if(TARGET mongo::mongoc_shared)
  set(MDD_MONGOC_TARGET mongo::mongoc_shared)
elseif(TARGET mongo::mongoc_static)
  set(MDD_MONGOC_TARGET mongo::mongoc_static)
elseif(TARGET mongoc::mongoc_shared)
  set(MDD_MONGOC_TARGET mongoc::mongoc_shared)
elseif(TARGET mongoc::mongoc_static)
  set(MDD_MONGOC_TARGET mongoc::mongoc_static)
elseif(TARGET libmongoc-1.0::libmongoc-1.0)
  set(MDD_MONGOC_TARGET libmongoc-1.0::libmongoc-1.0)
elseif(TARGET mongoc-1.0::mongoc-1.0)
  set(MDD_MONGOC_TARGET mongoc-1.0::mongoc-1.0)
endif()

if(NOT MDD_MONGOC_TARGET)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(LIBMONGOC REQUIRED IMPORTED_TARGET libmongoc-1.0)
  set(MDD_MONGOC_TARGET PkgConfig::LIBMONGOC)
endif()

target_link_libraries(mongo_document_db_mongoc PRIVATE ${MDD_MONGOC_TARGET})

# Make it easy to ship dependent shared libs in the same directory.
if(APPLE)
  set_target_properties(mongo_document_db_mongoc PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "@loader_path"
  )
elseif(UNIX)
  set_target_properties(mongo_document_db_mongoc PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN"
  )
endif()
