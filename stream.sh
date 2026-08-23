#!/bin/bash

# ==========================================
# إعدادات البث (يمكنك تغيير اسم قناة كيك بسهولة من هنا)
# ==========================================
KICK_CHANNEL="klash"
YOUTUBE_KEY="p0ky-h9m9-cywd-wy8v-2yra"
RESTREAM_KEY="re_12215822_event12d2d60d5f814c68b3c0f0137cacab10"

echo "جاري البحث عن البث في قناة كيك: $KICK_CHANNEL..."
KICK_M3U8=$(streamlink "https://kick.com/$KICK_CHANNEL" best --stream-url)

if [ -z "$KICK_M3U8" ]; then
  echo "لا يوجد بث حالياً. إعادة المحاولة بعد 5 دقائق..."
  sleep 300
  gh workflow run main.yml
  exit 0
fi

echo "تم العثور على البث! جاري التحويل إلى يوتيوب وريستريم..."

# تشغيل FFmpeg مع خاصية copy للحفاظ على الجرافيكس والدقة الأصلية 100% دون تقطيع
timeout 5h 45m ffmpeg -re -i "$KICK_M3U8" \
  -c:v copy -c:a copy \
  -f tee "[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY|[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"

echo "انتهت دورة الـ 6 ساعات. جاري تشغيل سيرفر جديد فوراً للاستمرار 24/7..."
gh workflow run main.yml
