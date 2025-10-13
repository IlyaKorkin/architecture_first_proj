clean_files() {
    local dir_path="$1"
    
    # Проверка что путь передан
    if [[ -z "$dir_path" ]]; then
        echo "Ошибка: путь к папке не указан"
        return 1
    fi

    # Проверка что папка существует
    if [[ ! -d "$dir_path" ]]; then
        echo "Ошибка: папка '$dir_path' не существует"
        return 1
    fi
    
    # Очистка
    #rm "$dir_path"/*.bin 2>/dev/null
    
    if ls "$dir_path"/*.bin 1> /dev/null 2>&1; then
        rm "$dir_path"/*.bin 2>/dev/null
    fi
    
    return 0
}

creation() {
    local size="$1"
    local count="$2"
    local dir_path="$3"

    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: '$count' не является целым числом"
        return 1
    fi
    
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: '$size' не является целым числом"
        return 1
    fi

    if [[ -z "$dir_path" ]]; then
        echo "Ошибка: путь к папке не указан"
        return 1
    fi
    
    # Проверка что папка существует
    if [[ ! -d "$dir_path" ]]; then
        echo "Ошибка: папка '$dir_path' не существует"
        return 1
    fi

    for i in $(seq 1 "$count"); do
        echo -e "$dir_path\nfile_$i\n$size" | ./creation_file.sh
    done

    return 0
}

#Запуск тестировщика 

echo "Введите путь до исполняемой программы"
read program

until [[ -f "$program" ]]; do
    echo "Вы ввели несуществующую программу, введите её заново"
    read program
done

echo "Введите путь до ограниченой папки, где будут проходить тесты"
read dir_path

until [[ -e "$dir_path" ]]; do
    echo "Вы ввели неправильный путь, введите его заново"
    read dir_path
done

 
# ===ТЕСТ 1===
clean_files "$dir_path"
#creation 1 10 "$dir_path"
echo "===Тест_1========================"
./"$program" << EOF
$dir_path
30
1
EOF




