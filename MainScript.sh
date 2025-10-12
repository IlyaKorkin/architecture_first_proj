echo "Введите путь до папки /log"
read dir_path

until [[ -e "$dir_path" ]]; do
    echo "Вы ввели нерпавильный путь, введите его заново"
    read dir_path
done

echo "Введите порог N в процентах(знак % писать не нужно)"
read N

while ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -lt 0 ]] || [[ "$N" -gt 100 ]]; do
    echo "Ошибка: порог должен быть целым числом от 0 до 100"
    read N
done

echo "Введите число M. M файлов будут заархивированны, если папка /log заполненна больше чем на N%"
read M

while ! [[ "$M" =~ ^[0-9]+$ ]]; do
    echo "Ошибка: M должно быть числом"
    read M
done

full_size=$(cat ./size.txt)
#echo $full_size

cure_size=$(df -m $dir_path | awk 'NR==2 {print $4}')
#echo $cure_size

if [ "$full_size" -ne 0 ]; then
    usage=$(echo "scale=2; (($full_size - $cure_size) / $full_size) * 100" | bc)
    echo "Папка заполнена на: ${usage}%"
    
    # Сравнение с порогом N
    if (( $(echo "$usage > $N" | bc -l) )); then
        echo "Превышен порог $N%. Заполнение: ${usage}%"
        echo "Будут удалены $M файлов"
        # Здесь добавьте код для удаления файлов
    else
        echo "Заполнение в пределах нормы: ${usage}% (порог: $N%)"
    fi
else
    echo "Ошибка: размер не может быть нулевым"
fi