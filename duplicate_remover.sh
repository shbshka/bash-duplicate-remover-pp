#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/prompts.sh"
source "$SCRIPT_DIR/lib/core.sh"

log "INFO" "Process started."
RUN_PARAMETERS="dry-run | prompt | auto"

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

# Abort if invvalid run option or directory does not exist or is inaccessible
if [[ ! "$RUN_OPTION" =~ ^(dry-run|prompt|auto)$ ]]; then
    log "ERROR" "Invalid run option: '$RUN_OPTION'"
    echo "Available run options: $RUN_PARAMETERS (default: dry-run)"
    exit 1
elif [ ! -d "$TARGET_DIR" ]; then
    log "ERROR" "Directory does not exist: $TARGET_DIR"
    echo "Provide full path of target directory: ~/..."
    exit 1
elif [ ! -r "$TARGET_DIR" ]; then
    log "ERROR" "Error: Directory '$TARGET_DIR' is not readable. Check permissions."
    exit 1
fi

#Initialize hash map
declare -A seen_hashes

#Process based on run option
if [ "$RUN_OPTION" = "prompt" ]; then
    process_duplicates "prompt"
    if [ "$(ls -A "$TRASH_DIR/")" ]; then
        xdg-open "$TRASH_DIR/" >> duplicate_remover.log 2>&1 & echo "Review the deletions."
        read -p "Press Enter after reviewing the files..." < /dev/tty
        read -p "Empty Trash? (y/n) " choice < /dev/tty
        case "$choice" in
            y)
                rm -r "$TRASH_DIR/"
                log "INFO" "Trash folder emptied"
                ;;
            n)
                log "INFO" "Aborted emptying Trash. You can empty it manually later."
                ;;
            *)
                log "WARNING" "Invalid choice: $choice"
                ;;
        esac
    fi
elif [ "$RUN_OPTION" = "auto" ]; then
    process_duplicates "auto"
    log "INFO" "Deleted all duplicate files"
else
    echo "To use other run options, type $RUN_PARAMETERS"
    process_duplicates "dry-run"
    log "INFO" "Moved all found files to $TRASH_DIR"
fi

log "INFO" "Duplicate processing complete."