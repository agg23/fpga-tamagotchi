# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: functions.tcl
# @brief: Collection of TCL Functions for the Framework
# ==============================================================================

# @brief: Get the current date in the format YYYYMMDD
# (see: https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/quartus/tcl-date-time-stamp.html)
proc getDate {} {
    set buildDate [ clock format [ clock seconds ] -format %Y%m%d ]
    return $buildDate
}

# @brief: Get the current time in the format HHMMSS
proc getTime {} {
    set buildTime [ clock format [ clock seconds ] -format %H%M%S ]
    return $buildTime
}

# @brief: Get the git hashtag for this project
proc getDigest {} {
    set buildHash ""
    if {[catch {exec git rev-parse --short=8 HEAD}]} {
        puts "No git version control in the project"
        set buildHash FEEDC0DE
    } else {
        set buildHash [exec git rev-parse --short=8 HEAD]
    }
    return $buildHash
}

# @brief: Creates a folder if it doesn't already exist
proc createFolder {folder_path} {
    if {![file isdirectory $folder_path]} {
        file mkdir $folder_path
    }
}

# @brief: Copies the input file to the output file
proc copyFile {input_path output_path} {
    # Open the input file for reading
    set input_file [open $input_path "r"]
    # Open the output file for writing
    set output_file [open $output_path "w"]
    # Copy the contents of the input file to the output file
    puts $output_file [read $input_file]
    # Close the input and output files
    close $input_file
    close $output_file
}

# @brief: Generate a Build ID
# Create a build_id.vh file containing build date and git commit digest
proc generateBuildID {target} {
    # Set the metadata for this project
    set buildDate [getDate]
    set buildHash [getDigest]

    # Create a Verilog file for output
    set outputFileName "../target/$target/build_id.vh"
    set outputFile [open $outputFileName "w"]

    # Output the Verilog source
    puts $outputFile "// Build ID Verilog Module"
    puts $outputFile "`define BUILD_DATE \"$buildDate\""
    puts $outputFile "`define BUILD_HASH \"$buildHash\""
    close $outputFile

    # Send confirmation message to the Messages window
    post_message "Core build date/time generated: [pwd]/$outputFileName"
    post_message "Date: $buildDate"
    post_message "Hash: $buildHash"
}

# @brief: Generate a JTAG Chain Description File.
# Create a .cdf file to be used with Quartus Prime Programmer
proc generateCDF {revision device outpath project_name use_hps} {
    set outputFileName "$project_name.cdf"
    set outputFile [open $outputFileName "w"]

    puts $outputFile "JedecChain;"
    puts $outputFile "  FileRevision(JESD32A);"
    puts $outputFile "  DefaultMfr(6E);"
    puts $outputFile ""
    if {$use_hps} {
        puts $outputFile "  P ActionCode(Ign)"
        puts $outputFile "    Device PartName(SOCVHPS) MfrSpec(OpMask(0));"
    }
    puts $outputFile "  P ActionCode(Cfg)"
    puts $outputFile "    Device PartName($device) Path(\"$outpath/\") File(\"$revision.sof\") MfrSpec(OpMask(1));"
    puts $outputFile "ChainEnd;"
    puts $outputFile ""
    puts $outputFile "AlteraBegin;"
    puts $outputFile "  ChainType(JTAG);"
    puts $outputFile "AlteraEnd;"
}

