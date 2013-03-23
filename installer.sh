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
� ��MQ�=kW�H���_�΀3�	I�%��0���������r��"K^= ����7�/�U�-�%K`�	g�|f�ݏ���zuI[�>��|޼z����Uk4�����ۍ:��ϳz����z���v�Y�^���z����u��gS�^�|0���ύ�Q��y���T������2�������������S����-��z{;���_����^�z�jO��柵�աiW�i�`�>���ڝ���aڑ��,Ӟ0)#��V��gO�����̡�m��������֓�D����M�����鍴���Q�u� kl-���0���ܲ�A`���������k.���;��	.]n�f౿Y�'3ݴ*�3{���w�a��xl��a�m��\�\7mn�=g�p���g��?8S��.����l�f�?��\X�~<f�� h���s�p�9��C���1�OgmTt3Kl�|f j���ƒ,���m6���f��C���u&�>�L۰�g��/A+����w�3gs�� 4��M�pZ)�8���~TӇW��= �F�̀��0
� ��������
�������v�w�9ij�J�Vr_/oiA!�َ����&c���w87E�Lܚ� j�$L�mX�횰e\�BwMD��0c��j7]�§`� l�Į�5�/�iL��H�Թ��ˑ�C���<�*,΁͸��LU�"a�����︰'��`Uf����ۻ��Mۡr���[x��@i�6�T����=g#>�����~��>�t?���{��~�M�Ő������v^�4663����� a�ӊ5�5�L��/Qob�\� 5a/�ʏ:�����ã^����`X�&������7�7!av�h!_V���'����~&Q�ΐ�YD�}��
&ٿ�~�0
�5��\B����AԎ-E���ɷ�r��B8���I��!:>���;�$z�D���i;Ѿ-�?��'�V������J.�Z���Xk���s�:=��'nM����*�������Iw*�Iw%���Uv��z�e�� u��h����	�Ę_�>���t�\� d�;t�ϯ栋d_��=g��:�M�ں��P3o�sl�������n�K�����i��(�4&9;c�����?oP��O7������~�������:h�B�� �K�BI-�����ğ�w��@�3�ݽ4A]����7��*�@�X����X�&���J,�j9�Fv�sv62]�t�� V#�|̣�1R� "9�ZזqL�R.���Hމ�Aj� e9��5�Q��P㒾C��r"�K��|�����9ww���w�Ӑi�dj�rM]%�ܱ�#
��316]p@�8��AҊ�6A�,sf��18�dV��n��F,\s�D��e?��-�I�h�A-�@�V�%vj�� G\�� �h�.�'11\H��v�Z�I[V) ;��n�1����8���*j@S[h�;�����-���q�V|TU4|ֱ9	\����"��#�}��v�7��V��~n�-)np8�b��E�()2����'Y����~��=��Z2�	�N8'�\KY�D�O����0n�_詂��")ުpC@��|�!P�K�����;�3�=zҞp������O����	��"�]��*azJ��} R�ChLc���5�$I5r�s�����\["��'\Vᄅ2��*ڎ$���Mw'@�xH���{�2�I>#�DB�rH��e!՛��v񖏒��}lkD�d�a7�?�׊	�[�ZP�Qd��n��{���	8Eʊ�<+��@�ݫNB(�����]l�Gl�覀�����\�T���"���[�Z(�Gc���t�W],C�3�[K�
+�r�>Z��ѓ�J������M!���CaL�@Y�#�eQ��j��]8G�A�����m��B�Bج#�j�dL��>B�[&0#bAs�+�#t��+1p=��GvN=����c�䡜���#	1 ���4�?Z��/V�
3OUeK�i�s����A����Β�A��
K�NK� ��0�1��UT!}�Sm�s��ӵ|��'��,����4�E�I�6�$4��@{凖M���2��Dr):L�a�A��,�s"��e�HQ�������_4�4ZKo� ,����iL��9.�(�"�fɢM�w'�6�I}�j�C���'Ѭ)���nq�_|����4(5�*���G����� (�
i��N�^�/u�F�[�/��	����o�4b�;8������`���Y���A�^pG�߼0%(��9_�Ν��K���>���
�x'����loB�N����^���aӭ�?�z�{`�hmTW\f٥��T���c~L_-�9��w"��xp�|�R���F��.����������'�ft~ك��e��K����Ws�⡉lR���pz3)�)�OU�/�f;�P��r.��(.LY�a��K-b���Hw�D�x�$x���8�h�D��=�J]9G�p�C,Պ�n�V\�!�jE��T+���Z��-Պp`�V�|?K�:�`�V�K�"�Z��?�R� ��|岲�������%k��e"�B����EQĉ���y�&.u�/g�"t<�r�d�d�����9�,���c��TtP��b�9�j�)�:|D�
h��4Y^J�
��мd���ba�:x�{�F]\x����P/9�m����)ibTF�Q��0iq95�D|��AJ����l�8��"�(:�����l��}�m�0����� #�k�ވ�Ae���1>���O�"1|#VL�'��6���	�"�qR��hF�yH��/)��plVe:����=�i��P��Y+��A�%�S]�H�(eM��+�J��B�����tÃ~޾����{��@�v?j�}?�d�s�Lc+ä�����5�W\hg�V>��ͅ���d@�K���7�@ɼ�B�9�J�c���6�W��r@So>�TL�������%����A��\de�=�G\X�\�a���@��58��oL�&y������R�e6�����IzV����nX���Mh�HͶ��l����&�4:����R�w[0rE�l*�[]�k  ���g^��+nx�w����y�e{d
 �)�F#-܋(�7��璟�qr|�k�Ի۽·���иMh�ӱ��FH[��x��ͬ����4�b��	L ε��S�i��=,	\l�U�/$��._��r�1hv��Z7��=���W��V!���:�y�3��D��=ߜ��7��r0��K!/7���s� ����#~���q���+����	>�R���G�9k�>�rj76����V*�Rң{#����r��}��}�^aT��P�*�:󥑉�eZF) � _����^狠$��)��{qɏ���Abن��RFA>�-uL�a%�>�G�Aa*/�v�Rb`�F�^
/�����2˒�R*��J��u$fk�6_�$'aQ���[;����j�)����%<-���S>Q�rF��T��ߕjMi�a�k@dV,DDU�aDAK�����LC'��gì�
{W�l�$�0-���'�Y���79"�����!w�x@���X�fr���b���D5NDe�\���x�L��P
��
��\��.���W��p����i�|� �v�a#�^��|�f��.w��X�$�u��ZO�`��Md68	��q�<%9���/7����B�g�R�y+�b��4�������Z �9H
��D5*����x���n���#Q�ck.�_0�s�}��-[ �����Q�����gݣP�d˗��5�*כ�c,8y��%�����3>I�1`3��x����0@��q|��zUMY��Z�G�-�����ULM,��!}�J	�g�Jy���ը'Q��A�@��Ķ�|�d!�1�U�l
+$]x��h�2Q�Bg��Q��1[�}���g�s�XG�����vH�I��s��1m��Տd��@�0����=:L���^?�Y���Vx_'(��X�K^�W-"�j�W'e(�7���r��i���^�PL=�і0����>����� ǘ��7����Y
a��#Kx�1�%�u�\���>�F��Zq��L��ƣ���Xw% v�X��z�/=��n�;�G#:��	��w�̹j I�B�!��JpΒU7�D(���2Q�n�4�"�/h�@b��Q(��fM�1��mxn���cF)g_ƀf*ž�j��j̔$%�8?��ߗ���!G��m����_(�J���͌z��Y%ϵt5Tt�E] ^��/����B����g�0u�*F��Px��;��	N��0&����+�_F#�%*��#�������9s�b�*�Tu���4�:I>��Xֱ��2���f� N��ۨ6r�_E8z xW�.�8@�G��4C� u���҅�����?PSb�`��c����XǏ��d��R���d���>�=;Z���w���Xz����O�?�Ng?�t��������!�f�2��:;+6��0ڼ��l�UQ4Q��
[�3�B#�p�l�3Q��҃�?*�!��{D0��Bψ�?*H�I�t�<�S8{��s�J�g�Ѵ���UƳV�ܨ2)t_�}��-M9�����s��_�z�Vb{�;G{�%S�>U�/���ӄ&�?ggi�z���6hJ>=�fHV���x+�"�ډ�<R�-�*�lD�����/���A�������ǡ>.O|�M��J]�R~*��W%��G �g�D��ů/�;�3\� z~k�\ږ��R�,p�X�����(|!ip��sς��F�P�Zv�T_&�"��Ff�z��S���k/?�-���o����'6c�	�#C�����c��:��ikkkl�%�.�jB˜����}�$��K]�Eҧĕ����2wb�[��px�۫���=:��(��n?2��oޤ���������x�>�ƙ�v]�
)��{u!S�l���w�Bw��R���	+�>yg���ӛ��l��[� �N��f{��7jO��O��GL&'T������S��[$~V;�������������>��N�?�?�B؆)8��̱��t)X*�J�B��P2���SD1�B+�-����n��f{�����0�tt�뷎��^���{Cj*�J�D����a&C�`��?�=I�s��q�R��%C�~��<r��7��VT6��i�ƔI��spO�G'GK3��vS+�3z�z�	(�~�r|W�"�i�����0�x�Χ�Kc�X�J�Z��5W���R� ؅��Y^0r���.��]���}ѲF 24 �f�U��ҚAޢ����k\l n¤QQ �������lY�Ә��	LUbJ��)� ���!��x#���Z�c$s�Dw՟�:H�VeD�ѫ׀`����w�4|{���`��겖�wJ�ԭ�'��( �u�_툫o�����r�Yy���R^+���t7H��䯪ub2Z�M!�A
	j�N��a�F��)��@�/b��\��j���]��B���Ksg���]3;'z�M�(�[@ݗL�0���V��L���|�
ф[AA��2v���+�W���8~5���*��W�@�_� �[��M�2Fl(��Ŗ�6�#��ژ�*����=Ǻ� /U��4Eu��x_����S��R+�lYp5�8� ���jJ�G��_���M0���Mb�5*?҂@�M7�7AUl6�@�M$�M	�(��ޡ���x�7#7�k��?n���j$biH�I�K,z�1˟��"A�$d�!��]X&��M��L�Rp�h�l�$AjnD��k�	  `��~^ ��48_��k3�    vZS.� x  