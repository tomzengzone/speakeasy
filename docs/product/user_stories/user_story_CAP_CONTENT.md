## 5. 内容资产（CAP-CONTENT / content-curriculum-scenario）

### US-CONTENT-001 - 学习者按场景主题浏览内容资产

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-001` | 作为学习者，当我进入内容资产入口时，我希望看到所有已发布的官方场景主题列表，点击某个场景主题后能看到该主题下当前已发布课程卡片（含英文课程标题、中文简介、等级），以便判断哪个场景和课程适合我开始学习。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-001-1` | 学习者进入内容资产入口，系统展示所有已发布的官方场景主题列表，每个场景主题包含场景主题标识（场景主题背景卡片/名称/简介），使学习者能一眼了解大致内容方向；成功时展示所有已发布的官方场景主题卡片；无内容时展示空状态；加载失败时展示加载失败提示。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-001-2` | 学习者点击某个场景主题后，系统展示该主题下当前已发布课程卡片列表；每张课程卡片以其课程标题区背景图为卡片背景，展示三条信息：英文课程标题、中文简介、等级（A1/A2/B1/B2/C1/C2）；成功时学习者能浏览该主题下当前已发布课程。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-001-3` | 学习者从课程卡片点击某课程后，系统成功导航到该课程的详情页；成功时进入课程详情；加载失败时展示重试入口。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

### US-CONTENT-002 - 学习者查看课程详情标题区

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-002` | 作为学习者，当我进入一个课程详情页时，我希望在页面顶部看到以课程场景图片为背景的标题区，包含英文课程标题、中文简介、等级和预计学习时间，以便快速了解这门课程的基本信息和投入成本。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-002-1` | 学习者进入课程详情页后，顶部标题区以课程场景图片为背景展示；图片加载失败时展示默认占位背景，不影响其他信息可见。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN` |
| `VS-CONTENT-002-2` | 标题区展示英文课程标题和中文简介；成功时学习者能明确知道英文课程名称和中文简介；字段缺失时展示保守占位文案。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN` |
| `VS-CONTENT-002-3` | 标题区展示课程等级（A1/A2/B1/B2/C1/C2）；成功时学习者能看到课程等级标签；等级数据不可用时不展示等级标签而非显示错误值。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN` |
| `VS-CONTENT-002-4` | 标题区展示预计学习时间；成功时学习者能看到预计学习时间；时间数据不可用时不展示该字段而非显示错误值。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN` |

### US-CONTENT-003 - 学习者查看课程学习路线与阶段状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-003` | 作为学习者，当我进入课程详情页后，我希望在标题区下方看到该课程的完整学习路线（任务挑战 → 课程精讲 → 专项训练 → 自由口语练习 → 学习报告），每个阶段显示当前状态，以便了解学习进度和下一步该做什么。 | `draft` | `CAP-CONTENT` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-003-1` | 学习者进入课程详情页后，标题区下方展示学习路线，包含5个阶段且顺序固定：01 任务挑战、02 课程精讲、03 专项训练、04 自由口语练习、05 学习报告；成功时学习者能看到完整路线结构。 | `draft` | `CAP-CONTENT` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-003-2` | 每个学习阶段展示其当前状态，状态值为以下三者之一：尚未开始、进行中、已完成；成功时学习者能区分各阶段进度。 | `draft` | `CAP-CONTENT` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-003-3` | 学习者点击任意学习阶段（01 任务挑战、02 课程精讲、03 专项训练、04 自由口语练习、05 学习报告）后，系统导航到该阶段的对应内容页；成功时进入对应学习内容；阶段内容不可用时展示原因提示。 | `draft` | `CAP-CONTENT` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-003-4` | 学习路线的阶段状态来源于外部学习进度（`CAP-MEMORY` / `CAP-TRAIN`），内容资产本身不维护进度状态；当进度服务不可用时，不显示任何阶段的进度状态，并展示“进度暂不可用”提示，不将未知状态表示为“尚未开始”。 | `draft` | `CAP-CONTENT` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
