# отключим вывод сообщений уровня "ИНФОРМАЦИЯ", оставим только сообщения уровня "ОШИБКА"
export LOGOS_CONFIG=logger.rootLogger=ERROR
# запускаем проверку основной конфигурации
echo $(date +%T) Проверка основной конфигурации
precommit4onec.bat exec-rules -source-dir src/cf -rules "СинхронизацияОбъектовМетаданныхИФайлов" .
# находим все расширения нашего проекта
for curr_ext in src/cfe/*/; do
	# запомним имя папки
	curr_name=${curr_ext#exts/}
	# выведем информацию о текущем расширении
	echo $(date +%T) Проверка расширения ${curr_name%"/"}
	# запускаем проверку расширения конфигурации
	precommit4onec.bat exec-rules -source-dir $curr_ext"src" -rules "СинхронизацияОбъектовМетаданныхИФайлов" .
done
# т.к. проверка запускается в отдельном окне - ждем пока пользователь не увидит результат
#read -p "Press key to continue.. " -n1 -s