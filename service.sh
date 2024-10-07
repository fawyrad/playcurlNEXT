#!/system/bin/sh

################################################################### Check if boot completed
check_boot_completed() {
    while true; do
        if [ "$(getprop sys.boot_completed)" = "1" ]; then
            echo "Boot process completed"
            return 0
        else
            echo "Waiting for boot process to complete..."
            sleep 10  # Wait 10 seconds before checking again
        fi
    done
}

# Wait until the boot is complete
check_boot_completed

while true; do
    ################################################################### Declare vars
    # Detect busybox
    busybox_path=""

    if [ -f "/data/adb/magisk/busybox" ]; then
        busybox_path="/data/adb/magisk/busybox"
    elif [ -f "/data/adb/ksu/bin/busybox" ]; then
        busybox_path="/data/adb/ksu/bin/busybox"
    elif [ -f "/data/adb/ap/bin/busybox" ]; then
        busybox_path="/data/adb/ap/bin/busybox"
    fi
    ###################################################################

    ################################################################### Download pif
    echo "[+] Downloading the pif.json"

    # Temp file to capture errors
    error_log="/data/adb/curl_error.log"

    if [ -f /data/adb/modules/playintegrityfix/migrate.sh ]; then
        if [ -d /data/adb/modules/tricky_store ]; then
            # Download osmosis.json
            if /system/bin/curl -o /data/adb/modules/playintegrityfix/custom.pif.json https://raw.githubusercontent.com/daboynb/autojson/main/osmosis.json > /dev/null 2> "$error_log"; then
                echo "[+] Successfully downloaded osmosis.json."
            else
                echo "[-] Failed to download osmosis.json."
                echo "Error: $(cat $error_log)"
            fi
        else
            # If tricky_store does not exist, download device_osmosis.json
            if /system/bin/curl -o /data/adb/modules/playintegrityfix/custom.pif.json https://raw.githubusercontent.com/daboynb/autojson/main/device_osmosis.json > /dev/null 2> "$error_log"; then
                echo "[+] Successfully downloaded device_osmosis.json."
            else
                echo "[-] Failed to download device_osmosis.json."
                echo "Error: $(cat $error_log)"
            fi
        fi
    else
        # Download chiteroman.json
        if /system/bin/curl -L "https://raw.githubusercontent.com/daboynb/autojson/main/chiteroman.json" -o /data/adb/pif.json > /dev/null 2> "$error_log"; then
            echo "[+] Successfully downloaded chiteroman.json."
        else
            echo "[-] Failed to download chiteroman.json."
            echo "Error: $(cat $error_log)"
        fi
    fi

    ###################################################################

    ################################################################### Check unsigned rom
    # Check the keys of /system/etc/security/otacerts.zip
    get_keys=$("$busybox_path" unzip -l /system/etc/security/otacerts.zip)

    if echo "$get_keys" | "$busybox_path" grep -q test; then
        echo ""
        echo "Setting custom props"
        
        # Check for the presence of migrate.sh and use the appropriate file path
        if [ -f /data/adb/modules/playintegrityfix/migrate.sh ]; then
            $busybox_path sed -i 's/"spoofSignature": *0/"spoofSignature": 1/g' /data/adb/modules/playintegrityfix/custom.pif.json
        else
            $busybox_path sed -i 's/"spoofSignature": *"false"/"spoofSignature": "true"/g' /data/adb/pif.json
        fi

        # Kill GMS processes
        killall com.google.android.gms
        killall com.google.android.gms.unstable
    fi
    ###################################################################

    ################################################################### 
    # Sleep for 3 seconds after the echo
    sleep 3

    # Clean up the error log file
    rm -f "$error_log"
    ###################################################################
    
    # Wait for 30 minutes before repeating the script
    filepath="/data/adb/modules/playcurlNEXT/seconds.txt"
    time_interval=$(cat "$filepath")
    sleep $time_interval 
done