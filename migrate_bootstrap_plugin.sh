#!/bin/bash

# Bootstrap 4 to Bootstrap 5 Migration Script for a Single Moodle Plugin
# This script finds and replaces Bootstrap 4 classes with their Bootstrap 5 equivalents
# in a specific plugin directory.

# Display usage information
echo "========================================================"
echo "Bootstrap 4 to Bootstrap 5 Migration Script for a Single Plugin"
echo "========================================================"
echo "This script will update Bootstrap 4 classes to Bootstrap 5 in"
echo "a single plugin directory."
echo ""

# Ask for plugin path
read -p "Enter the path to the plugin directory: " plugin_dir

if [ ! -d "$plugin_dir" ]; then
    echo "Error: Directory $plugin_dir does not exist."
    exit 1
fi

# Ask for confirmation
read -p "Are you sure you want to proceed with migrating the plugin at $plugin_dir? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Migration cancelled."
    exit 0
fi

# Ask if the user wants to create backups
read -p "Do you want to create backups of modified files? (y/n): " backup
if [[ "$backup" == "y" || "$backup" == "Y" ]]; then
    backup_dir="${plugin_dir}_bootstrap_migration_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo "Backups will be saved in: $backup_dir"
fi

echo "Starting migration in plugin: $plugin_dir"

# Function to backup a file before modifying it
backup_file() {
    if [[ "$backup" == "y" || "$backup" == "Y" ]]; then
        local file=$1
        local rel_path=$(realpath --relative-to="$plugin_dir" "$file")
        local backup_path="$backup_dir/$rel_path"
        mkdir -p "$(dirname "$backup_path")"
        cp "$file" "$backup_path"
    fi
}

# Function to update a single file with all replacements
update_file() {
    local file=$1
    local changed=false
    
    # Check if file contains any Bootstrap 4 classes that need to be replaced
    if grep -q -E "class=\"[^\"]*ml-|class=\"[^\"]*mr-|class=\"[^\"]*pl-|class=\"[^\"]*pr-|form-row|custom-select|has-danger|data-dismiss=|data-toggle=|data-target=|input-group-prepend|input-group-append|badge-|custom-file|custom-control|sr-only" "$file"; then
        # Backup the file before making changes
        backup_file "$file"
        
        # Margin and padding classes
        sed -i -E 's/([[:space:]])ml-([[:digit:]]+)/\1ms-\2/g' "$file"
        sed -i -E 's/([[:space:]])mr-([[:digit:]]+)/\1me-\2/g' "$file"
        sed -i -E 's/([[:space:]])pl-([[:digit:]]+)/\1ps-\2/g' "$file"
        sed -i -E 's/([[:space:]])pr-([[:digit:]]+)/\1pe-\2/g' "$file"
        
        # Class attribute replacements (more specific targeting)
        sed -i -E 's/class="([^"]*)ml-([[:digit:]]+)([^"]*)">/class="\1ms-\2\3">/g' "$file"
        sed -i -E 's/class="([^"]*)mr-([[:digit:]]+)([^"]*)">/class="\1me-\2\3">/g' "$file"
        sed -i -E 's/class="([^"]*)pl-([[:digit:]]+)([^"]*)">/class="\1ps-\2\3">/g' "$file"
        sed -i -E 's/class="([^"]*)pr-([[:digit:]]+)([^"]*)">/class="\1pe-\2\3">/g' "$file"
        
        # Form elements
        sed -i 's/form-row/row/g' "$file"
        sed -i 's/custom-select/form-select/g' "$file"
        sed -i 's/has-danger//g' "$file"
        
        # Data attributes
        sed -i 's/data-dismiss=/data-bs-dismiss=/g' "$file"
        sed -i 's/data-toggle=/data-bs-toggle=/g' "$file"
        sed -i 's/data-target=/data-bs-target=/g' "$file"
        
        # Input groups
        # sed -i 's/input-group-prepend/input-group-text/g' "$file"
        # sed -i 's/input-group-append/input-group-text/g' "$file"
        
        # Badge contextual classes (requires more careful handling)
        sed -i 's/badge-primary/bg-primary/g' "$file"
        sed -i 's/badge-secondary/bg-secondary/g' "$file"
        sed -i 's/badge-success/bg-success/g' "$file"
        sed -i 's/badge-danger/bg-danger/g' "$file"
        sed -i 's/badge-warning/bg-warning/g' "$file"
        sed -i 's/badge-info/bg-info/g' "$file"
        sed -i 's/badge-light/bg-light/g' "$file"
        sed -i 's/badge-dark/bg-dark/g' "$file"
        
        # Screen reader classes
        sed -i 's/sr-only/visually-hidden/g' "$file"
        
        # Report the file as changed
        changed=true
    fi
    
    if $changed; then
        echo "Updated: $file"
        return 0
    else
        return 1
    fi
}

# Counter variables
total_files=0
updated_files=0

# Process files - focus on templates first since they're most likely to contain Bootstrap classes
echo "Processing template files (*.mustache)..."
while IFS= read -r -d '' file; do
    ((total_files++))
    if update_file "$file"; then
        ((updated_files++))
    fi
done < <(find "$plugin_dir" -type f -name "*.mustache" -print0)

# Process PHP files
echo "Processing PHP files..."
while IFS= read -r -d '' file; do
    ((total_files++))
    if update_file "$file"; then
        ((updated_files++))
    fi
done < <(find "$plugin_dir" -type f -name "*.php" -print0)

# Process JavaScript files
echo "Processing JavaScript files..."
while IFS= read -r -d '' file; do
    ((total_files++))
    if update_file "$file"; then
        ((updated_files++))
    fi
done < <(find "$plugin_dir" -type f -name "*.js" -print0)

# Process HTML files (if any)
echo "Processing HTML files..."
while IFS= read -r -d '' file; do
    ((total_files++))
    if update_file "$file"; then
        ((updated_files++))
    fi
done < <(find "$plugin_dir" -type f -name "*.html" -print0)

# Summary
echo ""
echo "========================================================"
echo "Migration Complete for plugin: $(basename "$plugin_dir")"
echo "========================================================"
echo "Files scanned: $total_files"
echo "Files updated: $updated_files"

if [[ "$backup" == "y" || "$backup" == "Y" ]]; then
    echo "Backups saved to: $backup_dir"
fi

if [[ $updated_files -gt 0 ]]; then
    echo ""
    echo "Modified files:"
    find "$plugin_dir" -type f \( -name "*.php" -o -name "*.mustache" -o -name "*.html" -o -name "*.js" \) -exec grep -l -E "ms-|me-|ps-|pe-|form-select|data-bs-|visually-hidden" {} \; | sort
fi

echo ""
echo "Testing Steps:"
echo "1. Clear Moodle cache"
echo "2. Test all affected pages with different browsers"
echo "3. Pay special attention to forms, modal dialogs, and components that use dropdowns"
echo "=========================================================" 