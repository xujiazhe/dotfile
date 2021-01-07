
# --write-sub   --convert-subs=srt -k


youtube-dl -o 'ds.mp4'  \
	--sub-lang zh-CN --write-sub --embed-subs -i \
	-k  -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]'  \
	--postprocessor-args "-ss 00:14:30 -t 00:16:05" \
	'https://www.youtube.com/watch?v=eBhqC4nqe_E'

#内嵌字幕的  时间不准的
youtube-dl -o 'ds2.mp4'  \
	--sub-lang zh-CN   --convert-subs=srt --write-sub  --embed-subs -i \
	-k  -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]'  \
	--postprocessor-args "-ss 00:14:30 -t 00:16:05" \
	'https://www.youtube.com/watch?v=eBhqC4nqe_E'
