cmake_minimum_required(VERSION 2.8.9)
project(lua_gcrypt)

set(CMAKE_BUILD_TYPE Debug)

file(GLOB LUA_GCRYPT_SOURCES "./c_src/*.c")
add_library(lua_gcrypt SHARED ${LUA_GCRYPT_SOURCES})
set_target_properties(lua_gcrypt PROPERTIES PREFIX "")

find_package(Lua REQUIRED)
include_directories(${LUA_INCLUDE_DIR})
link_directories(${LUA_LIBRARIES})
target_link_libraries(lua_gcrypt ${LUA_LIBRARIES})

target_link_libraries(lua_gcrypt gcrypt)

add_custom_command(TARGET lua_gcrypt
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy 
    $<TARGET_FILE:lua_gcrypt> 
    "${CMAKE_CURRENT_SOURCE_DIR}/lua_src/"
)
