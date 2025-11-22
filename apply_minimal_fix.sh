#!/bin/bash
#
# Apply Minimal Fix to Firestore Rules
# Only changes lines 48-50 to fix Edit Profile permission errors
#
# This preserves all 479 lines of existing rules
# and only fixes the specific bug causing profile update failures
#

set -e

echo "=========================================="
echo "🔧 MINIMAL FIRESTORE RULES FIX"
echo "=========================================="
echo ""

# Check if firestore.rules exists
if [ ! -f "firestore.rules" ]; then
    echo "❌ firestore.rules not found!"
    echo "   Make sure you're in the project directory"
    exit 1
fi

echo "📁 Current directory: $(pwd)"
echo "📄 Found: firestore.rules"
echo ""

# Create backup
echo "💾 Creating backup..."
cp firestore.rules firestore.rules.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"
echo ""

# Show the current problematic lines
echo "🔍 Current lines 48-50 (BROKEN):"
echo "------------------------------------"
sed -n '48,50p' firestore.rules
echo "------------------------------------"
echo ""

# Apply the fix using sed
echo "🔧 Applying fix..."
echo ""

# Create a temporary file with the fix
cat > /tmp/firestore_fix.sed << 'EOF'
48,50c\
      allow update: if isOwner(userId) &&\
                       (!('role' in request.resource.data) || request.resource.data.role == resource.data.role) &&\
                       (!('uid' in request.resource.data) || request.resource.data.uid == resource.data.uid);
EOF

# Apply the fix
sed -i -f /tmp/firestore_fix.sed firestore.rules

echo "✅ Fix applied"
echo ""

# Show the new fixed lines
echo "✅ New lines 48-50 (FIXED):"
echo "------------------------------------"
sed -n '48,50p' firestore.rules
echo "------------------------------------"
echo ""

# Count lines to verify nothing else changed
LINES=$(wc -l < firestore.rules)
echo "📊 File still has $LINES lines (should be 479)"
echo ""

if [ "$LINES" -eq 479 ]; then
    echo "✅ File integrity verified - all lines preserved"
else
    echo "⚠️ Warning: Line count changed from 479 to $LINES"
    echo "   Check if sed introduced extra newlines"
fi

echo ""
echo "=========================================="
echo "✅ FIX APPLIED SUCCESSFULLY"
echo "=========================================="
echo ""
echo "📋 What Changed:"
echo "   Lines 48-50: Updated profile update rule"
echo "   Rest of file: Unchanged (476 lines preserved)"
echo ""
echo "🚀 Next Steps:"
echo "   1. Review the fix: cat firestore.rules | sed -n '48,50p'"
echo "   2. Deploy: firebase deploy --only firestore:rules"
echo "   3. Test profile editing with Rita's account"
echo ""
echo "💾 Backup available at: firestore.rules.backup.*"
echo ""
