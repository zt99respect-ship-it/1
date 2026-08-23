#!/bin/bash

# قراءة المتغيرات القادمة ديناميكياً من الواجهة أو القيم الافتراضية
KICK_CHANNEL="${KICK_CHANNEL:-klash}"
YOUTUBE_KEY="${YOUTUBE_KEY}"
RESTREAM_KEY="${RESTREAM_KEY}"
QUALITY="${STREAM_QUALITY:-best}"
DEST="${STREAM_DEST:-both}"

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
  gh workflow run main.yml -f kick_channel="$KICK_CHANNEL" -f youtube_key="$YOUTUBE_KEY" -f restream_key="$RESTREAM_KEY" -f destination="$DEST" -f quality="$QUALITY"
  exit 0
fi

echo "جاري بدء البث بأعلى جودة وتجاوز قيود الترويسة..."

# تشغيل البث بناءً على الاختيار
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

# مؤقت لضمان استمرار البث وتجديد الدورة قبل انتهاء حد الـ 6 ساعات
sleep 20700

echo "انتهت الدورة الحالية، جاري تجديد السيرفر للبث 24/7..."
killall ffmpeg

gh workflow run main.yml -f kick_channel="$KICK_CHANNEL" -f youtube_key="$YOUTUBE_KEY" -f restream_key="$RESTREAM_KEY" -f destination="$DEST" -f quality="$QUALITY"
