#!/bin/bash

#Set log pattern and record to logs
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a duplicate_remover.log
}

log "INFO" "Process started."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Abort when no directory
if [ -z "$1" ]; then
    log "ERROR" "Usage: $0 <directory> [run_option]"
    exit 1
fi

#Set directories and variables
TARGET_DIR="$1"
RUN_OPTION="${2:-dry-run}"
TRASH_DIR="$SCRIPT_DIR/trash/"
mkdir -p "$TRASH_DIR"

# Abort if invvalid run option
if [[ ! "$RUN_OPTION" =~ ^(dry-run|prompt|auto)$ ]]; then
    log "ERROR" "Invalid run option: '$RUN_OPTION'"
    echo "Available run options: dry-run | prompt | auto (default: dry-run)"
    exit 1
fi

# Abort if directory does not exist or is inaccessible
if [ ! -d "$TARGET_DIR" ]; then
    log "ERROR" "Directory does not exist: $TARGET_DIR"
    echo "Provide full path of target directory: ~/..."
    exit 1
elif [ ! -r "$TARGET_DIR" ]; then
    log "ERROR" "Error: Directory '$TARGET_DIR' is not readable. Check permissions."
    exit 1
fi

#Set a hash array
declare -A seen_hashes

#Displays available actions
function display_prompt() {
    echo "(1) - delete $1"
    echo "(2) - delete $2"
    echo "(3) - open and compare files"
    echo "(4) - keep both and skip"
}

#Prompt user to choose action
function prompt_user() {

    display_prompt "$1" "$2"
    read choice < /dev/tty

    case "$choice" in
        1)  
            if [[ -e "$1" ]]; then
                mv "$1" "$TRASH_DIR
            /" && log "INFO" "Moved $1 to Trash"
            else
                log "ERROR" "Cannot delete $1: File not found"
            fi
            ;;
            
        2)  
            if [[ -e "$2" ]]; then
                mv "$2" "$TRASH_DIR/" && log "INFO" "Moved $2 to Trash"
                hash=$(md5sum "$1" | awk '{print $1}')
                seen_hashes["$hash"]="$1"
            else
                log "ERROR" "Cannot delete $2: File not found"
            fi
            ;;
        3) 
            log "INFO" "Opening $1 and $2 for comparison"
            {
                xdg-open "$1"
                xdg-open "$2"
            } >> duplicate_remover.log 2>&1
            
            if [ $? -ne 0 ]; then
                log "ERROR" "xdg-open failed for $1 or $2"
            else
                log "INFO" "Opened $1 and $2 successfully"
            fi

            read -p "Press Enter after reviewing the files..." < /dev/tty
            #pkill -f ""

            prompt_user "$1" "$2"
            ;;
        4) 
            log "INFO" "Skipped $1 and $2"
            ;;
        *) 
            log "WARNING" "Invalid choice: $choice"
            prompt_user "$1" "$2"
            ;;
    esac
}

#Iterate and process accordingly
while IFS= read -r -d '' file; do
    hash=$(md5sum "$file" | awk '{print $1}')
    if [[ -n "${seen_hashes[$hash]}" ]]; then
        log "INFO" "Duplicate: $file (equals ${seen_hashes[$hash]})"
        prompt_user "$file" "${seen_hashes[$hash]}"
    else
        seen_hashes["$hash"]="$file"
    fi
done < <(find "$TARGET_DIR" -type f -print0)

#Confirm changes
if [ "$(ls -A "$TRASH_DIR/")" ]; then
    xdg-open "$TRASH_DIR/" >> duplicate_remover.log 2>&1 & echo "Review the deletions."
    read -p "Press Enter after reviewing the files..." < /dev/tty

    read -p "Empty Trash? (y/n)" choice < /dev/tty

    case "$choice" in
        y) 
            rm -r "$TRASH_DIR/"
            log "INFO" "Trash folder emptied"
            ;;
        n) log "INFO" "Aborted emptying Trash. You can empty it manually later." ;;
        *) log "WARNING" "Invalid choice: $choice" ;;
    esac
fi

log "INFO" "Duplicate removal complete."