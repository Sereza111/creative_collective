#!/usr/bin/env bash
# Только диагностика: кто слушает 80/443.
# Если nginx для бота — НЕ останавливай. См. docs/NGINX_BOT_AND_ARC303.md

echo "=== 80 / 443 на хосте ==="
ss -tlnp 2>/dev/null | grep -E ':80 |:443 ' || echo "(свободно)"

echo ""
echo "=== Docker: только ХОСТ-порты 80 или 443 ==="
docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null | grep -E '0\.0\.0\.0:80->|0\.0\.0\.0:443->' || echo "(нет)"

echo ""
echo "Если nginx — для бота: не stop nginx."
echo "arc303: compose web = 127.0.0.1:8081:80 + deploy/nginx-host-arc303.conf + certbot"
