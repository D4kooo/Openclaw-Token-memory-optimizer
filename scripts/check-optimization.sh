#!/bin/bash
# Token Optimizer - Check Optimization Status
# Usage: ./check-optimization.sh [config-path]

CONFIG="${1:-$HOME/.openclaw/openclaw.json}"

echo "🔍 Token Optimizer - Status Check"
echo "=================================="

if [ ! -f "$CONFIG" ]; then
    echo "❌ Config not found: $CONFIG"
    exit 1
fi

echo ""
echo "📋 Checking: $CONFIG"
echo ""

# Check cron isolation
echo "1️⃣  Cron Job Isolation"
if grep -q '"sessionTarget".*"isolated"' "$CONFIG" 2>/dev/null; then
    ISOLATED=$(grep -c '"sessionTarget".*"isolated"' "$CONFIG")
    MAIN=$(grep -c '"sessionTarget".*"main"' "$CONFIG" || echo "0")
    echo "   ✅ Found $ISOLATED isolated job(s)"
    [ "$MAIN" != "0" ] && echo "   ⚠️  Found $MAIN job(s) still in main session"
else
    echo "   ⚠️  No isolated jobs found - background tasks may bloat context"
fi

echo ""

# Check RAG configuration
echo "2️⃣  Local RAG Configuration"
if grep -q '"memorySearch"' "$CONFIG" 2>/dev/null; then
    echo "   ✅ memorySearch configured"
    if grep -q '"provider".*"local"' "$CONFIG"; then
        echo "   ✅ Using local embeddings"
    else
        echo "   ℹ️  Using remote embeddings (may incur API costs)"
    fi
else
    echo "   ⚠️  memorySearch not configured - using full history reads"
fi

echo ""

# Check memory files
echo "3️⃣  Memory Files"
MEMORY_DIR="${CONFIG%/*}/../workspace/memory"
if [ -d "$MEMORY_DIR" ]; then
    COUNT=$(ls -1 "$MEMORY_DIR"/*.md 2>/dev/null | wc -l)
    echo "   ✅ Found $COUNT memory file(s)"
else
    echo "   ⚠️  No memory/ directory found"
fi

if [ -f "${CONFIG%/*}/../workspace/MEMORY.md" ]; then
    SIZE=$(wc -c < "${CONFIG%/*}/../workspace/MEMORY.md")
    echo "   ✅ MEMORY.md exists ($(numfmt --to=iec $SIZE 2>/dev/null || echo "$SIZE bytes"))"
else
    echo "   ⚠️  No MEMORY.md found"
fi

echo ""
echo "=================================="
echo "Run 'session_status' in your agent for live token count."
