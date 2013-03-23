#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="2056767775"
MD5="64d3f381db5a89a52e6f249e30c3690d"
TMPROOT=${TMPDIR:=/tmp}

label="arch linux installer"
script="./install.sh"
scriptargs=""
targetdir="build"
filesizes="6106"
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
	echo Date of packaging: Sat Mar 23 17:49:28 CET 2013
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
‹ İMQì<kWÛH²ùì_ÑÊ€3ø	!÷’!3apÖ63›CrYnc-²äÕğ0ìÿ¹ãş²[Uİ’Z²D³É™;Ÿ™`÷£ººªº^]Rµöì«êğyıêÕ³úÆF½ÙÜ„ß¯·6›j—Ÿgf£¹±ñjks£ş¬Şhlmm=c¯}ƒOè†ÇØ³	÷®,>¸(ÇgVÀÍÉ Yo¼~ö×ùTkşÜø´:ªı‰ø¿±¹±ùÄÿoÌÿz}0áÆˆ{_ƒÿ[››Åüßz•áÿ«Fıõ3VâÿWÿ¬<¯-§æOJ%ÓØ?´;%Ø§Ë´#HcÛ–sÁ¤ŒT«Z	ûŸ=}ş:çß¶†ş×u®ÿ›[pÈôÿ·ãÿĞÛ_•ÿÅúc«¹¹•µÿ¯êOúÿêÿ¡`…­ w±Ş„Û6;3°\‡[CÏğæ_šı­0˜¸Ş6;vÃk;úì;ùñÓÅÔ°ìªéNßÂè=×	<kâ">Î·ÙßÇbïBÏ¿4,‡;sÏÍ=ëb°ÿıœ©Sk—ÛÜğùˆ…x3,˜pf†,Ãß³+îù ´JC÷¹ozÖWÙ¦†şÄòüg0Ÿ6*º™-¶YeG35@ÁgcI– ÛiÂR`3aí!Òdæ¹1•,Ç´Ãgk¾z&/C+¬ƒ¦õwçÌ·¦3şà 4¾ê¨u6wCZ)ô9ƒ•˜qT3†6WĞ1| ÆF®N¶€0
© èü“›ÏfÆ'”J»½ƒãÁ/ínï¨sº£5«õzeÈ£²¡•…\æ¸ã#+˜Œ-›WÙßàÜ9³pk‹¨y’`0Ñp`] ¶gÁ–qõ+Ã³Q †ËÌ‰á\P»åA>%Ë`kev[*1ø¬ˆMÃğ‚M]€äOÜk¾z99tnÌÂ ¡ÂâØŒKÛî¡êW%Œ_p‘m6‡õ]öÄÖæ¬Æœ²²Ğ~{÷ìpÇqé‡œ&ÿôæ>Bôƒ9P¿M¹ï}eº5fÏÙˆA<Gì¸s¸ßê·:İ“VŸºa¯}ÁOª{G{1d/8{ñnûÅÉö‹FÃÆV.ÔÁÁÑq{ ;gš^×ØÎÓğ<kìSÜ›*×'@;°—jpÄÜöyşH^…áq¯DPşI1¬íHÖØÈòéÌ» aváh!_–çÊÚ§­İãö~.Q£Îˆ‹yDì}èİ&İ¿¤~ë°
ôíèõBBüš.¨AÔ#E¹ªéÉ·ÇrÌB8»íöiª£):>´;¿¦z6DÏîñY;Õ¾)ÚOZ‡íÓ~+ÕõJtí}h¥Ù’ :ÇVC×iòô´ÎûÑø¯®%û…mvXÃÔN²}©Íd;•ıd»Ò[Êö*»Êvmi9‡~7DrÃÆ šhüÖAq‚ñ 1æ7¦mL2SÃ»T9 Ù÷.]ğ›è"Ù—â{Ïr¶
j“{a¯2TÃÌŸqÓ[f¢*«*B½~«ÛüÚêï½ÛÑ´Ò]©©üX oiàù9ÓoŸ7*ÿ¸Ce@_?Ü±OŸp
êt¡v¢ÒlÄ«¡İ‹ ­Á.Ê¤HI9¯‚âÎE0aoY]Ğ`.½wmÒXIĞ™ş€æI„`™°Şx³¨¸ÎYÅ!<Ë7‹ÚJ,ÇêªGv7
ö7²<°z®7¶Sü/ãÏˆÉ6ÕèÙ†¶ˆi
ËåP[óøEh^™tâÒøáà\ÔÆÿÔl÷š{&8P`í<vuáÀ¥^¹¨Èà‚¿³Àc«çÛálÆ½íO«øFÂ÷,|SŸzáG0Õµ"ø¼¦ht8Æ–N
Ù€¹Hl±Ü:ˆ¢mM­€œ4‡ŸL?3L°æ*.5UÑcJí‡Óéœ)H£gu…~Nˆ>(rX*ÎX1KÜ +q‘gÿW²6Bç=› @P¤NÚ½è³"„JÙ!4HCğroÂÍKñx£ntµ¹†{ÖÀìjˆ X¡qÎ$*º‡8'@%G³ÁÛ[¡GÜ™@\ "ƒ ê¢}ÀÉêî—V—ğ~~i¡Ò×8¨±ºeEŠ5=)¼™9J4ûı÷üNØê¶œ’ù”[K¾<’hı‰píA¸Í¢&ÂeGø¹Âcàñ‡cÄ®-ĞŒ hŒ€³ïX`MQĞ÷…ÛtcA.ülÊÖ„L°ï	¿ä¤¨Bµ¡g§ ‘ïCc‹E…­à&IÖ‘‹èÙ,˜ÏÜçÚ1TQ½öà¼ø±Ó+Ü¸ÈÅF3QÃ#DÛ’„tñ4Ş… "¢’³E0&¡…kH'€ubág¤QÈ‚2‘éMÓå;‰‹GJÚ×>¶5cŠ2ôÑw>_¿×ô”Ó®}.©6,1yÊ÷ûß½~÷èÜ2–g¦+ ´ûıò4„J…ñé,˜«ñÉ:úÔ–ƒ˜4n]‰*M5¤ê.ŠI]¼©|4öö­lÀÀaÙÅr$>w½•ô¯(43l£yt*}yktıÀ˜Î ^b‰Æ!Æ0µ…<²{U±–Ï®ÄAó”s  @³0S€kf£é!¬V‘˜«Š‰ ‘U“1ÁÃeŒPëD£Û¦c¬-x!÷€ú
¸<V2<_fú±uTO(" õ\-}X§¨	á¨B4ÈÎÅi%MÂÁ>Œ €ãˆ«¥ÒÔWUİ‚âÚëwºâÔ%Vrš¨{ñG³dĞk¯ÒÂqÔR¼IÑà9f5€hUxŸgÅWÛïœvú Z±è
)–ÔÈÀ‘†óñ"÷\R‚›Êx …="Ë'ÇBOŸÉG"m²Èğä û_ÑK8É³¤ÀÏzi^Êß/šH­e·{ –ŒÃYšG[Š5)æ]MW”_Š©ŸäáâÍò)÷.¸cÎï“şåöI»1ëŞÑ¬+ç;±„as/X|ë¸İí?4(œ 5Ô2Ğ÷ºGı£½Öñƒ —(½iºİN÷A ¯ÏA\ø¯­î)š¬‡€¯É2'½8œÁ£½öƒ`[ÎØ]òÑéAçApG”Aı2`J>²{¹;??”ÄK|'uĞ-ğ^öÚM0åş„îííAßƒ ÏßÂ«{¿oõzÀ|Ñ=Aë£ºì2Ÿ/í¿¯j|# _Óıcúj[¸] Ûq+"â˜÷'-àÕê‹,L oC\UŒøØí ‘Üs !ØÂ,IçgŒA‘M¨sÑÑX´0…4Š~3C­™ÌŠ(—"Aï&cF%•’©êø…ÕWSĞ±kÛî5j/å>ÇãÂôåÁ +»ÕbFiH“l§CÔM†H‚çlL9S™_‰ùG,˜ŠAØáÇX°%A?Ş‚-¹Àc,Ø’ kÁ–ÿ(¶$ì[°%á>Â‚-	ùaly?Â‚-	ü1lIĞ´`KB”[¶‰ùÎEå¿w²â—W¦%ëÑ¥i*\’B¢é O[Õb(’DÚ{ÏºB“é×L™A’EÆ@[¤]ß"ML‘Š|P4® {ÍÂÙb0¦ØIåUak)VšA ¨¶›B4yµÄGT5¹˜(e¦Ä¯0[q² šÌ4g,± ¢sÚÒè‹«waö[İÃj¦§³5°M5²>eMŒjÂ(4z´&;®'–™Š'ñJJI:”<ãz‘Í1gR
1#Ê$I"ûcó€uÛ½ ØùL·ƒ€™ÿ¹Òh&a¤2ä¿êj™.û³=¡H8ß‰3¸$‰ıŠÃ´s±‘TâAÇ[×R&oÏH9©y"“ğ©ÀÓ3]‚]™ãN±‹r¼x{b™xEåsVJÿFqÔ@×<5J‰Skì*°r*%QàJds>İH1DŸ7oè'¹ £^ö0‘_P 5î~Tò
½LcKÃ¤ßÒ(uk,®¸jÏ-¼€"È²·2ŞÓç’]€B*Pg1P¼ÃÏJæ¿ªè-`W*—˜€¥,µşbeV šz‹¦2‡\Œ…ı/&.Ö&Â|"+»ˆ¬8âÂê‚úNú­ÃY·Í~gÂw)â¤ì-\¦2/ó÷N³³òN÷SÀRŒQâFhB;Çê¶³dƒE¼ '@ß0íÅÑ¹‡µ~”5,½ÃÄ¢‘«ò`‹P‚İëªH_ (×GˆE4ıŞ«>~ÃÍ/ûğîw:EWCŞn°°LÄÅë±&w’%ü‚ù•$×ÆæT½+Şëœœ´N‡Bë6¡NÉ6š=!mXY,7ú5³æÛïŸ³¤Lh¹'08·rÆv}»ùßwôXC,€‰­V}Äˆì_vST—³EHB³÷Vå‰d‚ØØı×E|YnBt)"/½cHr¾Z;ªækĞ+¬)z„p<m#R£ñtÍ/³À¸DO I¹A¾:08æ«¨Xw¨/ü2.Ìmc–Š’ú&Õ_ï¼Wœ¸öqë=(­}mºXEL`år"-=ºò™\ x-§Ñ~±Ô;€Ø: 3å=ÆeUŸõÏb¨;[™ºWR¦åÿ‚)É5®Ø9é‹h¾f¢ùì±Åxoïó $—­)›*çÄ8R÷Ä¸Ş,S½l0‚
'PAøÉu”Kn×ôF9ºğS.Ûw“Ë{µx**û²]L¿T<\}€ æ¦º`{É¥MzS{Ğy»±]Ñ×ÄOV/ßI¡HI5ğ[ÂÓò»[e'Å0­`d›Fûß‘Ãá»Rk£)wìíwMˆ²õ1‰•ªQV“¥/8Ç#Ë4HïFÜZ³ª¼ÊŞÖEŞ,ÍKLòıanŠuy¹Âö‰€(O¨€6†ñ,¯Öx@…L×ù,×›…WX]JUÅ4gÏ¥.ÎQÆ(ñH9	e"š¯ğÏÊrÌŠ EÑÄ¥‰x!Ï!	6cŠì|CŠĞÃ”ØØf#×YĞb”|h`x„‡Æë0…ª«Tûµš	_Á0®0šÈp/Ò3vÖ`Äíâ”ô¨óŸ>İÁ²ÃšğŸRDKH¥çi¬,Š—ÜÒ@”Nü‡6ö`t—ÆÖY-@RHX.ªq¹`¶úíJ.ºEÛCÄõ™­™¨ËÁ<Ú"|„÷)ªÉ¤Ê¢ªMád’vÂUŸ@õ“/_bOÔ·ƒUÆşÄcI¤Èˆ¬-ÿ×égr¢À·Àf8Iuğ+2E´)a€“#BAõÃš²Êµ/æE4ı'íğñşµ’U,M,œç}»Jé«oıF™¹˜¬1Õ¨'U_šCvB­6Å¶Øk|Ff.ËE‡!Õ­%~'àh­rQã"·ŠäQ£¶1[}átVÙGí£~«7P|>j`êãR©ó±xjŒ,‡rQ}fÊ6AÓ@We…¤Ó=:Ìú"ûí^?ë…ì·ğ¹}#º)”ÀV,I&?Î¯é­¦ãüÚEL!Êûâ]ç:0‰6|bk-ªøºÔ w€*~Ë˜Vã¦7}ı“÷p÷~.Áq¦1ƒYèOÁt¦ø¢A«dÛRşifÁÄ]0¾ç8œ™â»¦¯s”)‰£y4Ù+ÀÄ#ÀvBËÍX/œá•§ÏpÂ•qa'ÆhDÇ¿vÁƒï=>u¯„:@RÄ´tH¨ R ¹tıÏ"tT¦*‚¢" „ÅCäö-Hì\•=
e¿S—hLgQŸ<şzÂ(EÈèÑÊÄ¹‘#AÕoî©ÍHRj°Œ0ñ³¶f}ÿ}YÑ.*QøáQ¯ßÆH@*™ŠÊo„ŠŞÜx9U‚Wœ]ÏÖeÅ‡_T(âµƒĞ â‰DQÅ.´œK|^£W7ª¯Tª…‡kxxI!Á‰Rä)FQtG½x9áğëxŞÏÄÅšrdüNØ€	TÀÜ÷0âšæé¤åhô#u“|&/ÒM‰Ìc“…Šw®ÿ±•ÇÕš«¸şj$ÊÉ#%šÔí.À8@œG.Õã4C¢ u¸¶Ñ‰ëÎßQcbéb½eµ¿ª9øäænÒiŠI•â¡¥§N|íçÿ“âòŸÿ¯7_Õ›ïÙj>=ÿÿ-> ¹vğÃÎúGÇ=ñ½Tšy.hŠX1aa=« Íh°s½ùi›iĞæ‡v äHotÑDÉéPúïY:OÍÔÃÍ²QÎÄ/–Œ,/^¾Cø+:„‡`¤sŠŞ#€Tğ“àşeèïg è9÷H½ÆÏ¬¦Šh7Ñmß›œgêâ¹q½Xäâ‹[OÙ*rşaşéwüç¼Í?÷üO¬ÌöŞuöÚJQŸ¨9Ÿ4yBN˜ ÿœwÜ…ÁóÚijğËû )·17#z0=™–á­ØŠhøÒNå‘oØV¹¼g#b¬ãæ}wÇ<H¢­DEætó—lTå"€ø-Ë¯Ìµ5åùÒ÷#êa3ğ–À1a£–¨˜¿™ş»C'wÀ §ğFîµc»Æ(cİCÏN¤Ï„_¬ÒÂ’VğÇ@:³ñ,(N~3ê·²ó®ö2;ÏÈo´ÒNâË—™Bhü|\yùqe¡5sI¦<`z# ç>¥›x“CB¨‡v¨àW%dÍ~Õ…L[YYa»àI‚FpñU#Zî\å°Ú§û_‚¤xÃ™+ÊXú”Øûÿ»ıŸ‚‹55ì¯øÀG¼ÿïÕÆÓû¿9ÿõ(µ©á|cş7^¿ÎúMøóäÿı)Şÿ‡ r&­O—åBJğ‚¢6…0²R1†-ñ»vex5j©‰µÙå«ôæ>7i9áÍÓ›ÿlçÿk½ ô‹úÿõæÂùol>ÿ?Ñû?1áRO‡÷¯rş-Áæ¯‘øYîü¿jlfÏÿÆÖë§÷ÿ~ëóßítúƒı£.„m˜"€ƒÉ*K·,‚%½^.—Jô¼˜5¤4š"’ˆIZe:´”(BŠ3L»­^›íuN£<ÓÑi¯ß:>şòª­îŞ»#RSeZ.¥Wìàìt3JËr‚xyMú\ÛI>ì¸ƒÕÛ©³n‹’!J¿R`»CÉÛ¤¢Ï6Ó•¨sZ9aÒÀ¦'ÂÜÓàäèôha†xİrf¥hFïC/;%3=orá*ZD6-U.ú|0âW–ÉS¯ÏQÂùÌvi¬\©3"@‹½å?âÙ 7va²?f–\Fí¬²Ëj3Ï51ùG_´¼€€¿¹ı@Uê‡¿´fX´¨è`0ô[€ë0éNT]H©ëµ»ìèôıY?_–“4fä`S•˜réz‚·*çòæLí#ŞÈcõ‡– ÃËÜNª»Lg$I+E2âÁèÕk@°Xt`uÃ¿d¾½ĞJ	Ê°RiyYKï;#VêÖI„SİEòºÆo¶Åõ’?2şQVrO¹ç¬2,Xq!¯•YW[¸7%ÒbòWÕ:	­ğ¶÷ …57{ğ0Y'@âÍI +W‰àI®ERG•¡{øP5úiû-é¥ySÒğpŠ®™^½Ô&s”ş- îË&t˜ÔLtãŠDYN¦M‚`¶]ƒhÂ«¢ QˆW{µáÉkæÄsİ –t‰†ªPQÕàâ7­DÔßn ß{‡ÉMİ3Fl(¥“Å–—6½#ÚÑÚœ±ÌšÇ}×¾ª"/Uâdû4EueˆøP{‚€ÄKÆTQËÓu¶(¸šbP€Ä`b5¥úã^ŠÎo³áù:˜kùó.5ú•iA Ôº:ë *ÖëC ù:ş.‡„GœÍÆb€ÈSˆÃM¼ÿMš‘›Ø5HÜÑ˜÷Rìh-±,$	Šä$Å%öíİ1@„á«¸dî/
fÄîĞiş¯%˜}i^Ãºıºùêl¸—MÂv‚Êa>»qÆ#÷öIò|e•ÁøL2‚R»È;)\ğ—    À_èTú³ x  