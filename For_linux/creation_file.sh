#echo "Введите путь к ограниченной папке:"
read folder_path

#echo "Введите имя нового файла"
read filename

path="$folder_path/$filename.bin"

#echo "Введите размер файла в МБ"
read size

dd if=/dev/zero of=$path bs=$((size * 1024 * 1024)) count=1