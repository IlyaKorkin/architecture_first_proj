GREEN='\033[0;32m'
NC='\033[0m'

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
        timestamp=$(date +%Y%m%d_%H%M%S_%N)  
        echo -e "$dir_path\nfile_${timestamp}\n$size" | ./creation_file.sh
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
creation 10 1 "$dir_path"
echo -e "${GREEN}=====Тест_1=====${NC}"
./"$program" << EOF
$dir_path
50
3
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 2===
clean_files "$dir_path"
creation 5 5 "$dir_path"
echo -e "${GREEN}=====Тест_2=====${NC}"
./"$program" << EOF
$dir_path
50
3
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 3===
clean_files "$dir_path"
creation 25 1 "$dir_path"
creation 1 1 "$dir_path"
echo -e "${GREEN}=====Тест_3=====${NC}"
./"$program" << EOF
$dir_path
50
1
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 4===
clean_files "$dir_path"
creation 1 5 "$dir_path"
echo -e "${GREEN}=====Тест_4=====${NC}"
./"$program" << EOF
$dir_path
5
3
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 5===
clean_files "$dir_path"
creation 40 1 "$dir_path"
creation 5 3 "$dir_path"
echo -e "${GREEN}=====Тест_5=====${NC}"
./"$program" << EOF
$dir_path
75
3
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 6===
clean_files "$dir_path"
creation 50 2 "$dir_path"
echo -e "${GREEN}=====Тест_6=====${NC}"
./"$program" << EOF
$dir_path
75
3
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 7===
clean_files "$dir_path"
creation 5 11 "$dir_path"
echo -e "${GREEN}=====Тест_7=====${NC}"
./"$program" << EOF
$dir_path
80
15
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 8===
clean_files "$dir_path"
creation 1 50 "$dir_path"
echo -e "${GREEN}=====Тест_8=====${NC}"
./"$program" << EOF
$dir_path
10
30
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 9===
clean_files "$dir_path"
creation 10 3 "$dir_path"
echo -e "${GREEN}=====Тест_9=====${NC}"
./"$program" << EOF
$dir_path
60
2
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 10===
clean_files "$dir_path"
creation 7 6 "$dir_path"
echo -e "${GREEN}=====Тест_10=====${NC}"
./"$program" << EOF
$dir_path
60
5
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 11===
clean_files "$dir_path"
creation 3 10 "$dir_path"
echo -e "${GREEN}=====Тест_11=====${NC}"
./"$program" << EOF
$dir_path
85
10
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 12===
clean_files "$dir_path"
creation 15 3 "$dir_path"
echo -e "${GREEN}=====Тест_12=====${NC}"
./"$program" << EOF
$dir_path
85
1
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 13===
clean_files "$dir_path"
creation 10 10 "$dir_path"
echo -e "${GREEN}=====Тест_13=====${NC}"
./"$program" << EOF
$dir_path
50
2
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 14===
clean_files "$dir_path"
creation 10 4 "$dir_path"
echo -e "${GREEN}=====Тест_14=====${NC}"
./"$program" << EOF
$dir_path
75
2
EOF
echo -e "${GREEN}================${NC}"

# ===ТЕСТ 15===
clean_files "$dir_path"
creation 10 3 "$dir_path"
echo -e "${GREEN}=====Тест_15=====${NC}"
./"$program" << EOF
$dir_path
75
2
EOF
echo -e "${GREEN}================${NC}"
