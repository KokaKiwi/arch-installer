#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="1761233743"
MD5="16a6f16b355244439c5241d5421c3abe"
TMPROOT=${TMPDIR:=/tmp}

label="arch linux installer"
script="./install.sh"
scriptargs=""
targetdir="build"
filesizes="1715"
keep=y

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_Progress()
{
    while read a; do
	MS_Printf .
    done
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{print $4}'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.1.5
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target NewDirectory Extract in NewDirectory
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    MS_Printf "Verifying archive integrity..."
    offset=`head -n 402 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test `basename $MD5_PATH` = digest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test $md5 = "00000000000000000000000000000000"; then
				test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test "$md5sum" != "$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test $crc = "0000000000"; then
			test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test "$sum1" = "$crc"; then
				test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc"
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    echo " All good."
}

UnTAR()
{
    tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
}

finish=true
xterm_loop=
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 36 KB
	echo Compression: gzip
	echo Date of packaging: Sat Mar 23 17:54:10 CET 2013
	echo Built with Makeself version 2.1.5 on linux-gnu
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \"build\" \\
    \"installer.sh\" \\
    \"arch linux installer\" \\
    \"./install.sh\""
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"build\"
	echo KEEP=y
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=36
	echo OLDSKIP=403
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	arg1="$2"
	shift 2
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
	shift 2
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	echo "Creating directory $targetdir" >&2
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target OtherDirectory' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 402 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 36 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

MS_Printf "Uncompressing $label"
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test $leftspace -lt 36; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (36 KB)" >&2
    if test "$keep" = n; then
        echo "Consider setting TMPDIR to a directory with more free space."
   fi
    eval $finish; exit 1
fi

for s in $filesizes
do
    if MS_dd "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) | MS_Progress; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
echo

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ã 2ﬁMQÌZYo‚HÊŸø¢∆·!DÄ1ßîª íA ¿n“éòcÇÖ‰#…f~˚Vw€∆6êdvç˙{ ‹ut◊—ÂÓJäRfÔ(!µZ¶T©î Â*>7Í’≤L«d‰≤\ÆTjçRΩú)…rΩQ @-s ¯Æß8 ôôÊ<Ë⁄Ë~ü∂–=Mùç %πë˘uPî‹ïÎifq"Ω£¯W™ï:èˇÅ„_*çfö2—ú}ƒø^≠ÓéΩñäMñÂîx¸˜é£“X∑$w&™‚¡«èÌﬁ•Äv⁄ v,tçaË÷=9R,ä°g8~ù˝oËcwøáÄüØˇÂ:íy˝?\¸ßæ•z∫mπEw∂ó¯øPˇÀïÍf˝o˙G–$Ä¡mÁ∫œ~¬¬±ÕÖwúÉ'†∞ 1+√0[æ;«\ﬂ(Yü¬ƒeñâ–ƒÓŒ¿õiÂ `/ïlY§#S]àí¬s8ıh¢;—Ù¯ªô=f≤ë™…1ä¡#Æ©>≈ùGä˛¥˚∑ù^∑Iî–ëãˆÂ˘‡˙∂I◊C≠	HhN`O⁄†Hv•πëQÙ[U\B†ØEÜ_Wwìèa[ªˆ›;»AÎsØ”jèæÙØö‚´d›âggkÅÆÖ¯1ÏŸÃ+©õ`>yIõÊ*™êäfË»Æ≈R±e¶∞Å◊,aû'ﬁ8É1Œ2¡∆kŸ[XO"rÉ$5Ö§ä¢Œï{-
/Ÿ»ıq
ŸBˆ≠≠K¬ Üâ˝›2le—[≈lÚcù *>A°ák¡4° ¥0/¶uaête2,ltÙdü‚≥tr;≤ë∫UÃÍb‹ß‘¯9à˘Ç‡€—…∑£ç—ì\‚qù∫Ö%SºëØqLuC≥S√}5∆•êüT*∑ïõDc'ƒ££#¯‘æÍ`Öz«ƒ≠"dñWtµªØi
 G1ˇ–°ï√∂4å?ÊΩ˛7uK7cèÄqˇØUyˇÁ‡ÒóK#¨ò¶b8˛r£ë>ˇï+e~˛{˜ /^•.Ì∞,ÅÇíiyP(®ä:”5Gü•≈ëËàƒ•≈¸
˝”‰Æ\C∑¸%Ô$º∑˝øØ‡´ıøQ›ÿˇrùÔˇw‘ˇ≥ÕT	‡õ˜WŸˇ:Û>?o€ˇ5πöﬁˇïFâ˜ΩˇozΩ€—EÁÔÑ§EÄº¸„ãùﬁƒ≤•\N»Â÷–«Ùzä∞&‚˙ä[Ñ,éÙ˙uò>ù˜€–Íu/;Waü©”Ìﬂû__ø>Î˘MÎsY|:T0sB¢qóÉnãt2b,›ÚF™mMı˚Ë¶ŒÍZs∏ÓµŒØÉEnŒi3$Fcb·q◊•©ûÌ¨¢õÁ)dcÜƒeŒu¡6)à2ƒ¶—óN∑≥!¡˛‹íö)îËÌßHfzæ£Å∑ZhÒeQ∑âÒæV÷wµ—D{–Uçu∂Hª&Ÿ+HôKy„m‘‘åP—fGØ˘v–¶äi˚.t‘∫ÈË˙Ë8>Å¥plï4ˇËq.Ü2‡˜V:zï“ÒõŒÈÔöî Yü»dyTòG°g"e]ø}ùÓÉ€Ìπºncn…“¿ågLN¯>”çvoS4õ`[˝ß)ËfårÆô Kûπ)òI¢Ê2DÃ‰T/¢√¢‘¡Ÿw‚ œÛz"Q~«ôÑ∑ÁZ“ÓTZ≈Mß)ú ÔÚ À◊cmyJSBr' _πXcã-Ó∆;f‹hö•Ê◊Ì® Á©kIÛ7^u÷n`æjŸñá˜‚!ÊÀNoº•ÓAâ*bª}N≤∞Nº ja÷ôÓ=™∆ ÈësZ~=8•9&^“¶ ∆kç9ß˛ä©ì‰3”z¥Gâ‚∞Üïâ4ÁËaƒôÁ-N%ºM8EíHÙäWú:“œ_™ö§Œ€ˆ§5âYâ*z˜è¢@€≥èK\ÔãlÅQ/0É5ôô;“&-¢∆P_´ê4OïÕµçá"âe‹9iö+])'˛l≈˝Bë•%w]Z™úm&Æ{9êbÃ4‘¥’QÈÌ¸)}=œ„Î:x|Np?ë‚G´ :*Ô¯VKEùê£œÛƒÒœ[\@◊µ q4:)D◊M~ã H4	i¥>éFÒxë+ˆï¢Kk
T—<ID	ËÈg¨†û›“òpoôƒﬂô	€¸˛€Õ¶êÚ∫íL[◊ó“≥Õ$L[]êíç<Ä;ô¸]i¿oYˇ/˛y¡◊™ P  