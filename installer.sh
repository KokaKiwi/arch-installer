#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="2089520901"
MD5="da8145f7c67c50a73f921ea58704ea25"
TMPROOT=${TMPDIR:=/tmp}

label="arch linux installer"
script="./install.sh"
scriptargs=""
targetdir="build"
filesizes="6073"
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
	echo Uncompressed size: 52 KB
	echo Compression: gzip
	echo Date of packaging: Sat Mar 23 17:52:48 CET 2013
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
	echo OLDUSIZE=52
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
	MS_Printf "About to extract 52 KB in $tmpdir ... Proceed ? [Y/n] "
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
if test $leftspace -lt 52; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (52 KB)" >&2
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
‹ àİMQì=kWÛH²ùì_ÑÎ€3ø	Iî%ëÌ0„‚³¶™Ù’ãÈrÛÖ"K^= ÃşŸû7î/»UÕ-©%K`˜	gî|fƒİêêªêzuI[©>ûæŸ|Ş¼zõ¬¶µUk4¶á÷›×Û:µËÏ³z£ŞØÚzõúÍvíY­^ı¦ñŒ½zöŸÀóu—±gSî^˜|0ÉÇç¦Ïé Q«¿yö×ùTªŞÂóù¬2ªş‰ø¿µøÿ¸ü¯ÕS®¸û-øÿz{;Ÿÿ¯_¥øÿª^ßzÆjOüÿæŸµçÕ¡iW½i¡`è>ûÛßÚƒìÓaÚ‘¤±,Ó0)#•ŠVÀşgOŸ¿Îù·Ì¡÷m€ûëÿÆëÆÖ“şDş½±õMùŸ¯ÿ‘é´ığ¤ÿQÿu° kl-ÿ½»0ˆõ¦Ü²ØA`¾éØìØºº»¸k.ô·ê¸;ìØ	.]nûfà±¿Yñ'3İ´*†3{£÷ÛwÍa€‹xl¸Øa×m“½\ï\7mnÌ=g¾pÍÉÔgÿû?8S£Ö.·¸îñlğf˜?åÌ\X†~<fÜõ h…†îsÏpÍ9®²Cı©é1øOgmTt3Kl³Â|f j€‚ÇÆ’,¶ÓĞm6„¥ÀfÂÚC¤ÉÜu&®>“LÛ°‚g¸/A+¬¦õwÌ3gsşà 4¾ê¨M¶pZ)ğ8ƒ•˜~TÓ‡WĞÑ= ÆFÌ€¶€0
© èü‹¾Çæú„
…İŞÁñàçv·wÔ9ijJ­Vr_/oiA!‡ÙÏøÈô&cÓâöw87EÎLÜšï j®$LÔmXˆíš°e\ıBwMD¨á0cªÛj7]è±Â§`Ú l£Ä®Ÿ5ñ/°iLØÌHŞÔ¹ôà«Ë‘“CÈàş<ğ*,ÎÍ¸´åLU¯"aüŒ‹ì°¬ï¸°'¶±`Uf—”…öÛ»§‡MÛ¡ršüÓ[xÑó@iü6ãTô”éæ˜=g#>ñ±ãÎá~«ß>èt?´úÔ{µé~İMíÅ½àìÅûv^ô4663¡ÛË aØÓŠ55›LÃó¬±/Qob¨\Ÿ 5a/ÿÊ:¹åñì‘¼Ã£^‰ ü“`XÛ&‘¬²‘éÑ7˜7!avàh!_VçÊÚ'­İãö~&QÃÎ‹YDì}êİ
&Ù¿¤~ë0
ô5‹µ\B‚ü¨AÔ-E¹¢éÉ·ÇrÌêB8»íöI¢£!:>µ;¿$z¶DÏîñi;Ñ¾-Ú?´Û'ıV¢ë•èÚûÔJ.òZ‚ê‡Xk¤ÉÓsĞ:=î‡ã'nM‹÷Ûì*°†‰¤û›Iw*ûIw%·”îUv•îz­eúİ uÈƒh¢ñÛÅ	ÆÄ˜_–>ÓÉÎt÷\å dß;t¥Ï¯æ ‹d_‚ï=gÆÙ:¨MîÚºµÎP3oÎsl±ª¬¨õú­nğK«¿÷¾©i…€(‘4&9;cÅëçõò?oPĞ×O7ìËŒÚÜå~à‚…¨¡ëÑ:hñB™Ş üK¤BI-¯ƒíáöÄŸ²w¬¦@¨3Äİ½4A]À¦¦º7 ñ*°@²X»¬¬ÎXÙ&¿·ËJ,Äj9êFv×sv62]°t» V#¼|Ì£‘1Rİ "9­Z×–qLà·R.Ÿ–î–HŞ‰ÊAjü e9—Ü5ÀQ«æ‚Pã’¾C­Ñr"€KıÆ|—­Ÿíó9ww¾¬ãwßÓiÌdj½rM]%„Ü±Á#
Á£316]p@à8úÌAÒŠ…6Aä,sfúä€18ØdV¼¹n€¥F,\s–D¡Ñe?˜Í-øIèµháA-ğ@¸VÄ%vjàØ G\şï ¤h„.ú'11\H¨¤v¯Z©I[V) ;„şnû1§ö¦Ü8÷–*j@S[h¸;Œ§†ˆ-à¢ºqˆV|TU4|Ö±9	\‚à¿"³ë#ê¢}ÀÉv7ìçV—ğ~n¡-)np8òbŸ‹Eè()2ª£‘Â'Y ¼²ß~Ëî„= Z2£	‰N8'‘\KY—DëO…ƒ†î0nó_è©‚¢÷")ŞªpC@¥»|Î!P±K´¨İçì;æ›3ä=zÒpş€® òÉO…ŸÙ“	ö"á]®†*azJµ”} RìChLc‘¨°5Ü$I5rısù‹¹ó\["Šè¥'Â‹\Vá„…2ªú*Ú$ ƒçMw'@ˆxHÎ¡¨{„2I>#ªDBÏrH¢e!Õ›¤Ëvñ–’´}lkD”dèa7¿?¿×Š	—[ûZP­Qd¾Ôn÷{ıîÑ	8EÊŠ´<+³¢@»İ«NB(—ŸÍı…]l¢GlÚè¦€‘âæ¨\ÖT“¨î"ŸÔù[‘Z(ÆGcïŞÉtûW],CÒ3×[Kş
+İr¹>Z„§Ñ“ç°J§ĞóõÙ¢M!–¨şCaLÃ@YÈ#»eQåğjÙìŠ]8GÊA‚°ÊÄømÑÜB£BØ¬#×j¼dLÆ“>Bí¢[&0#bAs‰+ê#t¶ò+1p=™èGvN=‰¸ ÔcÕä¡œ¡¦ƒ#	1 ·§’4ı?Z‚î©/V¬
3OUeKŠi¯sÜéŠÓ‡Añ©¡îåÓÎ’¡A¤
KÇNKğ ¤Ï0›1£ÃUT!}Sm¿sÒéÓµ|‚‘'‰£,£ç4äEæIı6¸$4‘—@{å‡–Mî2ƒDr):L¡aÈA·¶,£s"ú’eßHQŸö’šº½_44ZKo÷ ,‡³´·iLÌÜ9.š(™"ófÉ¢Mòw'Ü6·I}ˆjûC»åŞ'Ñ¬)×±„nq×_|ë¸İíß4(5Ñ*Ğ÷ºGı£½Öñ½ (¼
iºİN÷^ /u×FÑ[ø/­î	š¤û€oÈ4bç;8œ½£½ö½`›öØYòÑÉAç^pG”ß¼0%(ïÙ9_…ÎŸîKâ÷>†“º
èƒx'û÷í˜loB÷N÷ö ï^Ğçºç…aÓ­À?¶z½{`»hmTW\fÙ¥½÷T¯ûô‹c~L_-Ó9ºÃw"ŒÙxp¾|R¥ÈFÀğ.ÄÂˆõÀòãñíĞ‚'Ìft~Â˜Ùƒº‹e‹’K›ÈÁàWsÔâ¡‰lR„¸Épz3)³)©OUÇ/­f;šPËr.©Ü(.LY¶a²K-b†´HwÚDÕxˆ$xÂúŒ8ºh¨DÄû=–J]9G¼pÈC,ÕŠ n©V\à!–jEĞµT+‚¥Zö½-ÕŠp`©V„|?Kµ:‰`©VşKµ"èZª¡?ÈR­ ÛÀ|å²²ßû°‹¢——%káÕe"’B¢¶ŠEQÄ‰°®y&.uÉ/g‘"t<“r¼dğ¨dÀÅâØÑ9—,˜“­c‰TtP¶”bŸ9ä¾j›)ä’:|Dµ
h‹°4Y^JÔ
³ÿĞ¼d†Éøba•:x˜{–F]\x³ŞêÖP/9m€ª’•)ibTF¡Q£õ0iq95D|ˆ×AJ¡àê—Ël8™“"ˆ(:¤Œ§ŠlÅ}Öm÷0±ù•îâ #ïk¹ŞˆÃAeÈÕÔ1>³¢ìO÷"1|#VLá'àË6ÓÎÄ	„"ŞqRù‡hFÂyHÌ/)ÏÍplVe:ÁÊÅâ=†iàÕP˜Y+¤üA¼%ÂS]µH”(eM­‘+ÀJ‰”B«ÎÙtÃƒ~Ş¾¥Ÿää€{Ùı@†v?jÔ}?¨dïs½Lc+Ã¤ßÒÎç»5–W\hgƒV>²ìÍ…Œ·á™d@ŸKêÌŠ7å™@É¼çB½9ìJäc°”¢6ĞW¬Är@So>ÂTL‰±°ïùÄ%ÀÚı„A˜Ç\de÷=‘G\Xõ\Ğaÿıé@ÿ 58í¶ÙoLø&yœ”½¹ËäRæe6ÀÓàşÑIzVÖéànXŠñ‰İMhåHÍ¶ñâ”l®ˆäè&½4:÷°Ö²R¤w[0rEl*°[]ék  åš±§g^Åñ+nx‡w²³ºò¶y„e{d
 ô)îF#-Ü‹(Ä7…İç’ŸÈqr|kÌÔ»Û½Î‡­Å£Ğ¸Mh€Ó±ƒæFH[Ö‹x¾†Í¬ñî»ú×4ébÚí	L Îµœ±SÛiü÷=,	\l“UŸ/$óİ._‚Êr¶1hvıÖZ7‘»=ŸÇW‘•V!„—ò:âyœ3Àê‡D½=ßœ¡§7‡Òr0²ÔK!/7¼óõsô €”ä§ƒ#~Šš…q§ùÂ+á‚ÜÒç	>®RıîÎGÅ9k·>‚rj76¨‹•ÅV*ÅRÒ£{#É€Çrí§}ˆ‘}ğ^aT¤ôPÿ*†:ó¥‘‰ûeZF) ˜ _«Š“^ç‹ $œ‘)ÀŞ{qÉ÷ç÷AbÙ†²©RFA>¾-uLäa%ª>õGĞAa*/¾v‘Rb`ëF±^
/æ”Ëİòœø2Ë’âR*ËÁJÙÅu$fk¢6_«$'aQ²×[;åâ†øÉj¥)±à“§%<-»»åS>QĞrF¶‰T´ó¦ß•jMi¼aï¾k@dV,DDUêaDAKš¢àöLC'ÍògÃ¬ğ
{WÕló$÷0-÷»ù'ÖYæŞÛ79"Êãİã…ã!wæx@·°¹XÏfr±‘Ëb…¹…D5NDeö\êÛ…xÅL’“P
Âù
§ñ\ÜÎ. ĞÍW’¾p…øóÑiĞ|Ğ ”vØa#Ç^÷Ñ|Øf ».wú«X²$Ìuª¬ZO`æÖMd68	ÉÍq½<%9êìÇ/7°“ô°BügRÉy+‰b¼·4…ĞÆîîÊØZ 9H
ÉÊD5*ÆËÀ¶x½–‰nŞö#Qck.ª_0ë„sÀ}Šš-[ ©°ƒ°úQ¸Š¤°gİ£PÅdË—Øõ5±*×›šc,8yŒ%ÒàÿŠô3>Ià1`3œ x©ÔŒ„0@‚†q|¢ zUMYã€³ZñGí-ğñöµâULM,œç!}»J	©gşJy´ˆ¬Õ¨'Q½™A¶@­åÄ¶È|†d!‹1‡Uúl
+$]xÛçh‘2QãBg‰äQ£¶1[á}¶×ÙgísñºXGñù¬vH…IÌÃsªğ1mÊ†Õdàë@–0¥…£Ó=:Lûûí^?íYì·ğ™âVx_'(€­XÒK^™W-"´jçW'e(‹7›Àr¿ği¦°^èPL=ÕÑ–0Æïİú>ÀÕÛû© Ç˜Ææ7ø³¹âY
a¬’#Kx›1˜%íuÁ\øá>¦FˆïZq˜¢L‰İÆ£ÙÜâXw% vâXäÅzÁ/=†»nŠ;ÑG#:öÕ	÷¿wùÌ¹j IÑBÒ!¦‚JpÎ’U7ËD(€¸Æ2Q‡nÅ4È"·/h¡@bç¨ìQ(ãîfM¢1›‡mxn®ğØcF)g_Æ€f*zÌŒÿjñê–jÌ”$%Ë8?æ÷ß—­¢’!GõúmŒ—¤’_(ÿJ¡¤èÍŒz…ÍY%Ïµt5TtèE] ^ˆ“/ÖµáBëÁ¹Ägù0uÂ*F¥¦Px¯º;Á«	NúÎ0&¢›èÅ+›_F#ğ%*‰”#£âœ°¨Ú€9sîbü*ÂTuÑÀ´4ê:I>§ê¤XÖ±ƒÉ2€ØófÅ N¡¢Û¨6r×_E8z xWÃ.Á8@œGµØ4C¢ u¶¶™Ò…ŸíËÏö?PSb¡`½cÕ¿¨ÚXÇ™—d’áR¡ød¡ğ‡>ÿ=;Zñ¦üüw­ñªÖXzÿÇë×OÏ?ÆNg?ì´tÜß…¹ëÀ©ˆ!–f³2êÅ:;+6¾ì0Ú¼Àò•lŞUQ4QÚô
[Ê3”B#ñp«l”3Q¸ÅÒƒ‘?*ß!¤Â{D0ÒñBÏˆÀ?*HøIğtï<ôS8{ôœs¨J¢g×Ñ´›ğ‚ÌUÆ³VÑÜ¨2)t_Å}œì-M9û´øòşsÖæ_ÎzŞVb{ï;G{í%SÏ>Uí/šÌÔÓ„&À?ggiğ¢z’üò6hJ>=âfHVŒ§¥x+¶"îÚ‰ <Rã-Â*ç·lDŒµŒ¡/£îˆÉA´•°ÜÀ˜Ç¡>.O|ˆMÒüJ]¨R~*™¹W%šƒG ÎgµDÙøuÌŠ/±;°3\á z~kä\Ú–£R–,p­XúøÅÊØ(|!ipô¨sÏ‚âÈFñPñZvŞT_&â"âùFfÒzùŸSŸÏk/?¯-µ¦®o”¯àÌ'6c	â#CáĞüª„cé²:·ƒikkkl¼%Ò.¾jBËœ‚«Ü«}²$ÅãK]EÒ§Ä•ÿßßÿ2wb¦[ßğpxÿÛ«í§÷ÿ=:ÿëµ(µ™n?2ÿëoŞ¤ı¿ÆÖö“ÿ÷çxÿ>ÒÆ™´v]ë
)Á¤{u!S¹lèğ™âwõBw«ÔR«óó	+÷>ygÚÁÕÓ›äşlçÿ[½ òNıÿf{éü7jOçÿOôşGL&'TÀÓáı«œS°ù[$~V;ÿ¯êÛéó¿õ¦öôş×Ç>ÿİN§?Ø?êBØ†)8øç¬Ì±ØÈt)X*ÖJ¥BP2‡†SD1B+¬-Š¢Ón«×f{“ƒ£Ã0ÏttÒë·ï^µÕİ{Cj*ÏJ…DâŠœìa&CÉ`™¶?¯=I½s¦ØqëŠR§İ%C”~åò<r‡â7…ŸVT6¢Îi¹Æ”I›œspOƒG'GK3ÄëvS+…3zŸzé	(™~àr|WÑ"²i‰ˆÀãƒ¿0xñŠÎ§¶KcÕXàJZÎè5Wÿˆ§Rœ Ø…‰íˆY^0rµ³ò.«Î]ÇÀä}Ñ²F 24 şföU©şÒšAŞ¢¢ƒÁĞk\l nÂ¤QQ ¥®×î²£“§ılYÓ˜’ƒ	LUbJ…Ë)Ş œÉÛ!µx#ÕïZ‚c$sÍDwÕŸÍ:H’VeDƒÑ«×€`‘èÀêºwÎ4|{™”`¥Âê²–ÜwJ¬Ô­“'ºó( äuƒ_íˆ«o¤ÿ³¤ärÏYy˜³âR^+µ®¶t7H¤Åä¯ªub2ZáM!îA
	jØNúàa²F€Ä)š“@–/bÁ“\¥j÷ğñ]ôÓBö›ÒKsg¤á»Â]3;'z©MÆ(ù[@İ—Lê0©™èV³œL›úş|§
Ñ„[AA¢¯2v«ÿñƒ+ƒW©ë8~5î¡¢*şäW­@Ô_¯ ß[‡ÉMİ2Fl(¡“Å–—6¹#ÚÑÚ˜³*÷ªË=Çº¨ /Uâ¤û4Eu¥ˆx_û‰×S©¢R+êlYp5Å8  ‰ÁÄjJõG½_§ÃóM0×òçMbô5*?Ò‚@¨M7°7AUl6‡@óM$üM	(›Ş¡§…›x×7#7±k»£?n¥ØÑj$biHÉI‚K,zû1ËŸ·Ê"A®$dÑ!ü¿]X&ôÜM…ä LüRp²h€lÊ$AjnDÿk¿	  `€¥~^ Ù48_¨¡k3ğ²    vZS.Ã x  