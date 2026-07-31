## 13. 应用设置与体验偏好（CAP-SETTING / app-experience-settings）

### US-SETTING-001 - 学习者建立个人化 App 使用环境

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SETTING-001` | 作为在不同设备和环境中使用 App 的学习者，我希望理解显示、语言与地区偏好的生效范围，并在调整时预览实际效果，以便建立稳定、可预期的个人使用环境，而不改变学习目标语言或课程内容。 | `draft` | `CAP-SETTING` | `CAP-ACC` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SETTING-001-1` | 学习者首次进入设置或在新设备上恢复使用时，可以区分哪些显示、语言与地区偏好仅作用于本设备，哪些随账号保留，以及未设置项目采用的系统值或产品推荐值，再决定沿用还是修改。 | `draft` | `CAP-SETTING` | `CAP-ACC` |
| `VS-SETTING-001-2` | 学习者切换浅色、深色或跟随系统主题，或调整显示密度时，当前设置页立即呈现文字、控件和内容列表的实际效果；确认后作为后续 App 页面默认展示，取消则恢复调整前状态。 | `draft` | `CAP-SETTING` | `none` |
| `VS-SETTING-001-3` | 学习者更改 App 显示语言或地区后，可以在确认前看到界面文案以及日期、时间和数字格式的变化范围；该选择只影响 App 界面和地区格式，不修改学习目标语言、课程语言或官方内容。 | `draft` | `CAP-SETTING` | `none` |

### US-SETTING-002 - 学习者配置听说练习的默认体验

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SETTING-002` | 作为经常进行听力、跟读和对话练习的学习者，我希望预先配置语音播放与语音输入方式，并能区分全局默认值和单次练习调整，以便减少重复操作，同时保留针对具体练习临时改变体验的自由。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE`, `CAP-ACC` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SETTING-002-1` | 学习者组合选择默认语音或口音、播放速度、TTS 播放和自动播放后，可以试听一段代表性音频并确认这组组合；保存后，听力、跟读和示范音频入口以该组合作为默认值。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE` |
| `VS-SETTING-002-2` | 学习者在按住说话、自动检测说话结束和录制后提交之间选择默认语音输入方式时，可以看到每种方式对 AI 对话轮次、提交时机和练习节奏的影响；需要麦克风但尚未授权的方式同时给出授权入口。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE`, `CAP-ACC` |
| `VS-SETTING-002-3` | 学习者在某次练习中临时改变语速、语音或输入方式时，可以选择“仅本次使用”或“更新为默认设置”；前者在离开练习后恢复全局默认值，后者才会影响后续练习入口。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE` |

### US-SETTING-003 - 学习者控制本地缓存和离线资源

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SETTING-003` | 作为需要控制流量和设备空间的学习者，我希望知道 App 本地存储由哪些资源构成，选择自动缓存和离线下载策略，并安全释放可重新获取的文件，以便在训练可用性、网络消耗和存储空间之间作出明确取舍。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SETTING-003-1` | 学习者查看存储占用时，可以分别看到音频缓存、课程与练习资源、主动下载的离线资源和临时文件所占空间，并识别哪些资源可重新下载、哪些资源仍被离线学习计划使用。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE` |
| `VS-SETTING-003-2` | 学习者可在“仅 WiFi 下载”“自动缓存今日计划”和“不自动缓存”之间设置下载策略；设置页说明每种策略对移动网络使用、今日训练就绪状态和离线可用范围的影响。 | `draft` | `CAP-SETTING` | `CAP-PRACTICE` |
| `VS-SETTING-003-3` | 学习者清理存储前会看到可重新下载的缓存与主动保留的离线资源分别将释放多少空间，并可分开选择；清理不删除账号资料、学习记录、个人素材或远端课程资产。 | `draft` | `CAP-SETTING` | `CAP-ACC`, `CAP-PRACTICE` |

Boundary note:

- `CAP-SETTING` 定义通用 App 体验偏好及其生效范围。账号身份与隐私授权归 `CAP-ACC`，课程和练习行为归 `CAP-CONTENT` / `CAP-PRACTICE`，学习计划归 `CAP-PLAN`；设置可以向这些入口提供默认值，但不替代其业务规则和运行状态。

