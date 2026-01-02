Write-Host "=== Guestbook App Deployment Script ===" -ForegroundColor Cyan
Write-Host "Скрипты развертывания приложения" -ForegroundColor Yellow
Write-Host ""

Write-Host "Доступные скрипты:" -ForegroundColor Green
Write-Host "1. deploy-frontend.ps1 - Развертывание фронтенда в Object Storage"
Write-Host "2. deploy-backend.ps1 - Развертывание бэкенд-функций"
Write-Host "3. create-api-gateway.ps1 - Создание API Gateway"
Write-Host "4. init-database.ps1 - Инициализация базы данных YDB"