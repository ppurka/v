#!/usr/bin/env bash

        ###     This program is used to open files using vim      ###
        #    This is a modified version of rupa/v on github,        #
        #    modified to make it more to my liking.                 #
        #                                                           #
        #    Original program is from: https://github.com/rupa/v    #
        #    License: Unknown. No license provided by author        #
        #                                       -ppurka             #
        #-----------------------------------------------------------#

. `which my_bash_functions 2> /dev/null` || {
    echo -e " \x1b[1;31mError!\x1b[0m The script \x1b[1;32mmy_bash_functions\
\x1b[0m was not found in your \$PATH
        Please ensure that the script is available and executable"
    exit 1
}


self="${0##*/}"
case "$self" in
    vv) vim="vim" ;;
    vg) vim="gvim" ;;
    *)  [[ "$vim" ]] || {
            [[ "$DISPLAY" ]] && vim="gvim" || vim="vim"
        } ;;
esac
[[ $viminfo ]] || viminfo=~/.viminfo

# Help me!!
help() {
    echo
    echo -e " $yellow ${self}:$normal"
    info "This program uses viminfo's list of recently edited files to open
    one quickly no matter where you are in the filesystem."
    info "Usage:     ${self} [<options>] [regexes]"
    info "Options:
    -[1-9]          Open the most recent nth file, 1 ≤ n ≤ 9
    -a, --all       List all files. By default it lists only the most recent
                    few files such that the list fits within the terminal
                    window.
    -d, --deleted   Open deleted files
    -D, --debug     Debug the file that would be run
    -h, --help      Show this help and exit
    -l, --list      List previously opened files
    --no-color      Do not use color in output
    --              Pass on the rest of the options to $green$vim$normal
    "
    info "You can use regexes like so:
    Example:
    v '.*previous.py' # there is a file ending with previous.py
    v '.*previous.*'  # same, except we do not provide extension
    "
}

[[ "$1" ]] || list=1

declare -i all=0        # whether to display all files even if they do not
                        # fit the terminal dimensions
declare -i deleted=0    # display deleted files
declare -i list=0       # whether to list the files
declare -i edit         # the number corresponding to the file
declare -a fnd
until [[ -z "$@" ]]; do
    case "$1" in
        -a|--all)       all=1 ;;
        -d|--deleted)   deleted=1 ;;
        -l|--list)      list=1 ;;
        -[1-9])         edit=${1:1}; shift ;;
        -h|--help)      help; exit 0 ;;
        --debug)        vim=echo ;;
        --)             shift; fnd+=( "$@" ); break ;;
        *)              fnd+=( "$1" ) ;;
    esac
    shift
done
set -- "${fnd[@]}"

# If the file already exists then we open it directly
[[ -f "$1" ]] &&
    exec $vim "$@"

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
    rows=$(( $(tput lines) - 1 ))
    [[ $all -eq 0 && $i -gt $rows ]] && i=$rows
    while [[ $i -gt 0 ]]; do
         echo -e "$i\t${files[$i]}"
         i=$((i-1))
    done
    read -p 'Input number of file: ' CHOICE
    resp=${files[$CHOICE]}
fi

[[ "$resp" ]] || exit
exec $vim "${resp/\~/$HOME}"
