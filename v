#!/usr/bin/env bash

[[ "$vim" ]] || {
    [[ "$DISPLAY" ]] && vim="gvim" || vim="vim"
}
[[ $viminfo ]] || viminfo=~/.viminfo

usage="$(basename $0) [-a] [-l] [-[1-9]] [--debug] [--help] [regexes]"

[[ "$1" ]] || list=1

declare -a fnd
until [[ -z "$@" ]]; do
    case "$1" in
        -a)     deleted=1;;
        -l)     list=1;;
        -[1-9]) edit=${1:1}; shift;;
        --help) echo $usage; exit;;
        --debug) vim=echo;;
        --)     shift; fnd+=( "$@" ); break;;
        *)      fnd+=( "$1" );;
    esac
    shift
done
set -- "${fnd[@]}"

[[ -f "$1" ]] &&
    exec $vim "$1"

while IFS=" " read line; do
    [[ "${line:0:1}" = ">" ]] || continue
    fl=${line:2}
    [[ -f "${fl/\~/$HOME/}" || "$deleted" ]] || continue
    match=1
    for x; do
        [[ "$fl" =~ $x ]] || match=
    done
    [[ "$match" ]] || continue
    i=$((i+1))
    files[$i]="$fl"
done < "$viminfo"

if [[ "$edit" ]]; then
    resp=${files[$edit]}
elif [[ "$i" = 1 || -z "$list" ]]; then
    resp=${files[1]}
elif [[ "$i" ]]; then 
    while [[ $i -gt 0 ]]; do
         echo -e "$i\t${files[$i]}"
         i=$((i-1))
    done
    read -p '> ' CHOICE
    resp=${files[$CHOICE]}
fi

[[ "$resp" ]] || exit
exec $vim "${resp/\~/$HOME}"
