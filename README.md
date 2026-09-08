# Развёртывание Redmine с помощью Ansible

[![hexlet-check](https://github.com/VorobyevAM/devops-engineer-from-scratch-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/VorobyevAM/devops-engineer-from-scratch-project-76/actions/workflows/hexlet-check.yml)

Проект подготавливает серверы и развёртывает официальный Docker-образ Redmine
на группе хостов `webservers`.

## Требования

- Ansible
- GNU Make
- SSH-ключ для подключения к серверам
- две ВМ с Ubuntu
- PostgreSQL
- балансировщик нагрузки

## Настройка

Склонируйте репозиторий и установите роли и коллекции Ansible Galaxy:

```bash
git clone YOUR_REPOSITORY_URL
cd YOUR_PROJECT_DIRECTORY
make install
```

Укажите серверы и SSH-пользователя в `inventory.ini`:

```ini
[webservers]
server-1 ansible_host=<SERVER_1_IP> ansible_user=<SSH_USER>
server-2 ansible_host=<SERVER_2_IP> ansible_user=<SSH_USER>
```

По умолчанию Ansible использует ключи из `~/.ssh`. Другой ключ можно передать
через переменную окружения:

```bash
export ANSIBLE_PRIVATE_KEY_FILE=/path/to/private_key
```

В `group_vars/all.yml` укажите общие параметры приложения и PostgreSQL:

```yaml
redmine_port: <APPLICATION_PORT>
redmine_db_host: <POSTGRESQL_HOST>
redmine_db_port: <POSTGRESQL_PORT>
redmine_db_name: <POSTGRESQL_DATABASE>
redmine_db_user: <POSTGRESQL_USER>
```

Пароль базы данных и `SECRET_KEY_BASE` хранятся в зашифрованном файле
`group_vars/webservers/vault.yml`. В открытом файле
`group_vars/webservers/vars.yml` находятся только ссылки на Vault-переменные.

Создайте локальный файл `.vault_password` с паролем Ansible Vault. Этот файл
добавлен в `.gitignore` и не должен попадать в репозиторий:

```bash
openssl rand -hex 32 > .vault_password
chmod 600 .vault_password
```

При первоначальном создании Vault добавьте в него секреты:

```bash
ansible-vault create group_vars/webservers/vault.yml \
  --vault-password-file .vault_password
```

Содержимое файла до шифрования должно иметь следующий вид:

```yaml
---
vault_redmine_db_password: <POSTGRESQL_PASSWORD>
vault_redmine_secret_key_base: <PERSISTENT_SECRET_KEY_BASE>
vault_datadog_api_key: <DATADOG_API_KEY>
```

Для уже созданного Vault получите пароль безопасным способом у владельца
инфраструктуры и запишите его в `.vault_password`. Изменить или просмотреть
секреты можно командами:

```bash
make vault-edit
make vault-view
```

## Подготовка серверов

Проверьте синтаксис плейбука:

```bash
make check
```

Установите на серверах pip, Python SDK для Docker и Docker Engine:

```bash
make prepare
```

## Деплой

После заполнения Vault запустите деплой:

```bash
make deploy
```

Команда `make deploy` запускает только задачи с тегом `deploy` и не изменяет
настройки операционной системы. Ansible создаёт на каждом сервере защищённый
файл `/opt/redmine/.env` из шаблона `templates/redmine.env.j2` и запускает
контейнер Redmine на порту `redmine_port`. Пароль PostgreSQL и
`SECRET_KEY_BASE` берутся из Ansible Vault.

## Мониторинг

Укажите сайт Datadog и настройки HTTP-проверки в `group_vars/all.yml`.
API-ключ задаётся только через
`vault_datadog_api_key` в зашифрованном Vault.

Установите и настройте агент Datadog на группе `webservers`:

```bash
make monitoring
```

Агент проверяет Redmine локально по адресу
`http://127.0.0.1:<APPLICATION_PORT>/`. Проверить его состояние на сервере
можно командой:

```bash
sudo datadog-agent status
```

## DNS и HTTPS

Создайте A-запись, направленную на публичный IP балансировщика:

```text
Name: YOUR_DOMAIN
Type: A
Value: LOAD_BALANCER_IP
```

Настройте на балансировщике:

- HTTP-листенер на порту `80` с перенаправлением на HTTPS;
- HTTPS-листенер на порту `443` с сертификатом для `YOUR_DOMAIN`;
- backend group из обеих ВМ на порту `APPLICATION_PORT`;
- HTTP health check по пути `/`.

Разрешите подключения к порту приложения на ВМ только от группы безопасности
балансировщика. Доступ к PostgreSQL разрешите только от группы безопасности ВМ.

## Проверка

```bash
curl --head http://YOUR_DOMAIN
curl --fail https://YOUR_DOMAIN/
```

Первый запрос должен вернуть перенаправление на HTTPS, второй — страницу
Redmine.

Развёрнутое приложение: [https://hexlet6.chickenkiller.com](https://hexlet6.chickenkiller.com)
