#!/bin/bash
# ═══════════════════════════════════════════════════
# 🔥 ÖZSES V8 — VPS Deploy Script
# ═══════════════════════════════════════════════════
# Bu scripti VPS üzerinde çalıştır:
# bash deploy.sh

set -e

echo "═══════════════════════════════════════════"
echo "  🔥 ÖZSES V8 — VPS Deploy Başlıyor"
echo "═══════════════════════════════════════════"

# 1. Eski servisleri temizle
echo "🗑️  Eski PM2 servisleri durduruluyor..."
pm2 delete all 2>/dev/null || true
pm2 flush 2>/dev/null || true

# 2. Dizin oluştur
echo "📁 Dizinler oluşturuluyor..."
mkdir -p /root/ozses_v8/cookies

# 3. yt-dlp güncelle
echo "⬆️  yt-dlp güncelleniyor..."
pip3 install -U yt-dlp 2>/dev/null || pip install -U yt-dlp 2>/dev/null || {
  echo "  yt-dlp pip ile yüklenemedi, curl ile deneniyor..."
  curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
  chmod a+rx /usr/local/bin/yt-dlp
}
echo "  yt-dlp sürümü: $(yt-dlp --version)"

# 4. Cookie dosyalarını kopyala
echo "🔑 Cookie dosyaları hazırlanıyor..."
if [ -f /root/cookies.txt ]; then
  cp /root/cookies.txt /root/ozses_v8/cookies/cookie_1.txt
  echo "  ✅ cookies.txt → cookie_1.txt"
fi
# Eski backend'lerden cookie'leri de al
for f in /root/backend/cookies.txt /root/ozses_backend/cookies.txt /root/backend_proxy/cookies.txt; do
  if [ -f "$f" ]; then
    name=$(echo "$f" | md5sum | cut -c1-8)
    cp "$f" "/root/ozses_v8/cookies/cookie_${name}.txt"
    echo "  ✅ $f → cookie_${name}.txt"
  fi
done

# 5. Node.js bağımlılıklarını kur
echo "📦 npm install..."
cd /root/ozses_v8
npm install --production 2>&1

# 6. PM2 ile başlat
echo "🚀 Sunucu başlatılıyor..."
pm2 start ozses_server.js --name ozses-v8 --max-memory-restart 200M
pm2 save
pm2 startup 2>/dev/null || true

# 7. Sağlık kontrolü
echo ""
echo "═══════════════════════════════════════════"
sleep 2
curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/health
echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ ÖZSES V8 Karargah AKTIF!"
echo "  📡 http://$(hostname -I | awk '{print $1}'):8080"
echo "═══════════════════════════════════════════"
