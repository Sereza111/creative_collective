# HTTPS для arc303.ru при работающем nginx (бот)

**nginx на 80/443 не отключаем** — он нужен боту.

Caddy **не** занимает 80/443. В Docker: `127.0.0.1:8081:80`. Сертификаты — **certbot** на хостовом nginx.

Пошагово: [NGINX_BOT_AND_ARC303.md](./NGINX_BOT_AND_ARC303.md)

## Кратко

1. Portainer: `web` → `127.0.0.1:8081:80`, API → `8080:3000`
2. `sudo cp deploy/nginx-host-arc303.conf /etc/nginx/sites-available/arc303.conf` + `nginx -t` + `reload`
3. `sudo certbot --nginx -d arc303.ru -d api.arc303.ru`

## Диплом без HTTPS

```powershell
flutter build windows --dart-define=API_BASE_URL=http://93.189.230.198:8080/api/v1
```
