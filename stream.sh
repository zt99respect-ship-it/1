#!/bin/bash

# ==========================================
# بياناتك الثابتة
# ==========================================
KICK_CHANNEL="klash"
YOUTUBE_KEY="p0ky-h9m9-cywd-wy8v-2yra"
RESTREAM_KEY="re_12215822_event12d2d60d5f814c68b3c0f0137cacab10"

# المتغيرات المستلمة من لوحة التحكم (إذا كانت فارغة يعتمد القيم الافتراضية)
QUALITY=${STREAM_QUALITY:-best}
DEST=${STREAM_DEST:-both}

echo "========================================"
echo "قناة Kick المستهدفة : $KICK_CHANNEL"
echo "الجودة المطلوبة     : $QUALITY"
echo "منصات البث          : $DEST"
echo "========================================"

# جلب الرابط مع الجودة التي اخترتها من لوحة التحكم
KICK_M3U8=$(streamlink "https://kick.com/$KICK_CHANNEL" "$QUALITY" --stream-url)

if [ -z "$KICK_M3U8" ]; then
  echo "لا يوجد بث حالياً. إعادة المحاولة بعد 5 دقائق..."
  sleep 300
  gh workflow run main.yml -f destination="$DEST" -f quality="$QUALITY"
  exit 0
fi

# تجهيز مخرج FFmpeg بناءً على اختيارك في الموقع
if [ "$DEST" == "youtube" ]; then
    OUTPUT="[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
elif [ "$DEST" == "restream" ]; then
    OUTPUT="[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"
else
    # الخيار الافتراضي: كلا المنصتين معاً
    OUTPUT="[f=flv]rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY|[f=flv]rtmp://live.restream.io/live/$RESTREAM_KEY"
fi

echo "جاري تشغيل FFmpeg وتوجيه البث..."

# النقل الحرفي (copy) لحماية الجرافيكس من التدمير والتقطيع
timeout 5h 45m ffmpeg -re -i "$KICK_M3U8" \
  -c:v copy -c:a copy \
  -f tee "$OUTPUT"

echo "انتهت دورة البث، جاري بدء دورة جديدة أوتوماتيكياً بنفس إعداداتك..."
gh workflow run main.yml -f destination="$DEST" -f quality="$QUALITY"
