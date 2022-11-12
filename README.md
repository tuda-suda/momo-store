# Momo Store aka Пельменная №2

<img width="900" alt="image" src="https://user-images.githubusercontent.com/9394918/167876466-2c530828-d658-4efe-9064-825626cc6db5.png">

## Frontend

```bash
npm install
NODE_ENV=production VUE_APP_API_URL=http://localhost:8081 npm run serve
```

## Backend

```bash
go run ./cmd/api
go test -v ./...
```

# О проекте

Сайт доступен по адресу https://mgumerov-momo-store.ru

Интерфейс Grafana доступен на https://grafana.mgumerov-momo-store.ru

Логин/пароль для Grafana:

```
admin/admin
```

Интерфейс Prometheus доступен на https://prometheus.mgumerov-momo-store.ru

Чарты для Grafana и Prometheus располагаются в отдельном [репозитории](https://gitlab.praktikum-services.ru/m.gumerov/monitoring-tools)

## Структура репозитория

- `backend`, `frontend` - здесь хранятся исходники приложения, Dockerfile'ы для сборки образа, а также `.gitlab-ci.yml` для автоматической сборки, тестирования и релиза компонентов;
- `infrastructure` - здесь можно найти:
- - `terraform` - файлы Terraform для развертывания кластера Kubernetes со всем необходимым в Яндекс.Облаке;
- - `kubernetes` - здесь хранится Helm-чарт с манифестами, которые описывают развертывание приложения в кластере Kubernetes, `.gitlab-ci.yaml` для автоматической публикации Helm-чарта и деплоя приложения в кластере;
- `.gitlab-ci.yml` - корневой пайплайн который управляет всем процессом ci/cd.

## Разворачивание инфраструктуры:

### 1. Terraform

1. Создать и настроить вручную бакеты для `terraform.tfstate` и статического контента а также сервисный аккаунт приложения с правами `storage.editor`.
2. Заполнить файлы с переменными `.tfvars` и `backend.tfvars`:
   ```
   // backend.tfvars
   // Ключи от сервисного аккаунта для бакетов
   access_key = "xxxx"
   secret_key = "xxxx"
   ```
   ```
   // .tfvars
   token     = "xxxx" // IAM token
   cloud_id  = "xxxx"
   folder_id = "xxxx"
   ```
3. Инициализируем хранилище для `terraform.tfstate`
   ```
   terraform init -backend-config=./backend.tfvars
   ```
4. Применяем изменения
   ```
   terraform apply -var-file=./.tfvars
   ```

### 2. Kubernetes

1. Устанавливаем ingress-nginx controller
   ```
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install ingress-nginx ingress-nginx/ingress-nginx
   ```
2. Устанавливаем cert-manager и Service Account
   ```
   kubectl apply -f infrastrucuture/kubernetes/sa.yaml
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
   ```
3. Настройка DNS-записи для Ingress-контроллера
   Узнать IP-адрес Ingress-контроллера (значение в колонке EXTERNAL-IP):
   ```
   kubectl get svc
   ```
   Размещаем у своего DNS-провайдера или на собственном DNS-сервере A-запись:

   ```
   <your domain> IN A <ingress-controller public IP>
   ```

### 3. Мониторинг
1. Создаем неймспейс `monitoring`
   ```
   kubectl create ns monitoring
   ```
2. Задаем переменную вашего домена/хостнейма
   ```
   export MOMO_DOMAIN=mgumerov-momo-store.ru
   ```
3. Устанавливаем `grafana` и `prometheus`
   ```
   helm install grafana --set host=$MOMO_DOMAIN --namespace=monitoring infrastructure/kubernetes/monitoring/grafana-0.17.0.tgz
   helm install prometheus --set host=$MOMO_DOMAIN --namespace=monitoring infrastructure/kubernetes/monitoring/prometheus-0.0.1.tgz
   ```
4. Устанавливаем Loki
   ```
   helm repo add loki https://grafana.github.io/loki/charts
   helm repo update
   helm upgrade --install loki loki/loki-stack --namespace=monitoring
   ```