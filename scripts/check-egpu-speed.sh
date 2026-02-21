#!/usr/bin/env nix-shell
#! nix-shell -i bash -p libnotify

while true; do
    OUTPUT=$(boltctl list)

    RX_SPEED=$(echo "$OUTPUT" | grep -oP '(?<=rx speed:)\s+\K[0-9]+')
    TX_SPEED=$(echo "$OUTPUT" | grep -oP '(?<=tx speed:)\s+\K[0-9]+')

    if [[ -n "$RX_SPEED" ]] && [[ -n "$TX_SPEED" ]]; then
        if [[ "$RX_SPEED" -ne 40 ]] || [[ "$TX_SPEED" -ne 40 ]]; then
            notify-send -u critical "eGPU Speed Warning" \
                "eGPU dock running at ${RX_SPEED}/${TX_SPEED} Gbps instead of 40 Gbps!\n\nReconnect the dock to fix."
        fi
    fi

    sleep 5
done
