cmake_minimum_required(VERSION 3.28)

project(project_name
        DESCRIPTION "Project Description")

file(GLOB SOURCES src/*.cpp)

add_executable(${PROJECT_NAME} ${SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE include)

set_target_properties(${PROJECT_NAME} PROPERTIES
        COMPILE_FLAGS "-O2"
)