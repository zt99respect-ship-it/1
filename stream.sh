#!/bin/bash

echo "جاري البحث عن البث في قناة كيك..."
KICK_M3U8=$(streamlink "https://kick.com/$KICK_CHANNEL" best --stream-url)

if [ -z "$KICK_M3U8" ]; then
  echo "لا يوجد بث حالياً. إعادة المحاولة بعد 5 دقائق..."
  sleep 300
  gh workflow run main.yml -f kick_channel="$KICK_CHANNEL" -f youtube_key="$YOUTUBE_KEY" -f restream_key="$RESTREAM_KEY"
  exit 0
fi

echo "تم العثور على البث! جاري التحويل إلى المنصات..."

# تشغيل FFmpeg مع خاصية copy للحفاظ على الجرافيكس الأصلي 100%
timeout 5h 45m ffmpeg -re -i "$KICK_M3U8" \
  -c:v copy -c:a copy \
  -f tee "[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY|[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"

echo "انتهت دورة الـ 6 ساعات. جاري تشغيل سيرفر جديد فوراً للاستمرار 24/7..."
gh workflow run main.yml -f kick_channel="$KICK_CHANNEL" -f youtube_key="$YOUTUBE_KEY" -f restream_key="$RESTREAM_KEY"

