#!/bin/bash

# watch.sh - Watch for file changes and rebuild

echo "👀 Watching for Swift file changes..."

# Function to rebuild
rebuild() {
    echo "🔄 Files changed, rebuilding..."
    ./scripts/preview-swift.sh
}

# Watch Swift files for changes
if command -v fswatch >/dev/null 2>&1; then
    fswatch -o Sources/ | while read -r _; do rebuild; done
else
    echo "⚠️  fswatch not installed. Install with: brew install fswatch"
    echo "For now, run ./scripts/preview-swift.sh manually after changes"
fi
