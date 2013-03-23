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
� �MQ�<kW�H���_�ʀ3�	!��!3ap�63�CrYnc-����0������[UݒZ�D�ə;��`������^]R�����y��ճ��F��܄߯�6�j��g�f����jks����hlmm=c��}�O���س	��,>�(�gV��ɠYo�~���Tk����:�����������o��z}0�ƈ{_��[�����z����F��3V��W��<�-��OJ%��?�;%ا˴#Hcۖs���T�Z	��=}�:�߶���u���[pȞ�������_����c��������O�����`���w�ބ�6;3�\�[C���_���0���6;v�k�;���;����԰��N���=�	<k�">η���b�BϿ4,�;sϝ�=�b�����Sk�������x3,�pf�,���+�� �JC��oz�W٦�����g0�6*��-�YeG35@�gcI� �i�R`3a�!�d��1�,Ǵ�gk�z&/C+����w�̷�3�� 4��u6wCZ)�9���qT3�6W�1| �F�N���0
� ������f�'�J�����/�n�s��5��ze������\��#+��-�W����9�pk���y�`0�p`] �g��q�+óQ���̉�\P��A�>%�`kev[*1����M���M]��O�k�z99t�n�� ���،K����W%�_p�m6��]����Ɯ���~{��p�q釜&���>B�9P�M��}e�5f�و�A<G�s���:ݓV��a�}�O�{G{1d/8{�n������F��V.����q{ ;g�^�����<k�Sܛ*�'@;��jpĝ��y�H^��q�DP�I1��H�����̻ av�h!_���ڧ����~.Q�Έ�yD�}��&ݿ�~�
����BB����.�AԎ#E���ɷ�r�B8���i��):>���;��z6D���Y;վ)�OZ���~+��Jt�}h�ْ�:�VC�i���Ύ�����%��mvX��N�}��d;��d��[��*��vmi9�~7Dr�� �h��Aq�� 1�7�mL2�SûT9 ��.]��"ٗ�{ϝr�
j�{�a�2T�̟q�[f�*�*B�~�������Ѵ�]���X oi��9�o�7*��Ce@_?ܱO�p
�t��v���lī�݋ ��.ʤHI9����E0aoY]��`.�wm��XIЙ���I�`���x����Y�!<�7��J,���Gv7
�7�<�z�7�S�/����6��ن��i
��P[��Eh^�t�����\����l��{&8P`�<vu���^��������c����lƽ�O���F��,|S�z�G0յ"���ht8ƖN
ـ�Hl��:��mM���4��L�?3L��*.�5U�cJ���)H�gu�~N�>(rX*�X1K� +q�g�W�6B�=�� @P��Nڽ�"�J�!4HC��ro��K�x�nt���{���j� X�q�$*��8'@%G���[�Gܙ@\ "� �}����V���~~i���8�����eE�5=)��9J4����N������[K�<�h��p�A����&eG��c���cĮ-Ќ�h����X`MQ����tcA.�l�քL��	�䤨B���g� ��Cc�E���&I֑���,�����1TQ������+ܸ��F3Q�#Dے�t�4�� "���E0&��kH'�ub�g�QȂ2��MӍ�;��GJ��>�5c�2��w>_����Ӯ}.�6,1y���߽~����2��g�+ ����4�J���,����:�Ԗ���4n]�*M5��.�I]���|4���l��a��r$>w����(43l��yt*}ykt���� ^b��!�0��<�{U��Ϯ�A��s� @�0S�kf��!�V�������U�1��e�P�D���c�-x!���
��<V2<_f��uTO(" �\-}X��	�B4���i%M��>���������WU݂���w���%Vr��{�G�d�k���q�R�I��9f5�hUx�g�W��v� Z��
�)��������"�\R���x ��="�'�BO��G"m�����_��K8ɳ���zi^��/�H�e�{ ���Y�G[�5)�]MW�_���������)�.�c�����I�1��Ѭ+�;��as/X|���?4(� 5�2���G����� �(�i��N�A���A\����)������2'�8������`[��]���A�ApG�A�2`J�>�{��;??��K|'u�-�^��M0������A߃��ߏ«{��o�z�|�=A룺�2�/�j|#�_��c�j[��]��q+"��'-���,L oC\U���� ��s �!��,I�g�A�M�s��X�0�4�~3C����(�"�A�&cF%�������WSбk��5j/�>������� +��bFiH�l�C�M�H���lL9�S��_���G,��A����X�%A?ނ-��c,ؒ�k���(�$�[�%�>-	�aly?-	�1lIЏ�`KB�[����E�w���W�%�ѥi*\�B�� O[�b�(�D�{ϺB���L�A�E�@[�]�"ML��|P4��{���b0��I�Uak)V�A ���B4y��GT5���(�e�į0[q� ��4g,���s��苫wa�[��j���5�M5�>eM�j�(4z�&;�'���'�JJI:�<�z��1gR
1�#�$I"�c�u۽ ��L�������h&a�2��j���.��=�H8߉3�$���ôs��T�A�[�R&o�H9�y"����3]�]��N��r�x{b�xE�sVJ�Fq��@�<5J�Sk�*�r*%Q�Jds>�H1D�7o�'� �^�0��_P 5�~T�
�LcKä��(uk,��j�-��"Ȳ�2���]�B*Pg1P���J���-`W*����,���beV �z��2�\���/&.�&�|"+���8������N���Y��~g�w)��-\��2/�����N���N�S�R�Q�FhB;�궍�d�E� '@�0��ѹ��~�5,��Ģ���`�P���H_ (�G�E4�ޫ>~��/���w:EWC�n����Lč���&w��%�����$���T�+�뜜�N��B�6�N�6�=!mXY,7�5�������Lh�'08�r�v}���w�XC,���V}Ĉ�_vST��EHB��V�d�����E|YnBt)"/�cHr�Z;��k�+�)z�p<m#R��t�/���DO I�A�:08櫨�Xw�/�2.�mc����&�_�W���q�=(�}m��XEL`�r"-=���\ x-��~��;��: 3�=�eU���b�;[��WR����)��5��9�h�f�����xo�� $��)�*��8R�Ğ��,S�l0�
'PA��u��Kn��F9��S.��w��{�x**��]L�T<\}��榺`{ɥMzS{�y��]���OV/�I�H�I5�[���[e'�0�`d�F�ߑ��Rk�)�w��wM���1���QV��/8�#�4H�F�Z������E�,�KL��an�uy������(O��6��,��x@�L��,כ�WX]JU�4gϥ.�Q�(��H9	e"�����r�� E�ĥ�x!�!	6c��|C������f#�Y�b�|�h`x����0���T���	_�0�0��p/�3v�`������>����Ú�RDKH��i�,����@�N��6�`t���Y-@RHX.�q�`���J.�E�C���������<�"|��)������M�d�vU�@��/_bOԷ�U���cI�Ȉ�-����gr����f8Iu�+2E�)a��#BA������/�E4�'������U,M,��}�J�o�F����1ը'U_�CvB�6Ŷ�k|Ff.�E�!��%�~'�h�rQ�"���Q��1[}�tV�G�~�7P|>j`��R��x�j�,�r�Q}f�6A�@We���=:��"��^?���}#�)��V,I&?ί������EL!���]�:0�6|bk-���� w�*~˘V㦍7}���p�~.�q�1�Y�O�t���A�d�R�if��]0��8��⻦�s�)��y4��+��#�vB��X/�ᕧ�pqa'�hDǿv���=>u��:@RĴ�tH��R �t��"t�T��*��"���C��-H�\�=
e�S�hLgQ��<�z�(E����ĝ��#A�o��HRj��0�f}�}Y�.*Q���Q���H@*���o����x9U��W�]��eŇ_T(ⵃ� �DQ�.��K|^�W7��T���kxxI!��R�)FQtG�x9���x���Śrd�N؀	T���0���餁�h�#u�|&/�M��c���w�����՚���j$��#%����.�8@�G.��4C� u���щ����Qcb�b��e���9���n�i�I�����N|��������7_՛��j>=��->��v����G�=�T�y.h�X1aa=���h�s��i�i��v��Hot�D��P��Y:O���ͲQ��/��,/^�C�+:���`�s��#�T����e��g���9�H��Ϭ��h7�mߛ�g��q�X��[O�*�r�a��w���?���O����u���JQ��9�4yBN� ��w܅���ij����)�17#z0=���؊h��N�o�V��g#b���}w�<H��DE�t�lT�"��-˯̵5����#�a3��1�a���������C'w����F�c��(c�C�N�τ_�ҁ���V��@�:��,(N~3귲��2;��o��N����Bh�|\y�qe�5sI�<`z# �>��x�CB��v��W%d�~�ՅL[YYa��I��Fp�U#Z�\��ڧ�_��xÙ+�X����������55���G��������9��(���|c�7^���M�����)��� r&��O��BJ���6�0�R1�-�vex5j���������>7i9��ӛ�l��k� �������ol>��?��?1�RO���r�-�毑�Y���jlf�������~����t����.�m�"���*K�,��%�^.�J���5�4�"��IZe:��(B�3L��^��uN��<��i��:>���޻#RSeZ.�W���t3J�r��xyM�\�I>츃����n��!J�R`�C�ۤ��6ӕ��sZ�9a���'�������ha�x�rf�hF�C/;%3=�or�*ZD6-U.�|0�W��S��Q���vi�\�3"@����?�� 7va�?f��\F��j3�51�G_�������@Uꇿ�fX���`0�[��0�NT]H�뵻����Y?_��4f��`S��r�z��*���L�#��c�������N��Lg$I+E2����k@�Xt`uÿd���J	ʏ�RiyYK�;#V��I�S�E��o����?2�QVrO��2,Xq!��YW[�7%�b�W�:	����� �57{�0Y'@��I +W��I�ERG��{�P5�i�-�yS��p���^��&s��-���&�t��Lt�DYN�M�`�]�h«� Q�W{���k��sݠ�t���PQ���7�D��n �{��M�3Fl(��Ŗ�6�#��ڜ�̚�}׾�"/U�d�4Eue��P�{���K�TQ���u�(��bP��`b5���^��o���:�k��.5��iA Ժ:�*ց�C��:�.��G���b��S��M��M����5H�ј��R�h-�,$	��$�%���1@�᫸d�/
f���i��%�}i^ú����l��M�v��a>�qƐ#��I�|e���L2�R��;)\�    �_�T�� x  