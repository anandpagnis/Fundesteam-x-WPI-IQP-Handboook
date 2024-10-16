#!/bin/bash

# Directory to mount the USB drive
MOUNT_DIR="/mnt/external"

# Create the mount directory if it doesn't exist
mkdir -p $MOUNT_DIR

# USB device to mount
USB_DEVICE="/dev/sda1"

# Attempt to mount the USB drive
if sudo mount "$USB_DEVICE" "$MOUNT_DIR" 2>> /tmp/mount-errors.log; then
    echo "Successfully mounted $USB_DEVICE to $MOUNT_DIR"
else
    echo "Failed to mount $USB_DEVICE" >> /tmp/mount-errors.log
fi