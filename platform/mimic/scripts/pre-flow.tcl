# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: generateBuildID.tcl
# @brief: Generate a Build ID
# Create a build_id.vh file containing build date and git commit digest
# ==============================================================================

source ../platform/mimic/scripts/functions.tcl

generateBuildID mimic
