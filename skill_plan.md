# 8-Skill 批量生成与路由治理实施方案（决策完成版）

## 摘要

- 使用顺序：先按 `skill-builder-guide` 定义触发边界与交付质量，再按 `skill-creator` 的脚手架与校验流程落地。
- 目标：在 `~/.codex/skills` 生成并集成 8 个生产级 skill，含路由治理、双模式角色能力（Mode A/Mode B）、每日推荐机制与可审计更新流程。
- 已锁定决策：

1. 输出位置：`~/.codex/skills`
2. 交付深度：全部生产级
3. 语言：英文为主，必要时少量中文注释
4. 角色组织：每个角色单 skill 内置双模式
5. 测试与运维：分为两个 skill（保持总数 8）
6. 推荐策略：14 天窗口、频次 >=5、每日批处理
7. 路由更新：先建议后更新（人工确认）
8. 法律辖区：CN + US + EU + SG
9. 创业导师：圆桌会议模式，多角色交互后给统一结论
10. `personal-profile` 仅保留用户画像上下文，不承担路由管理职责

## 新增 Skill 清单（固定 ID）

1. `skill-management-orchestrator`
2. `product-manager`
3. `algorithm-engineer`
4. `test-engineer`
5. `devops-engineer`
6. `ui-ux-designer`
7. `energy-web3-legal-advisor`
8. `startup-cognition-mentor`

## 公共接口与类型变更

### 1) Skill 管理输入事件流（新增）

### 2) 路由注册表（新增）

### 3) 推荐输出报告（新增）

### 4) 现有路由接口（修改）

- 修改 `~/.codex/skills/skill-management-orchestrator/references/skill-router.md`
- 修改 `~/.codex/skills/skill-management-orchestrator/references/skill-relationship-map.md`
- `personal-profile` 仅保留用户画像上下文，不再提供路由管理入口
- 新增 8 个 skill 的路由项与依赖关系，不替换已有 skill id。

## 每个 Skill 的文件结构（统一）

- `~/.codex/skills/<skill-id>/SKILL.md`
- `~/.codex/skills/<skill-id>/agents/openai.yaml`
- `~/.codex/skills/<skill-id>/references/mode-a.md`
- `~/.codex/skills/<skill-id>/references/mode-b.md`
- `~/.codex/skills/<skill-id>/references/trigger-boundaries.md`
- 仅 `skill-management-orchestrator` 额外包含：
  `/scripts/analyze_intents.py`, `/scripts/propose_router_changes.py`, `/scripts/render_recommendation_report.py`, `/data/`, `/reports/`

## 角色 Skill 的双模式定义（固定）

1. `product-manager`

- Mode A：虚拟电厂/分布式能源金融
- Mode B：SaaS 订阅模型/用户增长

2. `algorithm-engineer`

- Mode A：光储调度优化/负荷预测
- Mode B：通用 AI Agent/量化分析

3. `test-engineer`

- Mode A：智能合约审计/硬件联动测试
- Mode B：通用测试策略、自动化测试体系、质量门禁

4. `devops-engineer`

- Mode A：链上系统与硬件联动运维可靠性
- Mode B：云原生 SRE/自动化 CI/CD

5. `ui-ux-designer`

- Mode A：能源资产看板与运营视图
- Mode B：科技与艺术结合风格体系

6. `energy-web3-legal-advisor`

- Mode A：Web3 能源合规/国籍法律（CN+US+EU+SG）
- Mode B：跨国税务/版权法框架

7. `startup-cognition-mentor`

- 模式形式：圆桌会议模式
- 固定流程：多认知角色交叉辩论 -> 冲突点收敛 -> 统一可执行结论
- 角色镜像来源：Musk/Munger/Jobs/Buffett/Vitalik/CZ/Justin Sun 的公开方法论，不做身份模仿。

## 模式选择协议（所有角色 skill 统一）

1. 用户显式传 `mode:a` 或 `mode:b` 时强制使用对应模式。
2. 未显式指定时按关键词判定，然后询问用户。
3. 同时命中 A/B 关键词时，询问用户。
4. 判定不清时先问 1 个澄清问题后再执行。

## 实施步骤（执行顺序）

1. 用 `init_skill.py` 在 `~/.codex/skills` 脚手架创建 8 个 skill（含 `agents/openai.yaml`）。
2. 填写 8 个 `SKILL.md`：统一包含 Scope、Execution Workflow、Output Contract、Trigger Boundaries、Quality Checklist。
3. 为 7 个角色 skill 写 `mode-a.md` 与 `mode-b.md` 详细规则和例子。
4. 为 `skill-management-orchestrator` 实现 3 个脚本与 3 份参考文档（schema、registry、ops-runbook）。
5. 更新 `skill-management-orchestrator` 的路由表与关系图，加入 8 个 skill 的关键词和依赖，并将 `personal-profile` 收敛为仅用户画像职责。
6. 对 8 个 skill 分别跑 `quick_validate.py`，全部通过后完成交付。

## 测试与验收场景

1. 结构验收：8 个 skill 均存在 `SKILL.md` 与 `agents/openai.yaml`。
2. 语法验收：8 个目录执行 `quick_validate.py` 全通过。
3. 路由验收：`skill-router.md` 能把新增 8 类意图正确路由到主 skill。
4. 模式验收：每个角色 skill 至少 4 条测试请求，覆盖 `mode:a`、`mode:b`、自动判定、歧义澄清。
5. 管理验收：向 `intent-events.jsonl` 注入样例后，可生成推荐报告和路由候选变更。
6. 安全验收：

- 法律 skill 输出必须包含“非正式法律意见、需本地持牌律师复核”的边界提示。
- 创业导师输出必须是“多视角策略讨论 + 结论”，不做人物扮演口吻复制。

## 关键边界与失败模式

1. 数据不足：14 天内总样本不足 20 条时，仅出观察报告，不给新增 skill 建议。
2. 意图冲突：同一请求命中多个 role skill 时，先问澄清问题。
3. 法规冲突：遇到跨辖区冲突时输出差异对比，不给单点确定性法律结论。
4. 路由写入失败：保留建议报告，禁止部分写回，避免路由表半更新状态。

## 假设与默认值

1. 技术环境允许在 `~/.codex/skills` 创建和修改目录文件。
2. 推荐分析输入由外部流程持续写入 `intent-events.jsonl`。
3. Skill 内容主语言为英文，中文仅作少量注释补充。
4. 不引入额外第三方服务，推荐逻辑基于本地文件与脚本。
5. 保持现有 skill 兼容，不重命名已上线 skill。
