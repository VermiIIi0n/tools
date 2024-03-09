error() {
    local reason=$1
    local ret_code=${2:-1}
    echo "Error: $reason" >&2 # Print errors to stderr
    exit $ret_code
}

optional_run() {
    local command=$1
    shift
    local arguments=("$@") # Store arguments in an array

    if [[ $DRY == true ]]; then
        echo "Run command: $command ${arguments[@]}" # Print command and arguments
        return
    fi

    echo "$command ${arguments[@]}" # Print command and arguments

    if [[ $QUIET == true ]]; then
        "$command" "${arguments[@]}" </dev/null &
        1>/dev/null || error "Failed to run the command: $command ${arguments[*]}"
        return $?
    fi

    "$command" "${arguments[@]}" </dev/null || error "Failed to run the command: $command ${arguments[*]}"

    return $?
}

run() {
    optional_run "$@" || error "Failed to run the command: $command ${arguments[*]}"
}

update_flags_from_arg() {
    if [[ "$@" == *"-dry"* ]]; then
        export DRY=true
        return 1
    fi
    if [[ "$@" == *"-quiet"* ]]; then
        export QUIET=true
        return 1
    fi
    return 0
}

remove_flags_from_arg() {
    local opts=("$@")
    local new_opts=()
    for opt in "${opts[@]}"; do
        if [[ "$opt" != *"-dry"* ]] && [[ "$opt" != *"-quiet"* ]]; then
            new_opts+=("$opt")
        fi
    done
    echo "${new_opts[@]}"
}

pkg_check() {
    local packages=("$@")
    local os=$(uname)
    local missing_packages=0

    for package in "${packages[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            case $os in
            Darwin)
                # macOS
                if ! brew list "$package" &>/dev/null; then
                    ((missing_packages++))
                fi
                ;;
            Linux)
                if command -v apt-get &>/dev/null; then
                    # Debian/Ubuntu
                    if ! dpkg -s "$package" 2>/dev/null | grep -q "Status: install ok"; then
                        ((missing_packages++))
                    fi
                elif command -v yum &>/dev/null; then
                    # CentOS/RHEL
                    if ! yum list installed "$package" &>/dev/null; then
                        ((missing_packages++))
                    fi
                elif command -v dnf &>/dev/null; then
                    # Fedora
                    if ! dnf list installed "$package" &>/dev/null; then
                        ((missing_packages++))
                    fi
                else
                    ((missing_packages++))
                fi
                ;;
            *)
                ((missing_packages++))
                ;;
            esac
        fi
    done

    echo "$missing_packages"
}

pkg_install() {
    if [[ $(pkg_check "$@") -eq 0 ]]; then
        return
    fi
    local os=$(uname)
    case $os in
    Darwin)
        # macOS
        run brew upgrade -q
        run brew install "$@"
        ;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            run sudo apt-get update -qq
            run sudo apt-get install -y "$@"
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            run sudo yum install -y "$@"
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            run sudo dnf install -y "$@"
        else
            error "Unsupported Linux distribution. Please install the package(s) $@ manually."
        fi
        ;;
    *)
        error "Unsupported operating system: $os. Please install the package(s) $@ manually."
        ;;
    esac
}

pkg_remove() {
    local os=$(uname)
    case $os in
    Darwin)
        # macOS
        run brew uninstall "$@"
        ;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            run sudo apt-get remove -y "$@"
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            run sudo yum remove -y "$@"
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            run sudo dnf remove -y "$@"
        else
            error "Unsupported Linux distribution. Please remove the package(s) $@ manually."
        fi
        ;;
    *)
        error "Unsupported operating system: $os. Please remove the package(s) $@ manually."
        ;;
    esac
}

git_clone_or_pull() {
    local url=$1
    local path=$2

    if [[ -d $path ]]; then
        # Directory exists, perform git pull
        run git -C "$path" pull
    else
        # Directory does not exist, perform git clone
        run git clone --recursive "$url" "$path"
    fi
}

write_env() {
    local file=$1
    local key=$2
    local value=$(printf "%q" "$3")

    run eval "echo \"$key=\\\"$value\\\"\" > \"$file\""
}

append_env() {
    local file=$1
    local key=$2
    local value=$(printf "%q" "$3")

    run eval "echo \"$key=\\\"$value\\\"\" >> \"$file\""
}

user_owns() {
    local file=$1
    local owner=$(stat -c %U "$file")
    echo "$owner"
}

group_own() {
    local file=$1
    local group=$(stat -c %G "$file")
    echo "$group"
}

who_owns() {
    local file=$1
    local owner=$(stat -c "%U:%G" "$file")
    echo "$owner"
}
