#!/usr/bin/env bash

loadconfig() {
    while read line
    do
        # First ignore ini headers
        [[ "$line" =~ ^\[.*\]$ ]] && continue  # echo "regex match!"

        # Parse out key/value
        varname=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)

        # Substitutions and ensure proper value
        printf -v value "$value" "$name" # substitute the $name variable
        value=$(echo "$value" | sed 's/"//g') # remove quotes
        echo "parsed: $varname=$value"

        # Export the var to the session
        export $varname=$value
    done < $1
}
