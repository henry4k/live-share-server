echoerr()
{
    echo $@ 1>&2
}

has_program()
{
    local program="$1"
    if which "$program" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

get_regex_group()
{
    local pattern="$1"
    sed -nE "s|^.*?$pattern.*?$|\\1|p"
}

matches_regex_pattern()
{
    local pattern="$1"
    grep -qE "$pattern"
}

require_program()
{
    local program="$1"
    if has_program "$program"; then
        echo "Found $program"
    else
        echoerr "$program is missing"
        exit 1
    fi
}

require_file()
{
    local file="$1"
    if [ -e "$file" ]; then
        echo "Found $file"
    else
        echoerr "$file is missing"
        exit 1
    fi
}
