#!/usr/bin/env bash

# Config vars
SRC_DIR='/home/chris/AgentDVR/Media/WebServerRoot/Media/video'
TARGET_DIR='/mnt/nas/recordings'

# Find '.mkv' files
function find_files()
{
	unset transfer_list
	for dir in ./*; do
		for video_file in "$dir"/*.mkv; do
			[[ -f $video_file ]] && transfer_list+=("$video_file")
		done
	done
	count="${#transfer_list[@]}"
	[[ $count -eq 0 ]] && return 1
	export count transfer_list
	return 0
}

# Check file with ffprobe(1)
function check_file()
{
	local file="$1"
	if ! ffprobe "$file" &>/dev/null; then
		return 1
	fi
	return 0
}

# Transfer file to TARGET_DIR
function transfer_file()
{
	local file="$1"
	mkdir -p "$TARGET_DIR/$(dirname "$file")"
	if ! rsync --partial -q "$file" "$TARGET_DIR"/"$file"; then
		return 1
	fi
	rm "$file"
	return 0
}

# Main loop
cd "$SRC_DIR" || exit 1
while true; do
	if find_files; then
		i=0
		for file in "${transfer_list[@]}"; do
			((i++))
			printf 'Checking file (%s/%s)\n' "$i" "$count"
			if check_file "$file"; then
				if mountpoint -q "$TARGET_DIR"; then
					if transfer_file "$file"; then
						printf 'Transferred file ("%s")\n' "$file"
					else
						printf 'ERROR: An error occured while transfering the file "%s"\n' "$file"
					fi
				else
					printf 'ERROR: Target is not mounted!\n'
				fi
			else
				printf 'File incomplete, skipping\n'
			fi
		done
	else
		printf 'No new files found\n'
	fi
	printf 'Waiting for 60 seconds...\n'
	sleep 60
done
