SET(NAME "dominant_color")


GEN_JSC_SOURCE(JSC_GEN "jsc")

SET(SRC_LIST main.c test.c calc.c ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom dentry ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )
