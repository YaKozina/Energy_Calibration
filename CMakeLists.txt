cmake_minimum_required(VERSION 3.3)

project(CalibrationScript)

include_directories(${Bayeux_INCLUDE_DIRS})

add_subdirectory(EnergyCorrectionCalculator)
add_subdirectory(Charge2EnergyModule)
