#!/bin/bash
# filepath: /root/src/sanoid-master/compare_directories.sh

# Define the two directories to compare
DIR1="/alpha/home/davec"
DIR2="/home/davec"

echo "Comparing directories:"
echo "Source: $DIR1"
echo "Target: $DIR2"
echo "---------------------------------"

# Check if both directories exist
if [ ! -d "$DIR1" ]; then
    echo "Error: Source directory $DIR1 does not exist."
    exit 1
fi

if [ ! -d "$DIR2" ]; then
    echo "Error: Target directory $DIR2 does not exist."
    exit 1
fi

# Create temporary files to store directory listings
TEMP1=$(mktemp)
TEMP2=$(mktemp)

# List all files recursively in both directories
find "$DIR1" -type f -printf "%P\n" | sort > "$TEMP1"
find "$DIR2" -type f -printf "%P\n" | sort > "$TEMP2"

# Find files that are in DIR1 but not in DIR2
echo "Files present in $DIR1 but missing in $DIR2:"
comm -23 "$TEMP1" "$TEMP2" >> diff.txt

# Count missing files
MISSING_COUNT=$(comm -23 "$TEMP1" "$TEMP2" | wc -l)
echo "---------------------------------"
echo "Total files missing: $MISSING_COUNT"

# Clean up temporary files
rm "$TEMP1" "$TEMP2"
