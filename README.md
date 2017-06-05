# NTFSWriteEnabler
Since macOS 10.11, write functionality for NTFS (Windows) formatted drives have been disabled. This utility edits the File System Table in /etc/fstab. Implemeneted in Objective-c.

Tested on Macbook Pro Retina with 10.12.5

# Known Issues
- Cannot access drive under Devices in Finder : writing to fstab requires that finder is set to 'nobrowse'. No way to circumvent this currently.
- Does not work for internal drives. Limited to removable hardware.
- Does not format drives to NTFS or work on any non-NTFS drive.
