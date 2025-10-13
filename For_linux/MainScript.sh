#!/bin/bash

# Ввод пути до папки log
echo "Введите путь до папки /log"
read dir_path

until [[ -e "$dir_path" ]]; do
    echo "Вы ввели неправильный путь, введите его заново"
    read dir_path
done

# Ввод порога
echo "Введите порог N в процентах (знак % писать не нужно)"
read N

while ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -lt 0 ]] || [[ "$N" -gt 100 ]]; do
    echo "Ошибка: порог должен быть целым числом от 0 до 100"
    read N
done

# Ввод количества файлов для удаления
echo "Введите число M. M файлов будут заархивированы, если папка /log заполнена больше чем на N%"
read M

while ! [[ "$M" =~ ^[0-9]+$ ]]; do
    echo "Ошибка: M должно быть числом"
    read M
done

# Измеряем заполненность папки
full_size=$(cat ./size.txt)
current_size=$(df -m "$dir_path" | awk 'NR==2 {print $4}')

if [ "$full_size" -ne 0 ]; then
    usage=$(echo "scale=2; (($full_size - $current_size) / $full_size) * 100" | bc)
    echo "Папка заполнена на: ${usage}%"
    
    # Проверяем, превышен ли порог
    if (( $(echo "$usage > $N" | bc -l) )); then
        echo "Превышен порог $N%. Заполнение: ${usage}%"
        echo "Будет заархивировано $M старых файлов"
        
        # Путь для архива
        backup_dir="./backup"
        
        # Создаем папку для архивов
        if [ ! -d "$backup_dir" ]; then
            mkdir -p "$backup_dir"
            echo "Создана папка для архивов: $backup_dir"
        fi
        
        # Сортировка файлов от старых к новым
        echo "Поиск $M самых старых файлов в $dir_path"
        mapfile -t old_files < <(find "$dir_path" -maxdepth 1 -type f -printf '%T@ %p\n' | sort -n | head -n "$M" | cut -d' ' -f2-)
        
        count=${#old_files[@]}
        echo "Найдено файлов для архивации: $count"
        
        if [ $count -eq 0 ]; then
            echo "Нет файлов для архивации"
            exit 0
        fi
        
        # Создаем имя архива(имя_архива_год.месяц.день_час.минута.секунда) и его путь
        archive_name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        archive_path="$backup_dir/$archive_name"
        
        # Показываем файлы для архивации
        echo "Файлы для архивации:"
        for file in "${old_files[@]}"; do
            echo "  - $(basename "$file")"
        done
        
        # Создаем архива

        # Переходим в директорию для правильных относительных путей
        cd "$(dirname "$dir_path")" || exit 1
        
        if tar -czf "$archive_path" -C "$dir_path" "${old_files[@]##*/}"; then
            echo "Архив создан: $archive_path"
            
            # Удаляем заархивированные файлы
            echo "Удаление заархивированных файлов..."
            for file in "${old_files[@]}"; do
                if rm "$file"; then
                    echo "  Удален: $(basename "$file")"
                else
                    echo "  Ошибка при удалении: $(basename "$file")"
                fi
            done
            
            # Выводим новый размер папки
            new_current_size=$(df -m "$dir_path" | awk 'NR==2 {print $4}')
            new_usage=$(echo "scale=2; (($full_size - $new_current_size) / $full_size) * 100" | bc)
            echo "Новое заполнение папки: ${new_usage}%"
            
        else
            echo "Ошибка при создании архива"
            exit 1
        fi
        
    else
        echo "Заполнение в пределах нормы: ${usage}% (порог: $N%)"
        echo "Архивация не требуется"
    fi
else
    echo "Ошибка: размер не может быть нулевым"
    exit 1
fi