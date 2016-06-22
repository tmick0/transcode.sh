#!/bin/bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# transcode.sh
# a simple transcode script
# version 13-07-23
# by le1ca <root at lo dot calho dot st>
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# code is covered by mit license, see LICENSE file included in this repo
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# this script is by no means perfect
# pull requests and issues will be attended to, you are welcome to contribute
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# prerequisites:
#  bash
#  flac
#  metaflac
#  lame
#  perl
#  mktorrent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# configuration: enter the announce url(s) for your tracker(s) below
announce[0]=http://example-tracker.com:8080/path/announce
#announce[1]=http://another-tracker.net:8888/path/announce
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# usage:
#  $ /path/to/transcode.sh <options> "Directory Containing FLAC Files"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# options: (they are case sensitive!)
#  -v0          create lame mp3 -V 0
#  -v2          create lame mp3 -V 2
#  -320         create lame mp3 cbr 320
#  -mp3         create all of the above mp3 formats
#  -flac        move flacs and make a torrent
#  -all         equivalent to -mp3 -flac
#  -tracker<n>  where n is an integer, use announce[n] as the announce url
#                   (required if more than 1 url is specified above)
#  -keep        don't delete original directory after transcoding
#                   (it is deleted by default)
#  -notorrent   don't make .torrents
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# example:
#  $ ~/transcode.sh -mp3 "Artist - 2010 - Album"
#  this will create the following directories and files:
#   Artist - 2010 - Album [320]/
#   Artist - 2010 - Album [V0]/
#   Artist - 2010 - Album [V2]/
#   Artist - 2010 - Album [320].torrent
#   Artist - 2010 - Album [V2].torrent
#   Artist - 2010 - Album [V0].torrent
#  the original directory will be deleted if -keep is not specified
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# begin script, do not edit below this line or something will probably break
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

mp3v0=
mp3v2=
mp3320=
flac=
wav=
keepdir=
filepath=
notorr=
selectedtracker=

if [[ ${#announce[@]} == 1 ]]; then
    selectedtracker=announce[0]
fi

for arg in "$@"; do
	if [ "$arg" = "-all" ]; then
		mp3v0=true
		mp3v2=true
		mp3320=true
		flac=true
		continue
	fi
	
	if [ "$arg" = "-mp3" ]; then
		mp3v0=true
		mp3v2=true
		mp3320=true
		continue
	fi
	
	if [ "$arg" = "-flac" ]; then
		flac=true
		continue
	fi
	
	if [ "$arg" = "-v0" ]; then
		mp3v0=true
		continue
	fi
	
	if [ "$arg" = "-v2" ]; then
		mp3v2=true
		continue
	fi
	
	if [ "$arg" = "-320" ]; then
		mp3320=true
		continue
	fi
	
	if [ "$arg" = "-keep" ]; then
		keepdir=true
		continue
	fi
	
	if [ "$arg" = "-notorrent" ]; then
		notorr=true
		continue
	fi
	
	if [[ "$arg" =~ ^\-tracker([0-9]+) ]]; then
	    selectedtracker=${announce[${BASH_REMATCH[1]}]}
	    continue
	fi
	
    filepath="$arg"
done

if [ -z "$filepath" ]; then
	echo "error: no file path provided."
	exit
fi

if [ ! -d "$filepath" ]; then
	echo "error: path \"$filepath\" doesnt exist."
	exit
fi

if [ -z "$selectedtracker" -a -z "$notorr" ]; then
    echo "error: no tracker selected."
    exit
fi

if [ -z "$mp3v0" -a -z "$mp3v2" -a -z "$mp3320" -a -z "$flac" ]; then
    echo "error: no output formats provided"
	exit
fi

if [ $mp3v0 ]; then
	mkdir "$filepath [V0]"
fi
if [ $mp3v2 ]; then
	mkdir "$filepath [V2]"
fi
if [ $mp3320 ]; then
	mkdir "$filepath [320]"
fi
if [ $flac ]; then
	mkdir "$filepath [FLAC]"
fi

workdir=`pwd`
cd "$filepath"

for file in *.flac; do
	cd "$workdir"
	thisTitle=`metaflac --show-tag=TITLE "$filepath/$file"`
	thisTitle=$(printf '%q' "$thisTitle")
	thisTitle=`perl -e "my @stuff = \"$thisTitle\" =~ /^(.+?)\=(.+)/; print @stuff[1];"`
	thisArtist=`metaflac --show-tag=ARTIST "$filepath/$file"`
	thisArtist=$(printf '%q' "$thisArtist")
	thisArtist=`perl -e "my @stuff = \"$thisArtist\" =~ /^(.+?)\=(.+)/; print @stuff[1];"`
	thisAlbum=`metaflac --show-tag=ALBUM "$filepath/$file"`
	thisAlbum=$(printf '%q' "$thisAlbum")
	thisAlbum=`perl -e "my @stuff = \"$thisAlbum\" =~ /^(.+?)\=(.+)/; print @stuff[1];"`
	thisYear=`metaflac --show-tag=DATE "$filepath/$file"`
	thisYear=`perl -e "my @stuff = \"$thisYear\" =~ /^(.+?)\=(.+)/; print @stuff[1];"`
	thisTrack=`metaflac --show-tag=TRACKNUMBER "$filepath/$file"`
	thisTrack=`perl -e "my @stuff = \"$thisTrack\" =~ /^(.+?)\=(.+)/; print @stuff[1];"`
	echo "Decompressing $file to wav..."
	flac -sd "$filepath/$file" -o "$filepath/${file%.flac}.wav"
	if [ $mp3v0 ]; then
		echo "Converting ${file%.flac}.wav to V0..."
		lame --silent --tt "$thisTitle" --ta "$thisArtist" --tl "$thisAlbum" --ty "$thisYear" --tn "$thisTrack" -V 0 "$filepath/${file%.flac}.wav" "$filepath [V0]/${file%.flac}.mp3" &
	fi
	if [ $mp3v2 ]; then
		echo "Converting ${file%.flac}.wav to V2..."
		lame --silent --tt "$thisTitle" --ta "$thisArtist" --tl "$thisAlbum" --ty "$thisYear" --tn "$thisTrack" -V 2 "$filepath/${file%.flac}.wav" "$filepath [V2]/${file%.flac}.mp3" &
	fi
	if [ $mp3320 ]; then
		echo "Converting ${file%.flac}.wav to 320..."
		lame --silent --tt "$thisTitle" --ta "$thisArtist" --tl "$thisAlbum" --ty "$thisYear" --tn "$thisTrack" -b 320 "$filepath/${file%.flac}.wav" "$filepath [320]/${file%.flac}.mp3" &
	fi
	wait
	rm "$filepath/${file%.flac}.wav"
	if [ $flac ]; then
		echo "Moving $file..."
		mv "$filepath/$file" "$filepath [FLAC]/"
	fi
done

if [ -z "$notorr" ]; then
	if [ $mp3v0 ]; then
		mktorrent -a $selectedtracker -p "$filepath [V0]"
	fi
	if [ $mp3v2 ]; then
		mktorrent -a $selectedtracker -p "$filepath [V2]"
	fi
	if [ $mp3320 ]; then
		mktorrent -a $selectedtracker -p "$filepath [320]"
	fi
	if [ $flac ]; then
		mktorrent -a $selectedtracker -p "$filepath [FLAC]"
	fi
fi
if [ -z "$keepdir" ]; then
	rm -r "$filepath"
fi

echo "Done."
exit
