#!/bin/bash

# Directory for the script and log file
SCRIPT_DIR="/etc/moodle-docker"
LOG_FILE="$SCRIPT_DIR/import_mbz.log"

# Log function to add timestamped messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Script started."

# Check if the Docker container is running
CONTAINER_NAME="moodle-moodle-1"
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    log_message "Starting the Docker container..."
    docker start $CONTAINER_NAME
    if [ $? -ne 0 ]; then
        log_message "Failed to start the Docker container."
        exit 1
    fi
else
    log_message "Docker container is already running."
fi

# Set the directory containing MBZ files
MBZ_FILES_DIR="/etc/moodle-docker/mbz_files"

# Detecting MBZ files in the external drive
EXTERNAL_DRIVE_DIR="/mnt/external_drive"
log_message "Checking for MBZ files in $EXTERNAL_DRIVE_DIR..."
find "$EXTERNAL_DRIVE_DIR" -type f -name "*.mbz" -exec cp {} "$MBZ_FILES_DIR" \;

# Check if there are MBZ files in the directory
log_message "Checking for MBZ files in $MBZ_FILES_DIR..."
MBZ_FILES=$(find "$MBZ_FILES_DIR" -type f -name "*.mbz")

if [ -z "$MBZ_FILES" ]; then
    log_message "No MBZ files found in $MBZ_FILES_DIR."
    exit 0
fi

# Loop through each MBZ file and restore it to Moodle
for mbz_file in $MBZ_FILES; do
    if [ -f "$mbz_file" ]; then
        log_message "Restoring $mbz_file to Moodle..."

        # Copy the .mbz file into the Docker container
        docker cp "$mbz_file" "$CONTAINER_NAME:/backup/moodle_backup/mbz_files/"

        # Get the base name of the .mbz file
        BASENAME=$(basename "$mbz_file")

        # Restore the course from the .mbz file using the manual method
        docker exec -u root $CONTAINER_NAME php /var/www/html/admin/cli/restore_backup.php --file="/backup/moodle_backup/mbz_files/$BASENAME" --categoryid=1

        if [ $? -eq 0 ]; then
            log_message "Successfully restored $BASENAME."
            # Delete the .mbz file upon successful restore
            rm -rf "$mbz_file"
            if [ $? -eq 0 ]; then
                log_message "Successfully deleted $BASENAME from $MBZ_FILES_DIR."
            else
                log_message "Failed to delete $BASENAME from $MBZ_FILES_DIR."
            fi
        else
            log_message "Failed to restore $BASENAME."
        fi
    fi
done

log_message "Script completed."