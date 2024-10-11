# Specify the minimum version for CMake
cmake_minimum_required(VERSION <min>[...<policy_max>] [FATAL_ERROR])

cmake_minimum_required(VERSION 3.14)
cmake_minimum_required(VERSION 3.15...3.20)
cmake_minimum_required(VERSION 3.15...3.20 FATAL_ERROR)

# Set the project name and version
project(<PROJECT-NAME> [<language-name>...])
project(<PROJECT-NAME>
        [VERSION <major>[.<minor>[.<patch>[.<tweak>]]]]
        [DESCRIPTION <project-description-string>]
        [HOMEPAGE_URL <url-string>]
        [LANGUAGES <language-name>...])

project(MyProject
        VERSION 1.0.2.0
        DESCRIPTION "An example CMake project"
        HOMEPAGE_URL "https://example.com/myproject"
        LANGUAGES CXX C)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Enable folders in IDE projects like Visual Studio or Xcode
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Define project options
option(BUILD_TESTS "Enable building tests" ON)
option(BUILD_DOCS "Enable building documentation" OFF)

# Set global project settings (e.g., output directories)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Set custom paths for includes or libraries
set(EXTERNAL_LIB_DIR ${CMAKE_SOURCE_DIR}/external)

# Include custom modules or external dependencies
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules")

# Add dependencies (e.g., Boost, GoogleTest)
find_package(Boost REQUIRED COMPONENTS system filesystem)
find_package(GTest REQUIRED)

# Add global include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# External libraries and directories
include_directories(${EXTERNAL_LIB_DIR}/some_library/include)
link_directories(${EXTERNAL_LIB_DIR}/some_library/lib)

# Add custom compiler flags (example for GCC)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Platform-specific settings (example for Windows)
if(WIN32)
    add_definitions(-DWIN32)
endif()

# Define sources, headers, and other files
set(SOURCES
    src/main.cpp
    src/utils.cpp
    src/manager.cpp
)

set(HEADERS
    include/utils.h
    include/manager.h
)

# Add executable or library (for large projects, use subdirectories)
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Link libraries (Boost, custom, etc.)
target_link_libraries(${PROJECT_NAME} Boost::system Boost::filesystem)

# Add project subdirectories (e.g., for modular code)
add_subdirectory(src/module1)
add_subdirectory(src/module2)

# Unit testing setup
if(BUILD_TESTS)
    enable_testing()

    # Add test executable
    add_executable(runTests tests/test_main.cpp tests/test_module1.cpp)

    # Link with GTest and the project libraries
    target_link_libraries(runTests GTest::GTest GTest::Main ${PROJECT_NAME})

    # Define test cases
    add_test(NAME test_all COMMAND runTests)
endif()

# Documentation (optional, if building with Doxygen)
if(BUILD_DOCS)
    find_package(Doxygen)
    if(DOXYGEN_FOUND)
        set(DOXYGEN_IN ${CMAKE_SOURCE_DIR}/docs/Doxyfile)
        set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/docs)

        add_custom_target(docs
            COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_IN}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Generating API documentation with Doxygen" VERBATIM
        )
    endif()
endif()

# Packaging setup (optional)
include(CPack)
set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
