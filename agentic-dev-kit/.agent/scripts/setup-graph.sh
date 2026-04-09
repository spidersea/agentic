#!/bin/bash
# setup-graph.sh — 安装并初始化 graphify 知识图谱
# 用法: bash .agent/scripts/setup-graph.sh [project-root]

set -euo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "🔧 Graphify 知识图谱初始化"
echo "=========================="
echo ""

# 1. 检查 Python 版本
python3 --version 2>/dev/null || { echo "❌ Python 3.10+ required"; exit 1; }

# 2. 检查 graphify
if python3 -c "import graphify" 2>/dev/null; then
    echo "✅ graphify 已就绪"
else
    echo "📦 安装 graphifyy..."
    pip3 install graphifyy --user --break-system-packages 2>/dev/null || pip3 install graphifyy --user
    echo "✅ graphify 已安装"
fi

# 3. 创建 .graphifyignore（如不存在）
if [ ! -f ".graphifyignore" ]; then
    echo "📝 创建 .graphifyignore..."
    cat > .graphifyignore << 'EOF'
# Graphify ignore patterns (same syntax as .gitignore)
node_modules/
dist/
.venv/
__pycache__/
*.min.js
*.min.css
*.lock
*.generated.*
vendor/
coverage/
.next/
EOF
    echo "✅ .graphifyignore 已创建"
else
    echo "✅ .graphifyignore 已存在"
fi

# 4. 构建图谱
echo ""
echo "🏗️ 构建知识图谱..."
mkdir -p graphify-out
python3 -c "import sys; open('graphify-out/.graphify_python', 'w').write(sys.executable)"
echo "  Python: $(cat graphify-out/.graphify_python)"
echo "  请在 AI 助手中运行 /graphify . 进行完整构建"

echo ""
echo "📊 安装完成!"
echo "   用法:"
echo "   - 构建图谱: /graphify ."
echo "   - 查询图谱: /graphify query \"...\""
echo "   - 路径追踪: /graphify path \"A\" \"B\""
echo "   - 增量更新: /graphify . --update"
