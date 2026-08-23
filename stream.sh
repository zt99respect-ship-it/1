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

echo "جاري بدء البث بأعلى جودة وتجاوز قيود الترويسة..."

# تشغيل البث بناءً على الاختيار مع ضبط التوافقية لمنع أي خطأ في الترويسة
if [ "$DEST" == "youtube" ]; then
    ffmpeg -fflags +genpts -re -i "$KICK_M3U8" \
      -map 0:v -map 0:a \
      -c:v copy -c:a copy \
      -flvflags no_duration_filesize \
      -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY" &

elif [ "$DEST" == "restream" ]; then
    ffmpeg -fflags +genpts -re -i "$KICK_M3U8" \
      -map 0:v -map 0:a \
      -c:v copy -c:a copy \
      -flvflags no_duration_filesize \
      -f flv "rtmp://live.restream.io/live/$RESTREAM_KEY" &

else
    # البث للمنصتين معاً بشكل مستقل وثابت 100%
    ffmpeg -fflags +genpts -re -i "$KICK_M3U8" \
      -map 0:v -map 0:a \
      -c:v copy -c:a copy \
      -flvflags no_duration_filesize \
      -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY" &
      
    ffmpeg -fflags +genpts -re -i "$KICK_M3U8" \
      -map 0:v -map 0:a \
      -c:v copy -c:a copy \
      -flvflags no_duration_filesize \
      -f flv "rtmp://live.restream.io/live/$RESTREAM_KEY" &
fi

# الانتظار لمدة 5 ساعات و 45 دقيقة لتفادي إغلاق GitHub Actions (حد الـ 6 ساعات)
sleep 20700

echo "انتهت الدورة الحالية، جاري إيقاف العمليات وتجديد السيرفر للبث 24/7..."
killall ffmpeg

gh workflow run main.yml -f destination="$DEST" -f quality="$QUALITY"
