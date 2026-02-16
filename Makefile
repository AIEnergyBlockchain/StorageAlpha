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
CODEX_SKILLS_DIR ?= $(HOME)/.codex/skills
SKILL_CREATOR_SCRIPT ?= $(CODEX_SKILLS_DIR)/.system/skill-creator/scripts/init_skill.py
SKILL_VALIDATE_SCRIPT ?= $(CODEX_SKILLS_DIR)/.system/skill-creator/scripts/quick_validate.py
SKILL_NAME ?= programming-insights-publisher
SKILL_LOCAL_DIR ?= skills/$(SKILL_NAME)
SKILL_CODEX_DIR ?= $(CODEX_SKILLS_DIR)/$(SKILL_NAME)
SKILL_PROMPTS_REL ?= references/prompt-library.md
CODEX_BIN ?=
INSIGHT_OUT_DIR ?= guide/docs/insights
DAILY_OUT ?= $(INSIGHT_OUT_DIR)/daily-$(shell date +%F).md
WEEKLY_OUT ?= $(INSIGHT_OUT_DIR)/weekly-$(shell date +%G-W%V).md

.PHONY: help up newup ship sup \
	skill-help skill-new skill-sync skill-validate skill-validate-codex \
	prompt-daily prompt-weekly prompt-monthly \
	daily-note weekly-post monthly-review \
	today-insight weekly-insight

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
	@cd $(SUB_PATH) && git add -A && git commit -m "[Submodule] $(msg)" && git push
	@echo ">>> 正在同步主仓库..."
	@$(MAKE) up msg="chore: sync submodule - $(msg)"

# 5. Skill 命令说明
skill-help:
	@echo "--- Skill 配置 ---"
	@echo "CODEX_SKILLS_DIR = $(CODEX_SKILLS_DIR)"
	@echo "SKILL_NAME       = $(SKILL_NAME)"
	@echo "SKILL_LOCAL_DIR  = $(SKILL_LOCAL_DIR)"
	@echo "SKILL_CODEX_DIR  = $(SKILL_CODEX_DIR)"
	@echo "CODEX_BIN        = $(CODEX_BIN)"
	@echo ""
	@echo "--- Skill 命令 ---"
	@echo "make skill-new skill=foo resources=references,scripts"
	@echo "make skill-sync           # 使用默认 SKILL_NAME"
	@echo "make skill-validate       # 使用默认 SKILL_NAME"
	@echo "make skill-validate-codex # 使用默认 SKILL_NAME"
	@echo "make prompt-daily         # 使用默认 SKILL_NAME"
	@echo "make prompt-weekly        # 使用默认 SKILL_NAME"
	@echo "make prompt-monthly       # 使用默认 SKILL_NAME"
	@echo "make daily-note           # 使用默认 SKILL_NAME"
	@echo "make weekly-post          # 使用默认 SKILL_NAME"
	@echo "make today-insight        # 使用默认 SKILL_NAME"
	@echo "make weekly-insight       # 使用默认 SKILL_NAME"
	@echo "(可覆盖) make weekly-insight SKILL_NAME=foo"

# 6. 新建 Skill（默认写入 ~/.codex/skills）
skill-new:
	@if [ -z "$(skill)" ]; then echo "Error: 请指定 skill=skill-name"; exit 1; fi
	@RES="$(resources)"; \
	if [ -z "$$RES" ]; then RES="references"; fi; \
	python3 "$(SKILL_CREATOR_SCRIPT)" "$(skill)" --path "$(CODEX_SKILLS_DIR)" --resources "$$RES"

# 7. 同步本地 Skill 到 ~/.codex/skills
skill-sync:
	@if [ ! -d "$(SKILL_LOCAL_DIR)" ]; then echo "Error: 未找到本地 skill 目录: $(SKILL_LOCAL_DIR)"; exit 1; fi
	@mkdir -p "$(SKILL_CODEX_DIR)"
	@cp -R "$(SKILL_LOCAL_DIR)/." "$(SKILL_CODEX_DIR)/"
	@echo "已同步到: $(SKILL_CODEX_DIR)"

# 8. 校验本地 Skill
skill-validate:
	@if [ ! -d "$(SKILL_LOCAL_DIR)" ]; then echo "Error: 未找到本地 skill 目录: $(SKILL_LOCAL_DIR)"; exit 1; fi
	@python3 "$(SKILL_VALIDATE_SCRIPT)" "$(SKILL_LOCAL_DIR)"

# 9. 校验 Codex Skill
skill-validate-codex:
	@if [ ! -d "$(SKILL_CODEX_DIR)" ]; then echo "Error: 未找到 codex skill 目录: $(SKILL_CODEX_DIR)"; exit 1; fi
	@python3 "$(SKILL_VALIDATE_SCRIPT)" "$(SKILL_CODEX_DIR)"

# 10. 一键输出每日提示词
prompt-daily:
	@FILE="$(SKILL_CODEX_DIR)/$(SKILL_PROMPTS_REL)"; \
	if [ ! -f "$$FILE" ]; then FILE="$(SKILL_LOCAL_DIR)/$(SKILL_PROMPTS_REL)"; fi; \
	if [ ! -f "$$FILE" ]; then echo "Error: 未找到提示词文件"; exit 1; fi; \
	awk 'BEGIN{flag=0} /^## Daily Prompt/{flag=1; next} /^## Weekly Prompt/{flag=0} flag{print}' "$$FILE"

# 11. 一键输出每周提示词
prompt-weekly:
	@FILE="$(SKILL_CODEX_DIR)/$(SKILL_PROMPTS_REL)"; \
	if [ ! -f "$$FILE" ]; then FILE="$(SKILL_LOCAL_DIR)/$(SKILL_PROMPTS_REL)"; fi; \
	if [ ! -f "$$FILE" ]; then echo "Error: 未找到提示词文件"; exit 1; fi; \
	awk 'BEGIN{flag=0} /^## Weekly Prompt/{flag=1; next} /^## Monthly Review Prompt/{flag=0} flag{print}' "$$FILE"

# 12. 一键输出每月复盘提示词
prompt-monthly:
	@FILE="$(SKILL_CODEX_DIR)/$(SKILL_PROMPTS_REL)"; \
	if [ ! -f "$$FILE" ]; then FILE="$(SKILL_LOCAL_DIR)/$(SKILL_PROMPTS_REL)"; fi; \
	if [ ! -f "$$FILE" ]; then echo "Error: 未找到提示词文件"; exit 1; fi; \
	awk 'BEGIN{flag=0} /^## Monthly Review Prompt/{flag=1; next} flag{print}' "$$FILE"

# 13. 别名：每日笔记提示词
daily-note: prompt-daily

# 14. 别名：每周成文提示词
weekly-post: prompt-weekly

# 15. 别名：每月复盘提示词
monthly-review: prompt-monthly

# 16. 一键调用 skill 生成今日心得（Markdown）
today-insight:
	@set -e; \
	mkdir -p "$(INSIGHT_OUT_DIR)"; \
	CODEX_CLI="$(CODEX_BIN)"; \
	if [ -z "$$CODEX_CLI" ]; then CODEX_CLI=$$(command -v codex 2>/dev/null || true); fi; \
	if [ -z "$$CODEX_CLI" ]; then CODEX_CLI=$$(find "$(HOME)/.vscode-server/extensions" -maxdepth 4 -type f -path "*/bin/linux-x86_64/codex" 2>/dev/null | sort -r | head -n 1); fi; \
	if [ -z "$$CODEX_CLI" ]; then echo "Error: 未找到 codex CLI，请先安装或设置 CODEX_BIN=/path/to/codex"; exit 1; fi; \
	if [ ! -x "$$CODEX_CLI" ]; then echo "Error: codex CLI 不可执行: $$CODEX_CLI"; exit 1; fi; \
	PROMPT_FILE="$(SKILL_CODEX_DIR)/$(SKILL_PROMPTS_REL)"; \
	if [ ! -f "$$PROMPT_FILE" ]; then PROMPT_FILE="$(SKILL_LOCAL_DIR)/$(SKILL_PROMPTS_REL)"; fi; \
	if [ ! -f "$$PROMPT_FILE" ]; then echo "Error: 未找到提示词文件"; exit 1; fi; \
	TMP_PROMPT=$$(mktemp); \
	trap 'rm -f "$$TMP_PROMPT"' EXIT; \
	{ \
		echo 'Use $$$(SKILL_NAME) to generate my today programming insight in bilingual format.'; \
		echo 'Output must be publish-ready markdown, image-friendly and code-breakdown oriented.'; \
		echo ''; \
		awk 'BEGIN{flag=0} /^## Daily Prompt/{flag=1; next} /^## Weekly Prompt/{flag=0} flag{print}' "$$PROMPT_FILE"; \
		echo ''; \
		echo '附加输出：'; \
		echo '1) 中英标题各1个'; \
		echo '2) 可直接发布的主文（Markdown）'; \
		echo '3) LinkedIn 精简版（200-300词）'; \
		echo '4) 3条 X 导流短帖'; \
	} > "$$TMP_PROMPT"; \
	"$$CODEX_CLI" exec --full-auto --cd "$(CURDIR)" --output-last-message "$(DAILY_OUT)" - < "$$TMP_PROMPT"; \
	echo "已生成: $(DAILY_OUT)"

# 17. 一键调用 skill 生成本周心得（Markdown）
weekly-insight:
	@set -e; \
	mkdir -p "$(INSIGHT_OUT_DIR)"; \
	CODEX_CLI="$(CODEX_BIN)"; \
	if [ -z "$$CODEX_CLI" ]; then CODEX_CLI=$$(command -v codex 2>/dev/null || true); fi; \
	if [ -z "$$CODEX_CLI" ]; then CODEX_CLI=$$(find "$(HOME)/.vscode-server/extensions" -maxdepth 4 -type f -path "*/bin/linux-x86_64/codex" 2>/dev/null | sort -r | head -n 1); fi; \
	if [ -z "$$CODEX_CLI" ]; then echo "Error: 未找到 codex CLI，请先安装或设置 CODEX_BIN=/path/to/codex"; exit 1; fi; \
	if [ ! -x "$$CODEX_CLI" ]; then echo "Error: codex CLI 不可执行: $$CODEX_CLI"; exit 1; fi; \
	PROMPT_FILE="$(SKILL_CODEX_DIR)/$(SKILL_PROMPTS_REL)"; \
	if [ ! -f "$$PROMPT_FILE" ]; then PROMPT_FILE="$(SKILL_LOCAL_DIR)/$(SKILL_PROMPTS_REL)"; fi; \
	if [ ! -f "$$PROMPT_FILE" ]; then echo "Error: 未找到提示词文件"; exit 1; fi; \
	TMP_PROMPT=$$(mktemp); \
	trap 'rm -f "$$TMP_PROMPT"' EXIT; \
	{ \
		echo 'Use $$$(SKILL_NAME) to generate my weekly programming insight package in bilingual format.'; \
		echo 'Output must be publish-ready markdown with a clear GitHub->LinkedIn->Medium->X flow.'; \
		echo ''; \
		awk 'BEGIN{flag=0} /^## Weekly Prompt/{flag=1; next} /^## Monthly Review Prompt/{flag=0} flag{print}' "$$PROMPT_FILE"; \
		echo ''; \
		echo '附加输出：'; \
		echo '1) 本周主选题与理由'; \
		echo '2) GitHub 完整版（中英双语）'; \
		echo '3) LinkedIn Newsletter 精简版'; \
		echo '4) Medium 叙事版提纲'; \
		echo '5) 3条 X 导流短帖'; \
	} > "$$TMP_PROMPT"; \
	"$$CODEX_CLI" exec --full-auto --cd "$(CURDIR)" --output-last-message "$(WEEKLY_OUT)" - < "$$TMP_PROMPT"; \
	echo "已生成: $(WEEKLY_OUT)"
