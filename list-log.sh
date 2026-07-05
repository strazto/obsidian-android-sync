#!/data/data/com.termux/files/usr/bin/bash
# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

while true; do
    clear

    if [[ -f "$LOG_FILE" ]]; then
        \cat "$LOG_FILE"
    else
        echo "No log yet..."
    fi

    echo -e '\n\033[44;97mPress R to reload or Enter to exit...\033[0m'
    read -r -n 1 -s input

    if [[ -z $input ]]; then
        break
    elif [[ $input == "r" || $input == "R" ]]; then
        continue
    fi
done
