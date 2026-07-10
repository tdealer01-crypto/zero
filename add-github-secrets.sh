#!/bin/bash

# =====================================================
# DSG GitHub Secrets Configuration Script
# =====================================================
# This script adds environment variables from Vercel
# to GitHub repository secrets for CI/CD pipelines
# =====================================================

set -e

echo "🔐 DSG GitHub Secrets Setup"
echo "================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install from: https://cli.github.com"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Get repository info
REPO=$(git remote get-url origin | sed 's/.*://g' | sed 's/.git$//')
echo "📦 Repository: $REPO"
echo ""

# =====================================================
# Supabase Configuration
# =====================================================
echo "🔗 Supabase Configuration"
echo "================================"
echo "Go to: Supabase Dashboard → Settings → API"
echo ""

read -p "Enter NEXT_PUBLIC_SUPABASE_URL (or press Enter to skip): " SUPABASE_URL
if [ -n "$SUPABASE_URL" ]; then
    echo "$SUPABASE_URL" | gh secret set NEXT_PUBLIC_SUPABASE_URL --repo "$REPO"
    echo "✅ NEXT_PUBLIC_SUPABASE_URL added"
fi

read -p "Enter NEXT_PUBLIC_SUPABASE_ANON_KEY (or press Enter to skip): " SUPABASE_ANON
if [ -n "$SUPABASE_ANON" ]; then
    echo "$SUPABASE_ANON" | gh secret set NEXT_PUBLIC_SUPABASE_ANON_KEY --repo "$REPO"
    echo "✅ NEXT_PUBLIC_SUPABASE_ANON_KEY added"
fi

read -p "Enter SUPABASE_SERVICE_ROLE_KEY (or press Enter to skip): " SUPABASE_SERVICE
if [ -n "$SUPABASE_SERVICE" ]; then
    echo "$SUPABASE_SERVICE" | gh secret set SUPABASE_SERVICE_ROLE_KEY --repo "$REPO"
    echo "✅ SUPABASE_SERVICE_ROLE_KEY added"
fi

echo ""

# =====================================================
# NVIDIA Configuration
# =====================================================
echo "🤖 NVIDIA Configuration"
echo "================================"
echo "Get key from: https://build.nvidia.com (API keys)"
echo ""

read -p "Enter NVIDIA_API_KEY (or press Enter to skip): " NVIDIA_KEY
if [ -n "$NVIDIA_KEY" ]; then
    echo "$NVIDIA_KEY" | gh secret set NVIDIA_API_KEY --repo "$REPO"
    echo "✅ NVIDIA_API_KEY added"
fi

echo ""

# =====================================================
# Stripe Configuration
# =====================================================
echo "💳 Stripe Configuration"
echo "================================"
echo "Get from: Stripe Dashboard → Developers → API Keys"
echo ""

read -p "Enter STRIPE_SECRET_KEY (or press Enter to skip): " STRIPE_KEY
if [ -n "$STRIPE_KEY" ]; then
    echo "$STRIPE_KEY" | gh secret set STRIPE_SECRET_KEY --repo "$REPO"
    echo "✅ STRIPE_SECRET_KEY added"
fi

echo ""

# =====================================================
# NextAuth Configuration
# =====================================================
echo "🔑 NextAuth Configuration"
echo "================================"

read -p "Enter NEXTAUTH_SECRET (or press Enter to skip): " NEXTAUTH_SECRET
if [ -n "$NEXTAUTH_SECRET" ]; then
    echo "$NEXTAUTH_SECRET" | gh secret set NEXTAUTH_SECRET --repo "$REPO"
    echo "✅ NEXTAUTH_SECRET added"
fi

echo ""

# =====================================================
# Optional: GitHub Token for CI/CD
# =====================================================
echo "🚀 CI/CD Configuration (Optional)"
echo "================================"

read -p "Enter GITHUB_TOKEN for actions (or press Enter to skip): " GITHUB_TOKEN
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | gh secret set GITHUB_TOKEN --repo "$REPO"
    echo "✅ GITHUB_TOKEN added"
fi

echo ""

# =====================================================
# Verification
# =====================================================
echo "✅ Secret Configuration Complete!"
echo "================================"
echo ""
echo "📋 Secrets added to: $REPO"
echo ""
echo "🔍 To verify, run:"
echo "   gh secret list --repo $REPO"
echo ""
echo "Next steps:"
echo "1. Push a test commit to trigger CI/CD"
echo "2. Check GitHub Actions for successful runs"
echo "3. Verify Vercel deployment builds successfully"
echo ""
echo "ทำเสร็จแล้ว ✅"
