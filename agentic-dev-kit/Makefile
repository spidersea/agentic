# Agentic Dev Kit — Build & Test
# Usage: make test | make validate | make health | make stress-test

SHELL := /bin/bash
PROJECT_ROOT := $(shell pwd)
SCRIPTS := .agent/scripts

.PHONY: all test validate health stress-test lint help

all: test

# ─── 验证 ────────────────────────────────────────────────────
validate: ## 验证框架结构完整性
	@bash $(SCRIPTS)/validate-structure.sh $(PROJECT_ROOT)

health: ## 运行健康检查
	@bash $(SCRIPTS)/health-check.sh $(PROJECT_ROOT)

stress-test: ## 运行量化评分引擎
	@bash $(SCRIPTS)/stress-test-engine.sh $(PROJECT_ROOT)

# ─── 测试 ────────────────────────────────────────────────────
test: ## 运行全量自动化测试
	@bash tests/test-all.sh

lint: ## 检查所有脚本语法
	@bash tests/test-scripts-syntax.sh

# ─── 帮助 ────────────────────────────────────────────────────
help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
