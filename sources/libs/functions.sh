
# ===== UTILS =====

prompt() {
    read -p "$1 [$2]: " result
    if [ "x$result" = "x" ]; then
        echo "$2"
    fi
    echo "$result"
}

prompt_dir() {
    dir=$(prompt "$1" "$2")
    eval dir=$dir
    echo "$dir"
}

checkcmd() {
    if [ $? -gt 0 ]; then
        exit 1
    fi
}

ask() {
    QUESTION="$1"
    DEFAULT="$2"

    if [[ "x$DEFAULT" == "x" ]]; then
        DEFAULT="yes"
    fi

    case $DEFAULT in
        [Yy]|[Yy][Ee][Ss] ) CHOICE_MSG="[Y/n]";;
        [Nn]|[Nn][Oo] ) CHOICE_MSG="[y/N]";;
        * ) CHOICE_MSG="[Y/n]";;
    esac

    read -p "$QUESTION $CHOICE_MSG: " result
    case $result in
        [Yy]|[Yy][Ee][Ss] ) echo "yes";;
        [Nn]|[Nn][Oo] ) echo "no";;
        * ) echo "$DEFAULT";;
    esac
}

package() {
    tar -czf $*
}

unpackage() {
    tar -xzf $1
}

download() {
    local url="$1"
    curl -O "$url"
}

template() {
    tpl_dir="$1"

    for i in ${tpl_dir}/*; do
        case "$i" in
            *~) ;;
            \#*\#) ;;
            *)
                if [[ -x "$i" ]]; then
                    filename=$(basename "$i")
                    echo
                    echo "### BEGIN $filename ###"
                    "$i"
                    echo "### END $filename ###"
                fi
                ;;
        esac
    done
}
