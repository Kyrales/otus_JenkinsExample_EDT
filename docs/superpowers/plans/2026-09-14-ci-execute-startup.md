# CI `/C` + `/Execute` Startup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить минимально совместимый с БСП жизненный цикл CI-запуска: распознать `/C ЗапуститьОбновлениеИнформационнойБазы`, сбросить повторно используемые значения и дать `ЗакрытьПредприятие.epf`, запущенной через `/Execute`, штатно завершить сеанс.

**Architecture:** Чистая экспортная функция существующего серверного общего модуля разбирает `ПараметрЗапуска` и покрывается YAxUnit. Модуль управляемого приложения вызывает сброс повторно используемых значений только при положительном результате; завершение остается ответственностью внешней обработки vanessa-runner.

**Tech Stack:** 1С:Предприятие 8.3.27.2130, BSL, EDT-MCP, YAxUnit, v8-runner, vanessa-runner 3.0.0, файловая ИБ `build/ib_extend`.

**Spec:** `docs/superpowers/specs/2026-09-14-ci-execute-startup-design.md`

## Global Constraints

- Не переносить подсистемы БСП, версии ИБ, реестр обработчиков миграций и формы обновления.
- Не создавать новые объекты основной конфигурации и не менять обычный интерактивный запуск.
- Не завершать приложение из модуля конфигурации: `/Execute` должен успеть открыть `ЗакрытьПредприятие.epf`.
- Все чтение и запись BSL выполнять только через EDT-MCP; для точечных правок использовать `expectedHash`.
- Интеграционный запуск и YAxUnit выполнять на `build/ib_extend`; `build/ib` не обновлять.
- Любой запуск предприятия ограничивать 180 секундами; таймаут считать провалом и завершать только созданное этим запуском дерево процессов.
- Не включать существующие пользовательские изменения `*.PMF` и `.codex/config.toml` в коммиты задачи.

---

## File Structure

- Modify: `src/cf/otusJenkinsExampleEDT/src/CommonModules/СервисныеМеханизмы/Module.bsl` — чистая функция распознавания команды.
- Modify: `src/cf/otusJenkinsExampleEDT/src/Configuration/ManagedApplicationModule.bsl` — запуск минимального обновления.
- Create via EDT-MCP: `src/cfe/otusJenkinsExampleEDT.YAXUNIT/src/CommonModules/ОМ_ПараметрыЗапускаCI/ОМ_ПараметрыЗапускаCI.mdo` — метаданные серверного тестового модуля.
- Create via EDT-MCP: `src/cfe/otusJenkinsExampleEDT.YAXUNIT/src/CommonModules/ОМ_ПараметрыЗапускаCI/Module.bsl` — параметризованные YAxUnit-тесты.
- Verify only: `tools/vrunner_ssl.json` — заданные `/C` и `/Execute`; менять не требуется.
- Verify only: `build/ib_extend` — выделенная интеграционная ИБ, не добавляемая в Git.

### Task 1: YAxUnit-тесты разбора `/C`

**Files:**
- Create: `src/cfe/otusJenkinsExampleEDT.YAXUNIT/src/CommonModules/ОМ_ПараметрыЗапускаCI/ОМ_ПараметрыЗапускаCI.mdo`
- Create: `src/cfe/otusJenkinsExampleEDT.YAXUNIT/src/CommonModules/ОМ_ПараметрыЗапускаCI/Module.bsl`
- Modify: `src/cf/otusJenkinsExampleEDT/src/CommonModules/СервисныеМеханизмы/Module.bsl:1-30`

**Interfaces:**
- Consumes: строку команд `/C`, элементы которой разделены `;`.
- Produces: `СервисныеМеханизмы.ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска)` → `Булево`.

- [ ] **Step 1: Зафиксировать исходное состояние и похожие паттерны**

Через EDT-MCP выполнить:

```text
get_problem_summary(projectName="otusJenkinsExampleEDT")
get_module_structure(projectName="otusJenkinsExampleEDT", modulePath="CommonModules/СервисныеМеханизмы/Module.bsl", responseFormat="detailed")
get_module_structure(projectName="otusJenkinsExampleEDT.YAXUNIT", modulePath="CommonModules/ОМ_ПервыйТест/Module.bsl", responseFormat="detailed")
search_in_code(projectName="otusJenkinsExampleEDT", query="СтрРазделить", metadataType="commonModules", outputMode="files", maxResults=100)
read_method_source(projectName="otusJenkinsExampleEDT", modulePath="CommonModules/СервисныеМеханизмы/Module.bsl", methodName="ПолучитьПараметры")
get_project_errors(projectName="otusJenkinsExampleEDT", severity="ERRORS", objects=["СервисныеМеханизмы"], limit=100)
```

Сохранить `contentHash` общего модуля и исходный набор его ошибок. Общую сводку использовать только для сравнения: проект уже содержит ранее существовавшие проблемы.

- [ ] **Step 2: Создать серверный тестовый модуль**

Через EDT-MCP создать объект:

```text
create_metadata(projectName="otusJenkinsExampleEDT.YAXUNIT", fqn="CommonModule.ОМ_ПараметрыЗапускаCI", commonModuleKind="Server", generateContent=true, expectedNotExists=true)
```

Через `write_module_source` с `mode="replace"` записать полный исходник нового модуля:

```bsl
#Область ПрограммныйИнтерфейс

Процедура ИсполняемыеСценарии() Экспорт

	ЮТТесты.ДобавитьТестовыйНабор("CI: параметры запуска")
		.ДобавитьТест("ТребуетсяОбновлениеИнформационнойБазы")
			.СПараметрами("ЗапуститьОбновлениеИнформационнойБазы;ЗавершитьРаботуСистемы;", Истина)
			.СПараметрами("  запуститьобновлениеинформационнойбазы  ;", Истина)
			.СПараметрами("", Ложь)
			.СПараметрами("ЗавершитьРаботуСистемы;", Ложь)
			.СПараметрами("ПрефиксЗапуститьОбновлениеИнформационнойБазы;", Ложь)
		;

КонецПроцедуры

Процедура ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска, ОжидаемыйРезультат) Экспорт

	ФактическийРезультат = СервисныеМеханизмы.ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска);

	ЮТест.ОжидаетЧто(ФактическийРезультат)
		.Равно(ОжидаемыйРезультат);

КонецПроцедуры

#КонецОбласти
```

`replace` допустим, потому что модуль новый и записывается целиком.

- [ ] **Step 3: Запустить тест и подтвердить красную фазу**

```text
run_yaxunit_tests(projectName="otusJenkinsExampleEDT", applicationId="867ff919-3b34-4103-9116-42bd2dd45866", extensions=["YAXUNIT"], modules=["ОМ_ПараметрыЗапускаCI"], updateBeforeLaunch=true, timeout=45)
```

Если возвращен `jobId`, опрашивать именно его через `get_job_status(waitSeconds=45)`, не запускать тест повторно. Общий срок ожидания — 180 секунд. После дедлайна вызвать `cancel_job` сначала без `confirm`, затем с `confirm=true`, и считать проверку проваленной. Expected: FAIL из-за отсутствующего метода `СервисныеМеханизмы.ТребуетсяОбновлениеИнформационнойБазы`; это обязательная красная фаза.

- [ ] **Step 4: Реализовать минимальную чистую функцию**

Через `write_module_source` с `mode="insertAfter"`, якорем `methodName="ПолучитьПараметры"` и `expectedHash` из Step 1 вставить:

```bsl
// Определяет необходимость минимального обновления информационной базы при запуске из CI.
//
// Параметры:
//  ПараметрЗапуска - Строка - значение параметра командной строки /C.
//
// Возвращаемое значение:
//  Булево - Истина, если передана команда ЗапуститьОбновлениеИнформационнойБазы.
Функция ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска) Экспорт

	КомандыЗапуска = СтрРазделить(ПараметрЗапуска, ";", Ложь);
	Для Каждого КомандаЗапуска Из КомандыЗапуска Цикл
		Если ВРег(СокрЛП(КомандаЗапуска)) = ВРег("ЗапуститьОбновлениеИнформационнойБазы") Тогда
			Возврат Истина;
		КонецЕсли;
	КонецЦикла;

	Возврат Ложь;

КонецФункции
```

Функция не меняет состояние и не обрабатывает команду `ЗавершитьРаботуСистемы`.

- [ ] **Step 5: Запустить модуль YAxUnit и подтвердить зеленую фазу**

Повторить `run_yaxunit_tests` из Step 3 как новый запуск и при необходимости опрашивать его `jobId` с тем же дедлайном 180 секунд и двухфазной отменой после дедлайна. Expected: пять наборов параметров PASS, итог модуля PASS.

- [ ] **Step 6: Проверить объекты и закоммитить тестируемый разбор**

```text
revalidate_objects(projectName="otusJenkinsExampleEDT", objects=["CommonModule.СервисныеМеханизмы"])
revalidate_objects(projectName="otusJenkinsExampleEDT.YAXUNIT", objects=["CommonModule.ОМ_ПараметрыЗапускаCI"])
get_project_errors(projectName="otusJenkinsExampleEDT", severity="ERRORS", objects=["СервисныеМеханизмы"], limit=100)
get_project_errors(projectName="otusJenkinsExampleEDT.YAXUNIT", severity="ERRORS", objects=["ОМ_ПараметрыЗапускаCI"], limit=100)
```

Expected: исходный набор ошибок `СервисныеМеханизмы` не увеличился; у нового тестового модуля нет ошибок.

```powershell
git diff --check
git add -- "src/cf/otusJenkinsExampleEDT/src/CommonModules/СервисныеМеханизмы/Module.bsl" "src/cfe/otusJenkinsExampleEDT.YAXUNIT/src/CommonModules/ОМ_ПараметрыЗапускаCI"
git commit -m "test: покрыть разбор CI-параметров запуска"
```

Перед коммитом проверить staged diff; существующие изменения `.codex/config.toml` и `*.PMF` не добавлять.

### Task 2: Подключение минимального обновления к запуску приложения

**Files:**
- Modify: `src/cf/otusJenkinsExampleEDT/src/Configuration/ManagedApplicationModule.bsl:8-36`

**Interfaces:**
- Consumes: `СервисныеМеханизмы.ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска)` → `Булево` из Task 1.
- Produces: сброс повторно используемых значений только при целевой команде `/C`.

- [ ] **Step 1: Прочитать и проверить точку подключения**

```text
get_module_structure(projectName="otusJenkinsExampleEDT", modulePath="Configuration/ManagedApplicationModule.bsl", responseFormat="detailed")
read_method_source(projectName="otusJenkinsExampleEDT", modulePath="Configuration/ManagedApplicationModule.bsl", methodName="ПриНачалеРаботыСистемы")
get_project_errors(projectName="otusJenkinsExampleEDT", severity="ERRORS", objects=["ManagedApplicationModule"], limit=100)
```

Сохранить `contentHash` и исходный набор ошибок модуля приложения.

- [ ] **Step 2: Добавить минимальный вызов в конец обработчика запуска**

Через `write_module_source` с `mode="searchReplace"` и `expectedHash` из Step 1 заменить:

```bsl
	ГлобальныйПоискКлиент.УстановитьОписаниеГлобальногоПоиска();
	
КонецПроцедуры
```

на:

```bsl
	ГлобальныйПоискКлиент.УстановитьОписаниеГлобальногоПоиска();
	
	Если СервисныеМеханизмы.ТребуетсяОбновлениеИнформационнойБазы(ПараметрЗапуска) Тогда
		ОбновитьПовторноИспользуемыеЗначения();
	КонецЕсли;
	
КонецПроцедуры
```

Исключения не перехватывать: ошибка сброса должна провалить CI, а не имитировать успех. Самостоятельное завершение приложения не добавлять.

- [ ] **Step 3: Перевалидировать проект и повторить YAxUnit**

```text
revalidate_objects(projectName="otusJenkinsExampleEDT", objects=[])
get_project_errors(projectName="otusJenkinsExampleEDT", severity="ERRORS", objects=["СервисныеМеханизмы", "ManagedApplicationModule"], limit=100)
run_yaxunit_tests(projectName="otusJenkinsExampleEDT", applicationId="867ff919-3b34-4103-9116-42bd2dd45866", extensions=["YAXUNIT"], modules=["ОМ_ПараметрыЗапускаCI"], updateBeforeLaunch=true, timeout=45)
```

Expected: наборы ошибок обоих модулей не хуже baseline, тестовый модуль PASS.

### Task 3: Проверка полного цикла `/C` → `/Execute` → завершение

**Files:**
- Verify only: `tools/vrunner_ssl.json`
- Update only: `build/designer/otusJenkinsExampleEDT`
- Update only: `build/ib_extend`
- Create ignored artifact: уникальный `build/ci-execute-{yyyyMMddHHmmssfff}.status`

**Interfaces:**
- Consumes: реализацию Tasks 1-2 и `ЗакрытьПредприятие.epf` из установленного vanessa-runner.
- Produces: свежий status-файл со значением `0` и завершившийся процесс как доказательство выполнения `/Execute`.

- [ ] **Step 1: Собрать и проверить основной source set**

```text
build_project(sourceSet="otusJenkinsExampleEDT", fullRebuild=false)
check_syntax_edt(projectName="otusJenkinsExampleEDT")
```

Expected: обе команды успешны; `build/designer/otusJenkinsExampleEDT` актуален.

- [ ] **Step 2: Загрузить основную конфигурацию в выделенную базу**

```powershell
vrunner infobase update `
  --src "build\designer\otusJenkinsExampleEDT" `
  --target main `
  --ibconnection "/FF:\1C\Projects\otus_JenkinsExample_EDT\build\ib_extend" `
  --db-user "Администратор" `
  --v8version "8.3.27.2130"
```

Expected: обновлена только `build/ib_extend`; `build/ib` не открывалась.

- [ ] **Step 3: Выполнить интеграционный запуск с watchdog**

В PowerShell выполнить bounded-запуск ниже. Он использует уникальный status-файл, проверяет его свежесть и при таймауте завершает только дерево созданного процесса; перед остановкой процесса 1С дополнительно проверяет, что его командная строка относится к `ib_extend`.

```powershell
$StartedAt = Get-Date
$StatusPath = Join-Path (Resolve-Path 'build') ("ci-execute-{0}.status" -f $StartedAt.ToString('yyyyMMddHHmmssfff'))
$RunnerPath = (Get-Command vrunner).Source
$RunnerArguments = @('run', 'enterprise', '--settings', 'tools/vrunner_ssl.json', '--ibconnection', '/FF:\1C\Projects\otus_JenkinsExample_EDT\build\ib_extend', '--db-user', 'Администратор', '--v8version', '8.3.27.2130', '--exitCodePath', $StatusPath)
$RunnerProcess = Start-Process -FilePath $RunnerPath -ArgumentList $RunnerArguments -PassThru -WindowStyle Hidden

if (-not $RunnerProcess.WaitForExit(180000)) {
    $Processes = Get-CimInstance Win32_Process
    $Descendants = @()
    $PendingParents = @($RunnerProcess.Id)
    while ($PendingParents.Count -gt 0) {
        $CurrentParentId = $PendingParents[0]
        $PendingParents = @($PendingParents | Select-Object -Skip 1)
        $Children = @($Processes | Where-Object ParentProcessId -eq $CurrentParentId)
        $Descendants += $Children
        $PendingParents += @($Children.ProcessId)
    }
    $ForeignClients = @($Descendants | Where-Object { $_.Name -like '1cv8*' -and $_.CommandLine -notlike '*ib_extend*' })
    if ($ForeignClients.Count -gt 0) {
        throw "Таймаут; в дереве найдены процессы 1С не от build\ib_extend, автоматическая остановка отменена."
    }
    $Descendants | Sort-Object ProcessId -Descending | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Stop-Process -Id $RunnerProcess.Id -Force -ErrorAction SilentlyContinue
    throw "CI-запуск превысил таймаут 180 секунд."
}

if ($RunnerProcess.ExitCode -ne 0) { throw "vrunner завершился с кодом $($RunnerProcess.ExitCode)." }
if (-not (Test-Path -LiteralPath $StatusPath)) { throw "Обработка /Execute не создала status-файл." }
$StatusFile = Get-Item -LiteralPath $StatusPath
if ($StatusFile.LastWriteTime -lt $StartedAt -or (Get-Content -LiteralPath $StatusPath -Raw).Trim() -ne '0') {
    throw "Обработка /Execute не подтвердила успешное завершение свежим статусом 0."
}
```

Expected: блок завершается без исключения менее чем за 180 секунд. Уникальный свежий status-файл содержит `0`; это подтверждает запуск `ЗакрытьПредприятие.epf`, а не только успешный старт процесса.

- [ ] **Step 4: Проверить отсутствие runtime-ошибок запуска**

Через EDT-MCP прочитать журнал выделенной ИБ за интервал от `$StartedAt`:

```text
get_event_log(logDir="F:\\1C\\Projects\\otus_JenkinsExample_EDT\\build\\ib_extend\\1Cv8Log", from="фактическое значение $StartedAt в ISO-8601", severity=["Error"], order="date_desc", limit=100)
```

Подставить сохраненное в Step 3 значение `$StartedAt`. Expected: `success=true`, `format="text-2.0"`, runtime-ошибок этого запуска нет. Поддержка формата уже проверена на `build/ib_extend` при подготовке плана.

- [ ] **Step 5: Финальная проверка и коммит подключения**

```powershell
git diff --check
git status --short
git diff -- "src/cf/otusJenkinsExampleEDT/src/Configuration/ManagedApplicationModule.bsl"
git add -- "src/cf/otusJenkinsExampleEDT/src/Configuration/ManagedApplicationModule.bsl"
git commit -m "feat: поддержать CI-запуск через execute"
```

Expected: во второй коммит входит только модуль управляемого приложения. Status-файл и остальные артефакты `build/` игнорируются; пользовательские `.codex/config.toml` и `*.PMF` не добавляются.
