#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "SndFile::sndfile" for configuration ""
set_property(TARGET SndFile::sndfile APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(SndFile::sndfile PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "C"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libsndfile.a"
  )

list(APPEND _cmake_import_check_targets SndFile::sndfile )
list(APPEND _cmake_import_check_files_for_SndFile::sndfile "${_IMPORT_PREFIX}/lib/libsndfile.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
