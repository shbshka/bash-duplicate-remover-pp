#!/bin/bash

function display_prompt() {
    echo "(1) - delete $1"
    echo "(2) - delete $2"
    echo "(3) - open and compare files"
    echo "(4) - keep both and skip"
}

function prompt_user() {
    display_prompt "$1" "$2"
    read choice < /dev/tty

    case "$choice" in
        1)  
            [[ -e "$1" ]] && mv "$1" "$TRASH_DIR/" && log "INFO" "Moved $1 to Trash" || log "ERROR" "Cannot delete $1"
            ;;
            
        2)  
            [[ -e "$2" ]] && mv "$2" "$TRASH_DIR/" && log "INFO" "Moved $2 to Trash" && seen_hashes["$(md5sum "$1" | awk '{print $1}')"]="$1" || log "ERROR" "Cannot delete $2"
            ;;
        3) 
            log "INFO" "Opening $1 and $2 for comparison"
            xdg-open "$1" & xdg-open "$2" >> duplicate_remover.log 2>&1
            [[ $? -ne 0 ]] && log "ERROR" "xdg-open failed for $1 or $2" || log "INFO" "Opened $1 and $2 successfully"

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
