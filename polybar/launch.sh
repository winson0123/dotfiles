#!/bin/zsh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config
polybar mybar &
echo "Polybar launched..."

# Attempt to launch polybar on second monitor
polybar mybar_external &

if pgrep -f "polybar mybar_external" > /dev/null; then
	echo "External Polybar launched..."
else
	echo "Failed to launch external Polybar..."
fi

