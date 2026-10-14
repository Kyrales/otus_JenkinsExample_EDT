# Полный запуск YAxUnit и Vanessa Automation

2026-10-13, 15:58. База `build/ib_extend`, платформа 8.5.1.1522. Оба запуска выполнены через v8-runner со штатной сборкой перед тестами; код завершения обоих — 0.

```powershell
& F:/1C/Projects/v8-runner-rust/target/release/v8-runner.exe --config v8project.dadata-validation.yaml test yaxunit --junit-output .superpowers/sdd/2026-10-13-counterparty-dadata/all-yaxunit-junit.xml all
& F:/1C/Projects/v8-runner-rust/target/release/v8-runner.exe --config v8project.dadata-validation.yaml test va
```

| Набор | Всего | Прошли | Ошибки / провалы / пропуски |
| --- | --- | --- | --- |
| YAxUnit, весь набор | 99 | 99 | 0 / 0 / 0 |
| Vanessa Automation, профиль all | 2 | 2 | 0 / 0 / 0 |

VA выполнила сценарии «0100 Создание и проведение документа» и «1000 Закрыть клиент тестирования». Оба имеют статус `passed` в свежих Allure-отчетах. Профиль сохраняет штатное исключение `IgnoreOnCIMainBuild`: файлы экспортных подсценариев не запускаются отдельно; файл переменных среды не содержит самостоятельных сценариев. Новых VA-сценариев для DaData в этом наборе нет.

- [JUnit YAxUnit](../../../.superpowers/sdd/2026-10-13-counterparty-dadata/all-yaxunit-junit.xml).
- [Allure: создание и проведение документа](../../../.superpowers/sdd/2026-10-13-counterparty-dadata/all-va-allure/47facce5-1fdc-46cb-be93-2fb41335cf9f-result.json).
- [Allure: закрытие клиента](../../../.superpowers/sdd/2026-10-13-counterparty-dadata/all-va-allure/8186e836-061d-445d-a3c2-0be37a3ff8bb-result.json).

Предупреждения CLI: информационная регистрация client_mcp, строка VA `Error: 0 (0%)`, сообщения об отсутствии уже закрываемых профилей TestClient. Они не сопровождались провалами сценариев; свежие Allure-результаты и сводки проверены отдельно.

В игнорируемом конфиге проверки указан абсолютный путь к уже установленной обработке Vanessa Automation. Продуктовый код не менялся, коммитов нет.
