# ==========================================
# 使用说明 (Usage Examples):
# 1. 基础更新: make up msg="修复算法逻辑"
# 2. 同步子模块: make sup msg="更新预言机接口"
# 3. 开发新功能: make newup branch=feat/energy msg="新增数据分析"
# 4. 合并并删除: make ship branch=feat/energy msg="完成能源调度优化"
# 5. 子模块+主仓库 PR: make spr branch=feat/energy msg="重构能源调度核心算法"
# 6. 全自动从main分支新建分支后pr后回main:
# make fullpr branch=feat/new-logic msg="重构能源调度核心算法"
# ==========================================

# --- CONSTANTS (常量定义) ---
SUB_PATH = guide  # 改成你真实的文件夹名
MAIN_BRANCH = main

.PHONY: help up newup ship sup spr

# 默认命令：输入 make 就会显示帮助
help:
	@echo "--- 常用命令实例 ---"
	@echo "make up msg='说明文字'          # 提交当前分支"
	@echo "make sup msg='说明文字'         # 先同步子模块再同步主仓库"
	@echo "make newup branch=名 msg='文字'  # 建新分支并推送"
	@echo "make ship branch=名 msg='文字'   # 合并回main并删分支"
	@echo ""
	@echo "--- Skill 一键命令 ---"
	@echo "make skill-help                          # 查看 skill 命令"
	@echo "make skill-new skill=foo resources=references"
	@echo "make skill-sync                          # 默认 skill: programming-insights-publisher"
	@echo "make skill-validate"
	@echo "make prompt-daily"
	@echo "make prompt-weekly"
	@echo "make prompt-monthly"
	@echo "make daily-note"
	@echo "make weekly-post"
	@echo "make today-insight"
	@echo "make weekly-insight"
	@echo "(可覆盖) make today-insight SKILL_NAME=foo"
	@echo "(可覆盖) make today-insight CODEX_BIN=/path/to/codex"

# 1. 基础提交
up:
	@if [ -z "$(msg)" ]; then echo "Error: 请输入 msg='说明文字'"; exit 1; fi
	@BRANCH=$$(git symbolic-ref --short HEAD); \
	git add -A && \
	git commit -m "[$$BRANCH] $(msg)" && \
	git push

# 2. 新分支提交
newup:
	@if [ -z "$(branch)" ] || [ -z "$(msg)" ]; then echo "Error: 请指定 branch= 和 msg="; exit 1; fi
	@git checkout -b $(branch) && \
	git add -A && \
	git commit -m "$(msg)" && \
	git push -u origin $(branch)

# 3. 洁癖版交付
ship:
	@if [ -z "$(branch)" ] || [ -z "$(msg)" ]; then echo "Error: 请指定 branch= 和 msg="; exit 1; fi
	@git checkout $(MAIN_BRANCH) && git pull && \
	git checkout -b $(branch) && \
	git add -A && \
	git commit -m "$(msg)" && \
	git push -u origin $(branch) && \
	git checkout $(MAIN_BRANCH) && \
	git merge --ff-only $(branch) && \
	git push origin $(MAIN_BRANCH) && \
	git branch -d $(branch) && \
	git push origin --delete $(branch)

# 4. 子模块+主仓库一键提交
sup:
	@if [ -z "$(msg)" ]; then echo "Error: 请输入 msg='说明文字'"; exit 1; fi
	@echo ">>> 正在同步子模块..."
	@cd $(SUB_PATH) && \
	git add -A && \
	if git diff --cached --quiet; then \
		echo ">>> 子模块无变更，直接 push 当前分支"; \
		git push; \
	else \
		git commit -m "[Submodule] $(msg)" && git push; \
	fi
	@echo ">>> 正在同步主仓库..."
	@git add -A && \
	if git diff --cached --quiet; then \
		echo ">>> 主仓库无变更，直接 push 当前分支"; \
		git push; \
	else \
		$(MAKE) up msg="chore: sync submodule - $(msg)"; \
	fi

# 5. 子模块+主仓库一键 PR (需安装 GitHub CLI)
spr:
	@if [ -z "$(branch)" ] || [ -z "$(msg)" ]; then \
		echo "Error: 请指定 branch=分支名 msg='说明文字'"; exit 1; \
	fi
	@echo ">>> [1/2] 正在处理子模块 PR..."
	@cd $(SUB_PATH) && \
		git checkout -b $(branch) && \
		git add -A && \
		git commit -m "[Submodule] $(msg)" && \
		git push -u origin $(branch) && \
		gh pr create --title "[Submodule] $(msg)" --body "Automated PR from Makefile" --base $(MAIN_BRANCH)
	
	@echo ">>> [2/2] 正在处理主仓库 PR..."
	@git checkout -b $(branch) && \
		git add -A && \
		git commit -m "[Main] sync submodule for $(msg)" && \
		git push -u origin $(branch) && \
		gh pr create --title "[Main] $(msg)" --body "Depends on submodule PR: $(branch)" --base $(MAIN_BRANCH)
	
	@echo ">>> 双端 PR 已创建。请先合并子模块 PR，再合并主仓库 PR。"

# 6. 全自动化：主子模块同开新分支 -> 提PR -> 切回main
fullpr:
	@# 检查主仓库是否在 main 分支
	@CURRENT_BRANCH=$$(git symbolic-ref --short HEAD); \
	if [ "$$CURRENT_BRANCH" != "$(MAIN_BRANCH)" ]; then \
		echo "Error: 请先手动切换到 $(MAIN_BRANCH) 分支后再运行此命令"; exit 1; \
	fi
	@if [ -z "$(branch)" ] || [ -z "$(msg)" ]; then \
		echo "Error: 请指定 branch=分支名 msg='说明文字'"; exit 1; \
	fi

	@echo ">>> [1/2] 正在处理子模块: $(SUB_PATH) ..."
	@cd $(SUB_PATH) && \
		git checkout $(MAIN_BRANCH) && git pull && \
		git checkout -b $(branch) && \
		git add -A && \
		git commit -m "[Submodule] $(msg)" && \
		git push -u origin $(branch) && \
		gh pr create --title "[Submodule] $(msg)" --body "Automated Submodule PR" --base $(MAIN_BRANCH) && \
		git checkout $(MAIN_BRANCH)

	@echo ">>> [2/2] 正在处理主仓库..."
	@git checkout -b $(branch) && \
		git add -A && \
		git commit -m "[Main] sync submodule for $(msg)" && \
		git push -u origin $(branch) && \
		gh pr create --title "[Main] $(msg)" --body "Depends on submodule PR: $(branch)" --base $(MAIN_BRANCH) && \
		git checkout $(MAIN_BRANCH)

	@echo ">>> 流程结束！主子模块均已切回 $(MAIN_BRANCH)。"
	@echo ">>> 请按顺序在 Web 端 Merge: 1.子模块 PR -> 2.主仓库 PR。"