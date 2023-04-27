# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: generateCDF.tcl
# @brief: Generate a JTAG Chain Description File.
# Create a .cdf file to be used with Quartus Prime Programmer
# ==============================================================================

source ../platform/mimic/scripts/functions.tcl

set project_name [lindex $quartus(args) 1]
set revision [lindex $quartus(args) 2]

if {[project_exists $project_name]} {
    if {[string equal "" $revision]} {
        project_open $project_name -revision [get_current_revision $project_name]
    } else {
        project_open $project_name -revision $revision
    }
} else {
    post_message -type error "Project $project_name does not exist"
    exit
}

set device  [get_global_assignment -name DEVICE]
set outpath [get_global_assignment -name PROJECT_OUTPUT_DIRECTORY]
set device_hps [get_parameter -name MIMIC_DEVICE_HAS_SOC]

if {$device_hps eq "ON"} {
    set use_hps 1
} else {
    set use_hps 0
}

if [is_project_open] {
    project_close
}

generateCDF $revision $device $outpath $project_name $use_hps
