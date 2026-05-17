cmake_minimum_required(VERSION 3.16)

project(arma_attendance_extension VERSION 0.1.0 LANGUAGES CXX)

include(CTest)

option(AASE_STATIC_GNU_RUNTIME "Statically link GNU C++ runtime into Linux extension builds" ON)

find_package(CURL REQUIRED)

add_library(arma_attendance_core STATIC
    src/commands.cpp
    src/config.cpp
    src/http_client.cpp
)

target_include_directories(arma_attendance_core
    PUBLIC
        include
)

target_link_libraries(arma_attendance_core
    PUBLIC
        CURL::libcurl
        ${CMAKE_DL_LIBS}
)

target_compile_features(arma_attendance_core PUBLIC cxx_std_20)
set_target_properties(arma_attendance_core PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_library(arma_attendance SHARED
    src/extension_exports.cpp
)

target_link_libraries(arma_attendance PRIVATE arma_attendance_core)
target_compile_features(arma_attendance PRIVATE cxx_std_20)
set_target_properties(arma_attendance PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED YES
    POSITION_INDEPENDENT_CODE ON
)

if(AASE_STATIC_GNU_RUNTIME AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_link_options(arma_attendance PRIVATE -static-libstdc++ -static-libgcc)
endif()

if(WIN32)
    set_target_properties(arma_attendance PROPERTIES
        PREFIX ""
        OUTPUT_NAME "arma_attendance_x64"
        SUFFIX ".dll"
    )
else()
    set_target_properties(arma_attendance PROPERTIES
        PREFIX ""
        OUTPUT_NAME "arma_attendance"
        SUFFIX ".so"
    )

    add_custom_command(TARGET arma_attendance POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:arma_attendance>"
            "$<TARGET_FILE_DIR:arma_attendance>/arma_attendance_x64.so"
        COMMENT "Copying Linux x64 Arma extension alias"
    )
endif()

if(BUILD_TESTING)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)

    add_executable(arma_attendance_smoke tests/smoke_main.cpp)
    target_link_libraries(arma_attendance_smoke PRIVATE arma_attendance_core)
    target_compile_features(arma_attendance_smoke PRIVATE cxx_std_20)

    add_test(
        NAME extension_contract_smoke
        COMMAND
            ${Python3_EXECUTABLE}
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/run_contract_smoke.py
            $<TARGET_FILE:arma_attendance_smoke>
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/mock_api_server.py
    )
endif()
