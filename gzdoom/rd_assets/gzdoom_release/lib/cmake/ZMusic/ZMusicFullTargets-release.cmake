#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "ZMusic::zmusic" for configuration "Release"
set_property(TARGET ZMusic::zmusic APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ZMusic::zmusic PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libzmusic.so.1.3.0"
  IMPORTED_SONAME_RELEASE "libzmusic.so.1"
  )

list(APPEND _cmake_import_check_targets ZMusic::zmusic )
list(APPEND _cmake_import_check_files_for_ZMusic::zmusic "${_IMPORT_PREFIX}/lib/libzmusic.so.1.3.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
