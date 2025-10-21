# -- Базовые параметры
pathConfig="src/cf"        # Путь к конфигурации. Пример: src/cf 
pathExtensions="src/cfe"   # Путь к расширениям EDT. Пример: src/cfe 
# --

# проверим, что каталог основной конфигурации существует
if [ ! -d "$pathConfig" ]; then
  echo "$(date +%T) Ошибка: каталог основной конфигурации не найден: $pathConfig"
  exit 1
fi

# отключим вывод сообщений уровня "ИНФОРМАЦИЯ", оставим только сообщения уровня "ОШИБКА"
export LOGOS_CONFIG=logger.rootLogger=ERROR
# запускаем проверку основной конфигурации
echo $(date +%T) Проверка основной конфигурации ${pathConfig}
precommit4onec.bat exec-rules -source-dir $pathConfig -rules "СинхронизацияОбъектовМетаданныхИФайлов" .

# проверим, что каталог расширений существует
if [ -d "$pathExtensions" ]; then
	# находим все расширения нашего проекта
	for curr_ext in $pathExtensions/*/; do
		# выведем информацию о текущем расширении
		echo $(date +%T) Проверка расширения: ${curr_ext}
		# запускаем проверку расширения EDT конфигурации
		precommit4onec.bat exec-rules -source-dir ${curr_ext} -rules "СинхронизацияОбъектовМетаданныхИФайлов" .
	done
else
  echo "$(date +%T) Каталог расширений отсутствует: $pathExtensions — цикл пропущен"
fi
# т.к. проверка запускается в отдельном окне - ждем пока пользователь не увидит результат
#read -p "Press key to continue.. " -n1 -s