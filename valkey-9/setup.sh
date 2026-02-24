#!/bin/bash

# Valkey 9.0 Presentation Setup Script
# This script sets up everything you need to run the presentation

set -e

echo "🚀 Setting up Valkey 9.0 Presentation..."
echo ""

# Check for Node.js
echo "📦 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js first:"
    echo "  Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
    echo "  macOS: brew install node"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js $NODE_VERSION found"

# Check for npm
echo "📦 Checking npm installation..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed!"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo "✅ npm $NPM_VERSION found"
echo ""

# Check for pnpm
echo "📦 Checking pnpm installation..."
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is not installed!"
    exit 1
fi

PNPM_VERSION=$(pnpm --version)
echo "✅ pnpm $NPM_VERSION found"
echo ""

# Install Slidev globally
echo "📥 Installing Slidev..."
if ! command -v slidev &> /dev/null; then
    pnpm install -g @slidev/cli
    echo "✅ Slidev installed successfully"
else
    echo "✅ Slidev already installed"
fi
echo ""

# Initialize npm project if needed
if [ ! -f "package.json" ]; then
    echo "📝 Initializing npm project..."
    pnpm init -y
fi

# Install Slidev dependencies locally
echo "📥 Installing Slidev dependencies..."
pnpm install --save-dev @slidev/cli @slidev/theme-default
echo "✅ Dependencies installed"
echo ""

# Check for Valkey
echo "🔍 Checking for Valkey 9.0..."
if command -v valkey-server &> /dev/null; then
    VALKEY_VERSION=$(valkey-server --version | grep -oP 'v=\K[0-9.]+' || echo "unknown")
    echo "✅ Valkey found (version: $VALKEY_VERSION)"
    
    if [[ "$VALKEY_VERSION" < "9.0.0" ]]; then
        echo "⚠️  Warning: Valkey version is older than 9.0.0"
        echo "   Some demo features may not work"
    fi
else
    echo "⚠️  Valkey not found in PATH"
    echo ""
    echo "To install Valkey 9.0:"
    echo ""
    echo "Option 1 - Docker:"
    echo "  docker pull valkey/valkey:9.0"
    echo ""
    echo "Option 2 - Build from source:"
    echo "  wget https://github.com/valkey-io/valkey/archive/refs/tags/9.0.0.tar.gz"
    echo "  tar xzf 9.0.0.tar.gz"
    echo "  cd valkey-9.0.0 && make"
    echo ""
fi

# Check for Python (optional, for demos)
echo ""
echo "🐍 Checking for Python (optional for demos)..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ $PYTHON_VERSION found"
    
    # Check for valkey-glide
    if python3 -c "import glide" 2>/dev/null; then
        echo "✅ valkey-glide installed"
    else
        echo "⚠️  valkey-glide not installed"
        echo "   Install with: pip install valkey-glide"
    fi
else
    echo "⚠️  Python3 not found"
    echo "   Python is optional but recommended for demo scripts"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "To start the presentation:"
echo "  slidev valkey-9-presentation.md"
echo ""
echo "To view presenter mode:"
echo "  Open http://localhost:3030/presenter in your browser"
echo ""
echo "To export to PDF:"
echo "  slidev export valkey-9-presentation.md --format pdf"
echo ""
echo "For demo commands, see: demo-script.md"
echo ""
echo "Happy presenting! 🎉"
