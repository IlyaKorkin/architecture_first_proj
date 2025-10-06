echo "Enter the path to the folder:"
read dir_path

check_path() {
    if [[ -d "$dir_path" ]]; then
        mount_info=$(df --output=source "$dir_path" | tail -1)
        if mountpoint -q "$dir_path"; then
            echo "Path is already limited, enter a path to a folder that is not limited yet."
            return 1
        else
            return 0
        fi
    else
        echo "Path does not exist or leads to a file, not a folder"
        return 1
    fi
}


while ! check_path; do
    read dir_path
done
echo "Valid path: $dir_path"


echo "Enter the size limit in MB (between 16 and 1000):"
read size_mb

until [[ "$size_mb" =~ ^[0-9]+$ ]] && [[ "$size_mb" -ge 16 ]] && [[ "$size_mb" -le 1000 ]]; do
    echo "Size must be an integer between 16 and 1000 MB."
    read size_mb
done
size_mb=$(((size_mb * 105) / 100 + 6))

echo "Enter the path to store the .img files:"
read img_storage_path

if [ -d "$img_storage_path" ]; then
    echo "Storage path is valid"
else
    echo "Path does not exist or it leads to a file, not a folder"
    until [ -d "$img_storage_path" ]; do
        echo "Incorrect path, try again"
        read img_storage_path
    done
fi

img_file="$img_storage_path/limiter_$(basename "$dir_path").img"

echo "Creating image file: $img_file ($size_mb MB)"
dd if=/dev/zero of="$img_file" bs=1M count="$size_mb" || { echo "Failed to create image file"; exit 1; }

sudo mkfs.ext4 "$img_file" -F || { echo "Failed to format image"; exit 1; }

sudo mount -o loop "$img_file" "$dir_path" || { echo "Failed to mount image"; exit 1; }

current_user=$(whoami)
sudo chown -R "$current_user:$current_user" "$dir_path" || { echo "Failed to set permissions"; exit 1; }

fstab_entry="$img_file $dir_path ext4 loop,defaults,uid=$(id -u),gid=$(id -g) 0 2"
echo "$fstab_entry" | sudo tee -a /etc/fstab || { echo "Failed to update /etc/fstab"; exit 1; }


df -h "$dir_path" > /dev/null 2>&1 || { echo "Critical fail"; exit 1; }
echo "Folder $dir_path is now limited to $size_mb MB."
