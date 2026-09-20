#!/bin/bash

set -u

ASOUND="$HOME/.asoundrc"

# Find the ALSA card number for the onboard HD-Audio Generic controller.
find_generic_card() {
    awk '$2 ~ /^\[Generic/ { print $1; exit }' /proc/asound/cards
}

# Wait for ALSA to expose the Generic controller.
GENERIC_CARD=""

for i in {1..30}; do
    GENERIC_CARD="$(find_generic_card)"

    if [[ -n "$GENERIC_CARD" ]]; then
        break
    fi

    sleep 1
done

if [[ -z "$GENERIC_CARD" ]]; then
    echo "ERROR: Could not find Generic ALSA card"
    cat /proc/asound/cards
    exit 1
fi

echo "Found Generic ALSA card: $GENERIC_CARD"

# Generate the A52 configuration using the discovered card number.
cat > "$ASOUND" <<ASOUND_EOF
pcm.dolby51 {
    type plug
    slave.pcm "a52:${GENERIC_CARD},'hw:${GENERIC_CARD},1'"
}

ctl.dolby51 {
    type hw
    card ${GENERIC_CARD}
}
ASOUND_EOF

echo "Generated $ASOUND:"
cat "$ASOUND"

# Wait for PipeWire-Pulse.
for i in {1..60}; do
    if pactl info >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! pactl info >/dev/null 2>&1; then
    echo "ERROR: PipeWire-Pulse unavailable"
    exit 1
fi

# Give ALSA/PipeWire a moment to settle.
sleep 2

# Remove an old dolby51 sink if one exists.
if pactl list short sinks | command grep -q '[[:space:]]dolby51[[:space:]]'; then
    pactl unload-module module-alsa-sink 2>/dev/null || true
    sleep 1
fi

# Create the PipeWire sink.
for i in {1..15}; do
    if pactl load-module module-alsa-sink \
        device=dolby51 \
        sink_name=dolby51 \
        sink_properties='device.description="Dolby Digital 5.1 (TOSLINK)"' \
        >/dev/null 2>&1; then
        break
    fi

    sleep 2
done

# Verify sink creation.
if ! pactl list short sinks | command grep -q '[[:space:]]dolby51[[:space:]]'; then
    echo "ERROR: Failed to create PipeWire dolby51 sink"
    exit 1
fi

# Make Dolby Digital the default.
pactl set-default-sink dolby51

echo "Dolby Digital 5.1 sink ready using ALSA card $GENERIC_CARD"
