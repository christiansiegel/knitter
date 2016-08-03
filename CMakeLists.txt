cmake_minimum_required(VERSION 2.8)
project( knitter )

if( UNIX )
    SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=gnu++0x" )
endif()

find_package( OpenCV REQUIRED )
add_executable( knitter knitter.cpp )
target_link_libraries( knitter ${OpenCV_LIBS} )
