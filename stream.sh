#!/bin/bash

# ==========================================
# بياناتك الثابتة
# ==========================================
KICK_CHANNEL="klash"
YOUTUBE_KEY="p0ky-h9m9-cywd-wy8v-2yra"
RESTREAM_KEY="re_12215822_event12d2d60d5f814c68b3c0f0137cacab10"

# المتغيرات المستلمة من لوحة التحكم
QUALITY=${STREAM_QUALITY:-best}
DEST=${STREAM_DEST:-both}

echo "========================================"
echo "قناة Kick المستهدفة : $KICK_CHANNEL"
echo "الجودة المطلوبة     : $QUALITY"
echo "منصات البث          : $DEST"
echo "========================================"

# جلب الرابط بالجودة المطلوبة
KICK_M3U8=$(streamlink "https://kick.com/$KICK_CHANNEL" "$QUALITY" --stream-url)

if [ -z "$KICK_M3U8" ]; then
  echo "لا يوجد بث حالياً. إعادة المحاولة بعد 5 دقائق..."
  sleep 300
  gh workflow run main.yml -f destination="$DEST" -f quality="$QUALITY"
  exit 0
fi

# تحديد مسار البث للمنصات
if [ "$DEST" == "youtube" ]; then
    OUTPUT="[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
elif [ "$DEST" == "restream" ]; then
    OUTPUT="[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"
else
    OUTPUT="[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY|[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"
fi

echo "جاري تشغيل FFmpeg وتوجيه البث بأعلى جودة بدون تقطيع..."

# تم تصحيح صيغة الـ timeout لتجنب أي خطأ في قراءة الوقت
ffmpeg -re -i "$KICK_M3U8" \
  -c:v copy -c:a copy \
  -f tee "$OUTPUT" &

FFMPEG_PID=$!

# ضبط مؤقت لإنهاء البث بسلاسة قبل انتهاء الـ 6 ساعات بـ 15 دقيقة (5 ساعات و 45 دقيقة)
sleep 20700

echo "انتهت الدورة الحالية، جاري إيقاف FFmpeg وبدء دورة جديدة فوراً..."
kill $FFMPEG_PID

gh workflow run main.yml -f destination="$DEST" -f quality="$QUALITY"
