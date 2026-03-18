#!/bin/bash
# setup-graph.sh — 安装并初始化 code-review-graph 代码知识图谱
# 用法: bash .agent/scripts/setup-graph.sh [项目根目录]

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "🔍 检查环境..."

# 1. 检查 Python 版本
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 python3，请先安装 Python 3.10+"
    exit 1
fi

PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]); then
    echo "❌ Python 版本 $PY_VERSION 不满足要求（需要 3.10+）"
    exit 1
fi
echo "✅ Python $PY_VERSION"

# 2. 检查 uv
if ! command -v uv &> /dev/null; then
    echo "⚠️  未找到 uv，尝试安装..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "✅ uv 已安装"
else
    echo "✅ uv 已就绪"
fi

# 3. 安装 code-review-graph
if ! command -v code-review-graph &> /dev/null; then
    echo "📦 安装 code-review-graph..."
    pip install code-review-graph
    echo "✅ code-review-graph 已安装"
else
    echo "✅ code-review-graph 已就绪"
fi

# 4. 注册 MCP 服务器（可选，仅 Claude Code 环境）
# code-review-graph install

# 5. 创建 .code-review-graphignore（如不存在）
if [ ! -f ".code-review-graphignore" ]; then
    echo "📝 创建 .code-review-graphignore..."
    cat > .code-review-graphignore << 'EOF'
# 排除不需要索引的目录
node_modules/**
dist/**
build/**
.venv/**
__pycache__/**
*.min.js
*.min.css
*.generated.*
vendor/**
.git/**
EOF
    echo "✅ .code-review-graphignore 已创建"
else
    echo "✅ .code-review-graphignore 已存在"
fi

# 6. 首次全量构建图谱
echo "🏗️  构建代码知识图谱（首次全量构建）..."
code-review-graph build

# 7. 显示图谱状态
echo ""
echo "📊 图谱状态："
code-review-graph status

echo ""
echo "🎉 代码知识图谱初始化完成！"
echo "   - 增量更新: code-review-graph update"
echo "   - 查看状态: code-review-graph status"
echo "   - 可视化:   code-review-graph visualize"
