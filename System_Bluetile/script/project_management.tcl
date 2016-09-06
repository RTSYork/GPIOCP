proc ::bs::find_root_dir {} {
	variable rootdir
	return $rootdir
}

proc ::bs::create_project {name partno} {

	file mkdir $name
	cd $name

	set project [::create_project -part $partno $name]

	set rootdir [bs::find_root_dir]

	puts "ROOT: $rootdir"
	puts [info script]

	# Also create the relevant boilerplate
	# Need to create the top level filesets if they don't already exist
	if {[get_filesets -quiet sources_1] == ""} {
		create_fileset -srcset sources_1
	}

	if {[get_filesets -quiet constrs_1] == ""} {
		create_fileset -constrset constrs_1
	}

	# Add in the IP repo
	set_property IP_REPO_PATHS $rootdir $project
	update_ip_catalog

	# Set up runs
	current_run -synthesis [get_runs synth_1]
	current_run -implementation [get_runs impl_1]

	return $project
}

proc ::bs::create_project_with_board {name boardname} {
	# Try and find the board first
	set searchStr ".*$boardname:.*"
	set boards [get_board_parts -regexp -latest_hw_revision	 -latest_file_version -nocase $searchStr]

	if {[llength $boards] != 1} {
		if {[llength $boards] == 0)} {
			puts "ERROR: Unknown board $boardname"
		} else {
			puts "ERROR: $boardname matches more than one board. Make your search more specific."
		}

		puts "Available boards: [get_board_parts -latest_hw_version -latest_file_version]"
		return TCL_ERROR
	}

	# Get the board part
	set part [get_property PART_NAME $boards]

	# Make the create_project
	set project [bs::create_project $name $part]

	# And apply the board name
	set_property BOARD_PART $boards $project
}
