#!/bin/bash

process_duplicates() {
    local mode="$1"
    while IFS= read -r -d '' file; do
        hash=$(md5sum "$file" | awk '{print $1}')
        if [[ -n "${seen_hashes[$hash]}" ]]; then
            log "INFO" "Duplicate: $file (equals ${seen_hashes[$hash]})"
            case "$mode" in
                prompt)
                    prompt_user "$file" "${seen_hashes[$hash]}"
                    ;;
                auto)
                    rm "$file" && log "INFO" "Deleted $file"
                    ;;
                dry-run)
                    mv "$file" "$TRASH_DIR/" && log "INFO" "Moved $file to Trash"
                    ;;
            esac
        else
            seen_hashes["$hash"]="$file"
        fi
    done < <(find "$TARGET_DIR" -type f -print0)
}