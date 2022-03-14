cmake_minimum_required(VERSION 3.10)

PROJECT(VTKConverter)
SET(VTK_DIR G:/VTK-9.1.0/build)

SET(CMAKE_VERBOSE_MAKEFILE ON)
find_package(VTK REQUIRED)

add_executable(VTKConverter VTKConverter)


target_link_libraries(VTKConverter glu32)
target_link_libraries(VTKConverter opengl32)
if(VTK_LIBRARIES)
target_link_libraries(VTKConverter ${VTK_LIBRARIES})
else()
target_link_libraries(VTKConverter vtkHybrid)
endif()

vtk_module_autoinit(
  TARGETS VTKConverter
  MODULES ${VTK_LIBRARIES})
