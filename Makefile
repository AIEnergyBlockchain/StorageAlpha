# ==========================================
# 使用说明 (Usage Examples):
# 1. 基础更新: make up msg="修复算法逻辑"
# 2. 同步子模块: make sup msg="更新预言机接口"
# 3. 开发新功能: make newup branch=feat/energy msg="新增数据分析"
# 4. 合并并删除: make ship branch=feat/energy msg="完成能源调度优化"
# ==========================================

# --- CONSTANTS (常量定义) ---
SUB_PATH = guide  # 改成你真实的文件夹名
MAIN_BRANCH = main


.PHONY: help up newup ship sup

# 默认命令：输入 make 就会显示帮助
help:
	@echo "--- 常用命令实例 ---"
	@echo "make up msg='说明文字'          # 提交当前分支"
	@echo "make sup msg='说明文字'         # 先同步子模块再同步主仓库"
	@echo "make newup branch=名 msg='文字'  # 建新分支并推送"
	@echo "make ship branch=名 msg='文字'   # 合并回main并删分支"

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

# 6. 最终全自动版：任意分支提交 -> 推送 PR -> 全体切回 main
fullpr:
	@if [ -z "$(msg)" ]; then echo "Error: 请指定 msg='说明文字'"; exit 1; fi
	
	@# 使用 rev-parse 获取分支名，即使在 detached 状态也能拿到哈希，比 symbolic-ref 更稳
	$(eval CUR_BRANCH := $(shell git rev-parse --abbrev-ref HEAD))
	$(eval CUR_SUB_BRANCH := $(shell cd $(SUB_PATH) && git rev-parse --abbrev-ref HEAD))
	
	@echo ">>> 启动全自动流程：主仓库($(CUR_BRANCH)) | 子模块($(CUR_SUB_BRANCH))"
	
	@# --- [1/2] 子模块处理 ---
	@echo ">>> [1/2] 正在处理子模块..."
	@cd $(SUB_PATH) && \
		git add -A && \
		if ! git diff --cached --quiet; then \
			git commit -m "[Submodule] $(msg)" && \
			git push origin $(CUR_SUB_BRANCH) && \
			gh pr create --title "[Submodule] $(msg)" --body "Automated" --base $(MAIN_BRANCH) || echo "PR已存在"; \
		else \
			echo ">>> 子模块无变更，跳过提交"; \
		fi && \
		git checkout $(MAIN_BRANCH) && git pull origin $(MAIN_BRANCH)

	@# --- [2/2] 主仓库处理 ---
	@echo ">>> [2/2] 正在处理主仓库..."
	@# 关键：先 ADD，再判断 diff，最后才准切换分支
	@git add -A
	@if ! git diff --cached --quiet; then \
		git commit -m "[Main] $(msg)" && \
		git push origin $(CUR_BRANCH) && \
		gh pr create --title "[Main] $(msg)" --body "Automated" --base $(MAIN_BRANCH) || echo "PR已存在"; \
	else \
		echo ">>> 主仓库无变更，跳过提交"; \
	fi
	@git checkout $(MAIN_BRANCH) && git pull origin $(MAIN_BRANCH)

# 7. 同时拉取主子仓库 main 分支并更新
sync:
	@echo ">>> [1/2] 正在同步主仓库至 $(MAIN_BRANCH)..."
	@git checkout $(MAIN_BRANCH)
	@git pull origin $(MAIN_BRANCH)
	
	@echo ">>> [2/2] 正在确保所有子模块同步并切换至 $(MAIN_BRANCH)..."
	@# 1. 先初始化并更新指针内容
	@git submodule update --init --recursive
	@# 2. 强制每个子模块切换到 main 并对齐远端
	@git submodule foreach 'git checkout $(MAIN_BRANCH) && git fetch origin $(MAIN_BRANCH) && git reset --hard origin/$(MAIN_BRANCH)'
	
	@echo ">>> 同步完成！主仓库与所有子模块均已回到 $(MAIN_BRANCH) 并对齐远端。"
	@git status