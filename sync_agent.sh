#!/usr/bin/env bash

# Config vars
SRC_DIR='/home/chris/AgentDVR/Media/WebServerRoot/Media/video'
MOUNT_DIR='/mnt/Saturn'
TARGET_DIR="$MOUNT_DIR/recordings"

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
	if [[ $count -eq 0 ]]; then
		return 1
	fi
	export count transfer_list
	return 0
}

# Check file with ffprobe(1)
function check_file()
{
	local file="$1"
	if ! ffprobe "$file" &>/dev/null; then
		return 5  # EIO
	fi
	return 0
}

# Transfer file to TARGET_DIR
function transfer_file()
{
	local file="$1"
	mkdir -p "$TARGET_DIR/$(dirname "$file")"
	if ! rsync --partial -q "$file" "$TARGET_DIR"/"$file"; then
		return 5  # EIO
	fi
	rm "$file"
	return 0
}

# Main loop
if ! cd "$SRC_DIR"; then
	exit 2  # ENOENT
fi

while true; do
	if ! mountpoint -q "$MOUNT_DIR"; then
		if ! mount "$MOUNT_DIR"; then
			printf 'Error mounting "%s"\n' "$MOUNT_DIR"
			exit 100  # ENETDOWN
		fi
	fi
	if find_files; then
		i=0
		for file in "${transfer_list[@]}"; do
			((i++))
			printf 'Checking file (%s/%s)\n' "$i" "$count"
			if check_file "$file"; then
				if transfer_file "$file"; then
					printf 'Transferred file ("%s")\n' "$file"
				else
					printf 'ERROR: An error occured while transfering the file "%s"\n' "$file"
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
