echo "Enter the path to the limited folder:"
read dir_path

check_path() {
    if [[ -d "$dir_path" ]]; then
        return 0
    else
        echo "Path does not exist or leads to a file, not a folder"
        return 1
    fi
}

while ! check_path; do
    read dir_path
done

echo "Info from /etc/fstab that matches this path:"
grep "$dir_path" /etc/fstab || echo "No entries found in /etc/fstab"

if mountpoint -q "$dir_path"; then
    echo "Unmounting $dir_path:"
    sudo umount "$dir_path" || { echo "Failed to unmount. Make sure no files are in use."; exit 1; }
else
    echo "Path is not mounted"
fi

mapfile -t img_files < <(grep -F "$dir_path" /etc/fstab | awk '{print $1}' | sort -u)

if ((${#img_files[@]})); then
	for img in "${img_files[@]}"; do
    	if [[ -f "$img" ]]; then
        	echo "Deleting image file: $img"
        	if sudo rm -f "$img"; then
            	echo "removed"
        	else
            	echo "failed to remove!"
        	fi
    	else
        	echo "Image file was already deleted: $img"
    	fi
	done
else
    echo "No image files referenced for this mount point."
fi

sudo sed -i "\|$dir_path|d" /etc/fstab || { echo "Failed to edit /etc/fstab"; exit 1; }
echo "fstab cleaned. All the work was done"
