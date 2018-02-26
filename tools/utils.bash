function echoerr
{
    echo $@ 1>&2
}

function has-program
{
    local program="$1"
    if which "$program" >/dev/null; then
        return 0
    else
        return 1
    fi
}

function get-regex-group
{
    local pattern="$1"
    sed -nE "s|^.*?$pattern.*?$|\\1|p"
}

function require-program
{
    local program="$1"
    if has-program "$program"; then
        echo "Found $program"
    else
        echoerr "$program is missing"
        exit 1
    fi
}

function require-file
{
    local file="$1"
    if [ -e "$file" ]; then
        echo "Found $file"
    else
        echoerr "$file is missing"
        exit 1
    fi
}
