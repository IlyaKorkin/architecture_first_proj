echo "Введите путь до папки /log"
read dir_path

if [ -e "$dir_path" ]; then
    echo "Путь обработан"
else
    until [[ -e "$dir_path" ]]; do
        echo "Вы ввели нерпавильный путь, введите его заново"
        read dir_path
    done
fi

du -sh "$dir_path"