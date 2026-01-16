#!/bin/bash
# Quick diagnostic script to launch app and capture stdout

echo "🔍 Launching V2RayUSA with stdout capture..."
echo ""

cd /Volumes/Daniel\ K1/Antigravity/V2RayUSA

# Kill any existing instance
killall V2RayUSA 2>/dev/null
sleep 1

# Launch and capture output
./build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA &
APP_PID=$!

echo "✅ App launched with PID: $APP_PID"
echo ""
echo "Waiting for initialization (5 seconds)..."
sleep 5

echo ""
echo "📊 Status Check:"
echo "  Process running: $(ps -p $APP_PID >/dev/null && echo '✅ YES' || echo '❌ NO')"
echo "  PID: $APP_PID"
echo ""

# Check menubar items
echo "🔍 Checking for menubar status items..."
echo ""

# Keep running so we can see output
echo "App is running. Check your menubar for the 🔒 icon."
echo "Press Ctrl+C to stop."
echo ""

# Wait and show any output
tail -f /dev/null
