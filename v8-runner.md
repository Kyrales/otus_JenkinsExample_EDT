# v8-runner

Памятка по локальному использованию `v8-runner` в этом проекте.

## MCP

В проекте есть две разные MCP-поверхности:

- `onec-client-mcp` внутри запущенного клиента 1С на `http://127.0.0.1:9874/mcp`.
- `v8-runner` MCP server через `v8-runner mcp serve stdio`, который публикует 8 tools для сборки, тестов, запуска и проверок.

Обе настроены только для этого проекта в `.codex/config.toml`.

## Клиентский MCP внутри 1С

MCP поднимается внутри запущенного клиента 1С через расширение `client_mcp`.
Текущий рабочий адрес:

```text
http://127.0.0.1:9874/mcp
```

### Запуск после включения компьютера

Открыть PowerShell:

```powershell
cd F:\1C\Projects\otus_JenkinsExample_EDT
v8-runner launch mcp va --mcp-port 9874
```

Команда запускает тонкий клиент 1С, Vanessa Automation и клиентский MCP-сервер.

Проверить, что MCP поднялся:

```powershell
Test-NetConnection 127.0.0.1 -Port 9874
```

Ожидаемый результат:

```text
TcpTestSucceeded : True
```

Если порт не поднялся, выполнить подготовку расширения и повторить запуск:

```powershell
v8-runner build
& 'C:\Program Files\1cv8\8.5.1.1989\bin\ibcmd.exe' infobase --db-path 'F:\1C\Projects\otus_JenkinsExample_EDT\build\ib' config extension update --name client_mcp --safe-mode no --unsafe-action-protection no --user 'Администратор'
v8-runner launch mcp va --mcp-port 9874
```

### Подключение из ИИ

ИИ-клиент должен подключаться как MCP Streamable HTTP client:

```text
URL: http://127.0.0.1:9874/mcp
Protocol version: 2024-11-05
Transport: Streamable HTTP / SSE
```

Для ручной HTTP-проверки нужен заголовок:

```text
Accept: application/json, text/event-stream
mcp-protocol-version: 2024-11-05
```

Обычный `GET http://127.0.0.1:9874/mcp` в браузере может вернуть `400` или `406`.
Это не означает, что MCP сломан: endpoint ожидает MCP-запросы с нужными заголовками.

### Доступные tools

На момент проверки сервер возвращает один tool:

| Tool | Что делает | Как просить ИИ |
| --- | --- | --- |
| `infobase_info` | Возвращает сведения об информационной базе: версия платформы, тип платформы, файловая/серверная база, сведения о конфигурации и расширениях. | "Через MCP 1С вызови `infobase_info` и покажи сведения об информационной базе." |

Примеры задач для ИИ:

```text
Проверь через MCP, какая версия платформы 1С запущена.
```

```text
Вызови tool infobase_info и кратко опиши состояние базы.
```

```text
Проверь, доступен ли MCP 1С на 127.0.0.1:9874, и если доступен, вызови infobase_info.
```

## MCP tools v8-runner

Этот сервер запускается Codex автоматически по stdio из проектного конфига:

```powershell
v8-runner --config F:\1C\Projects\otus_JenkinsExample_EDT\v8project.yaml mcp serve stdio
```

Он не требует отдельно открывать порт. Через него ИИ может выполнять автоматизацию проекта:

| Tool | Что делает | Как просить ИИ |
| --- | --- | --- |
| `build_project` | Собирает проект и загружает исходники в ИБ. | "Через MCP v8-runner выполни `build_project`." |
| `run_all_tests` | Запускает все тесты. | "Через MCP v8-runner запусти все тесты." |
| `run_module_tests` | Запускает тесты конкретного модуля. | "Через MCP v8-runner запусти тесты модуля `<ИмяМодуля>`." |
| `dump_config` | Выгружает изменения конфигурации в файлы. | "Через MCP v8-runner выгрузи конфигурацию в исходники." |
| `launch_app` | Запускает 1С: designer, thin, thick и другие поддержанные режимы. | "Через MCP v8-runner открой конфигуратор." |
| `check_syntax_edt` | Выполняет EDT syntax check. | "Через MCP v8-runner проверь синтаксис EDT-проекта." |
| `check_syntax_designer_config` | Выполняет Designer-проверку конфигурации. | "Через MCP v8-runner проверь конфигурацию в Designer." |
| `check_syntax_designer_modules` | Выполняет Designer-проверку модулей. | "Через MCP v8-runner проверь синтаксис модулей." |

Если после запуска Codex виден только `infobase_info`, значит подключен только `onec-client-mcp`. Нужно перезапустить Codex из корня этого проекта, чтобы он перечитал `.codex/config.toml` и поднял `v8-runner` MCP server.
