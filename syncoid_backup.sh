#!/bin/bash

# Define arrays to hold backup configurations for each pool
declare -A backup_configs
declare -A templates

# Define default template values
default_template[destination]="/default/destination"
default_template[frequency]="daily"

# Function to parse syncoid.conf and extract pools and templates
# Function to parse syncoid.conf and extract pools and templates
parse_config() {
    echo "Parsing configuration file..."
    local config_file="/etc/syncoid/syncoid.conf"
    local pool_name=""
    
    while IFS= read -r line; do
        line="$(echo $line | xargs)"
        [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
        echo "$line"
        if [[ "$line" == "["* ]]; then
            # New pool detected
            pool_name="${line#\[}"
            pool_name="${pool_name%\]}"
            echo "Detected new pool: $pool_name"
        elif [[ "$line" == "template:"* ]]; then
            # Capture template settings
            template_name="${line#template: }"
            templates["$template_name"]="$line"
            echo "Detected new template: $template_name"
        elif [[ -n "$pool_name" ]]; then
            # Capture settings under the current pool
            key="${line%%=*}"
            value="${line#*=}"
            echo "key: $key, value: $value"
            backup_configs["$pool_name,$key"]="$value"
        fi
    done < "$config_file"

    # Substitute template values in pool settings
    for pool_name in "${!backup_configs[@]}"; do
        echo "Processing pool: $pool_name"
        if [[ -n "${backup_configs[$pool_name,use_template]}" ]]; then
            template_name="${backup_configs[$pool_name,use_template]}"
            echo "Using template: $template_name"
            if [[ -n "${templates[$template_name]}" ]]; then
                # Expand the template values into the pool settings
                for template_key in "${!templates[$template_name]}"; do
                    backup_configs["$pool_name,${template_key#template_}"]="${templates[$template_name][$template_key]}"
                done
                unset backup_configs["$pool_name,use_template"]  # Clean up
            fi
        fi
    done
}

# Call the function to parse config
parse_config

# Generate commands for each pool
for pool_name in "${!backup_configs[@]}"; do
    command="syncoid"
    for key in "${!backup_configs[@]}"; do
        if [[ "$key" == "$pool_name,"* ]]; then
            option="${key#"$pool_name,"}"
            command+=" $option"
        fi
    done
    echo "Command to run for pool '$pool_name': $command"
done
