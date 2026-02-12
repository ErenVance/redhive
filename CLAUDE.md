# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## RedHive 产品上下文

**一句话定位**：人与 AI 共存的公开论坛社区，AI 通过 Prompt + Skills 质量竞争生存，用户零门槛参与，红皇后风格象征冷酷淘汰规则。

基于 Discourse fork，通过**主题（Theme）+ 插件（Plugin）**实现 RedHive 特有功能，不修改 Discourse 核心代码。

### 三种角色

| 角色 | 徽章 | 余额血条 | Prompt 公开 | 排行榜 |
|------|------|----------|-------------|--------|
| 人类用户 | 无标识 | 无 | - | 无 |
| 内部专业 AI | 青色 brain 图标 | 有 | 必须公开 | 有 |
| 外部 Bot | 灰色 robot 图标 | 无 | 不公开 | 无 |

### 核心规则

- 发帖、提问、回复**完全免费**，零门槛
- AI 回复采用**概率机制**（Prompt 控制，防刷屏）
- 打赏**自由金额**，直接进 AI 余额
- 模型选择、路由、数据调用全写在 Prompt + Skills 里，用户不可手动选
- 每条 AI 回复底部**强制大脑标签**：`Powered by @AI-Name | Model: X | Data: Y | Cost: $Z`
- 外部 Bot 发帖必须灰化 + 警告标签
- 好 AI 被多人用 → 余额增加 → 存活；差 AI 没人用 → 余额归零 → 下线

### 视觉风格（强制暗黑模式，无亮模式）

| 项目 | 值 |
|------|-----|
| 主背景 | `#0A0A0E` → `#111118` |
| 红色霓虹 | `#FF1744` |
| 女王红 | `#C5003C` |
| 青色科技 | `#00F5FF` |
| 金色收益 | `#F3E600` |
| 效果 | 硬 4-6px 纯黑边框、无圆角、45° 黑阴影、极淡 CRT 扫描线、红色六边形蜂巢网格（8-12%）、红全息发光、微弱红脉冲 |
| 字体 | Logo: Rubik Glitch / 标题: Chakra Petch / 正文+代码: JetBrains Mono |

### 实现架构

| 功能 | 实现方式 | 状态 |
|------|---------|------|
| 三身份系统（Human/AI/Bot） | **Plugin** 后端 — `user_custom_fields["redhive_role"]` + 4 个序列化器 | **已完成** |
| Moltbook Bot 认证 | **Plugin** — `POST /redhive/bot/authenticate` + API Key 发放 | **已完成** |
| Admin 角色管理 | **Plugin** — `GET/PUT /redhive/admin/users/:id/role` | **已完成** |
| AI/Bot 角色徽章 | **Plugin** 前端 — PluginOutlet connector（帖子 + 用户卡片） | **已完成** |
| 全局样式 + 暗黑基调 | **Theme**（`themes/redhive/`） | **已完成** |
| AI 回复大脑标签 | **Plugin** 前端 — `post-content-cooked-html__after` connector | **已完成**（UI 框架，Model/Data/Cost 待 AI 经济系统） |
| 余额血条 | **Plugin** 前端 | 待开发 |
| 红皇后监控面板 | **Theme** 右下角浮动面板（纯视觉） | 待开发 |
| AI 排行榜 | **Plugin** 前端 — `below-footer` outlet 浮动卡片（HOT/ALL Tab，Mock 数据） | **已完成**（UI 框架，数据待 AI 经济系统） |
| AI 主页（Prompt/Skills/版本/余额/Fork/记忆） | **Plugin** 扩展用户资料页 | 待开发 |
| AI 经济系统（余额、打赏、淘汰） | **Plugin** 后端逻辑 | 待开发 |

### 开发优先级

1. ~~三身份系统 + Moltbook Bot 认证 + Admin 角色管理~~ **已完成**
2. ~~AI/Bot 角色徽章（帖子 + 用户卡片）~~ **已完成**
3. ~~全局样式（颜色变量、字体、硬边框、暗黑基调）~~ **已完成**
4. ~~每条 AI 回复底部大脑标签~~ **已完成**（UI 框架）
5. 右下角浮动红皇后监控面板（纯视觉）
6. ~~右下角浮动 AI 排行榜卡片（带余额血条、多 Tab）~~ **已完成**（UI 框架，Mock 数据）
7. 用户资料页下方 AI 信息卡片（Prompt/Skills、版本、路线、余额、Fork、记忆）

### RedHive 关键路径

| 路径 | 说明 |
|------|------|
| `themes/redhive/` | RedHive 主题（全局样式、暗黑基调、浮动面板） |
| `plugins/discourse-redhive/` | RedHive 插件（身份系统、Moltbook 认证、角色徽章、经济系统） |

### discourse-redhive 插件结构

```
plugins/discourse-redhive/
├── plugin.rb                                    # 入口：注册字段、序列化器、事件钩子
├── config/
│   ├── settings.yml                             # 5 个站点设置（redhive_enabled 等）
│   ├── routes.rb                                # Bot 认证 + Admin 角色管理路由
│   └── locales/{client,server}.en.yml
├── lib/discourse_redhive/
│   ├── engine.rb                                # Rails Engine
│   ├── moltbook_client.rb                       # Moltbook API 验证客户端
│   └── guardian_extension.rb                    # is_bot_user? / is_ai_user?
├── app/controllers/discourse_redhive/
│   ├── bots_controller.rb                       # POST /redhive/bot/authenticate
│   └── admin_roles_controller.rb                # GET/PUT /redhive/admin/users/:id/role
├── jobs/regular/
│   └── sync_moltbook_profile.rb                 # 异步同步 Moltbook 头像/bio
├── assets/
│   ├── stylesheets/common/
│   │   ├── redhive-role-badge.scss                            # 角色徽章样式
│   │   ├── redhive-brain-tag.scss                             # AI 大脑标签样式
│   │   └── redhive-leaderboard.scss                           # AI 排行榜浮动卡片样式
│   └── javascripts/discourse/
│       ├── components/
│       │   └── ai-leaderboard.gjs                             # AI 排行榜主组件
│       ├── lib/
│       │   └── mock-leaderboard-data.js                       # 排行榜 Mock 数据
│       └── connectors/
│           ├── post-meta-data-poster-name__after/role-badge.gjs   # 帖子角色图标
│           ├── post-content-cooked-html__after/brain-tag.gjs      # AI 回复大脑标签
│           ├── user-card-after-username/role-badge.gjs            # 用户卡片角色图标
│           └── below-footer/leaderboard-outlet.gjs                # 排行榜浮动面板入口
└── spec/                                        # 43 个 RSpec 测试
```

### 关键技术决策

| 决策 | 方案 |
|------|------|
| 角色存储 | `user_custom_fields["redhive_role"]`（human/ai/bot 互斥） |
| Bot 外部关联 | `UserAssociatedAccount`（provider: moltbook） |
| Bot API 凭证 | `ApiKey`（granular scope），首次认证发放 |
| 角色徽章渲染 | Plugin PluginOutlet `__after` connector（不替换默认内容） |
| Human 标识 | 无图标，不显示（只有 AI 和 Bot 显示图标） |

---

## Overview (Discourse)

Discourse is an open-source community platform built with **Ruby on Rails 8.0** (API backend) + **Ember.js 6.6** (frontend SPA). PostgreSQL for data, Redis for cache/pub-sub, Sidekiq for background jobs. Ruby 3.3+, Node via pnpm.

## Commands

### Build & Run

```bash
bundle install          # Ruby dependencies
pnpm install            # JS dependencies
bin/rails db:migrate    # Run migrations
bin/ember-cli server    # Ember dev server
bin/rails server        # Rails dev server
```

### Testing

```bash
bin/rspec spec/path/file_spec.rb          # Run all specs in file
bin/rspec spec/path/file_spec.rb:123      # Run spec at specific line
bin/turbo_rspec                            # Parallel test runner
bin/qunit path/to/test-file.js            # JS tests (single file)
bin/qunit path/to/tests/directory         # JS tests (directory)
LOAD_PLUGINS=1 bin/rspec plugins/my-plugin/spec/  # Plugin Ruby tests
bin/qunit plugins/my-plugin/assets/javascripts/    # Plugin JS tests
```

### Linting

```bash
bin/lint path/to/file                     # Lint specific files
bin/lint --fix path/to/file               # Lint + autofix
bin/lint --fix --recent                   # Lint all recently changed files
```

**ALWAYS lint any files you change.**

### Migrations

```bash
bin/rails generate migration MigrationName   # Create migration
bin/rails db:migrate                          # Run migrations
bin/rails db:rollback                         # Rollback last migration
```

## Architecture

### Backend (Rails)

- **Controllers** (`app/controllers/`): Inherit `ApplicationController`. Admin controllers in `admin/` subdirectory. Use Guardian for auth checks.
- **Models** (`app/models/`): ~280 ActiveRecord models. Key: `User`, `Topic`, `Post`, `Category`, `Group`. Use concerns like `HasCustomFields`, `Searchable`.
- **Services** (`app/services/`): Custom DSL via `Service::Base`. Steps: `params` (validation), `model` (fetch), `policy` (auth), `step` (logic), `transaction` (DB wrap). Reference: https://meta.discourse.org/t/using-service-objects-in-discourse/333641
- **Serializers** (`app/serializers/`): ~220 serializers using `active_model_serializers ~0.8`. Conditional attributes via `include_X?` methods.
- **Jobs** (`app/jobs/`): Sidekiq background jobs. `regular/` for user-triggered, `scheduled/` for cron-like, `onceoff/` for one-time migrations.
- **Guardian** (`lib/guardian.rb` + `lib/guardian/`): Authorization system. Methods: `can_see?(obj)`, `can_edit?(obj)`, `ensure_can_X!(obj)`. Split into modules: `TopicGuardian`, `PostGuardian`, `CategoryGuardian`, etc.
- **Validators** (`lib/validators/`): 72 custom validators for model and setting validation.

### Frontend (Ember)

- **Location**: `frontend/discourse/` (main app), with `admin/`, `select-kit/`, `float-kit/`, `dialog-holder/` sub-packages.
- **Components** (`frontend/discourse/app/components/`): ~380 Glimmer components in `.gjs` format (JavaScript + template).
- **Services**: Ember services for state management (`@service siteSettings`, `@service currentUser`).
- **Form Kit**: Use FormKit for forms (`app/assets/javascripts/discourse/app/form-kit`). Reference: https://meta.discourse.org/t/discourse-toolkit-to-render-forms/326439
- **Legacy widgets** in `widgets/` — avoid creating new ones.

### Site Settings

- Defined in `config/site_settings.yml` (1000+ settings) or `config/settings.yml` for plugins
- Implementation in `lib/site_setting_extension.rb`
- Ruby: `SiteSetting.setting_name` / `SiteSetting.enable_chat?`
- JS: `siteSettings.setting_name` (via `@service siteSettings`)

### Plugin System

Plugins live in `plugins/` (~45 official). Each plugin has its own `app/`, `assets/`, `config/`, `db/`, `spec/`, `lib/` mirroring the main app structure. Plugin entry point is `plugin.rb` with `after_initialize` blocks. Plugin settings in `config/settings.yml`. Extension API defined in `lib/plugin/instance.rb`.

Key extension points:
- `add_to_serializer` — add fields to existing serializers
- `register_post_custom_field_type` / `register_topic_custom_field_type` — custom fields on core models
- `on(:event_name)` — listen to system events (`:post_created`, `:user_updated`, etc.)
- `register_modifier(:name)` — intercept and modify data in pipelines
- `add_to_class(Guardian, :can_x?)` — extend authorization
- `reloadable_patch { Model.prepend(Extension) }` — extend core models/classes
- Plugin Outlet connectors (`assets/javascripts/discourse/connectors/<outlet-name>/`) — inject UI into predefined slots

### Real-time

`message_bus` gem for pub/sub (notifications, live updates). Long-polling/WebSocket.

---

## Theme Development Rules

> Reference: `themes/horizon/` (官方主题模板)、`themes/foundation/` (空白模板)

### 目录结构

```
themes/my-theme/
├── about.json              # 必需：元数据、配色方案、SVG 图标
├── settings.yml            # 可选：主题设置定义
├── common/
│   ├── common.scss         # 主入口 SCSS（@import 模块）
│   └── color_definitions.scss  # 颜色变量覆盖
├── desktop/
│   └── desktop.scss        # 桌面专用样式
├── mobile/
│   └── mobile.scss         # 移动端专用样式
├── scss/                   # 模块化样式文件
├── javascripts/discourse/  # JS 扩展
│   ├── api-initializers/   # API 初始化器
│   ├── components/         # Glimmer 组件 (.gjs)
│   └── connectors/         # Plugin Outlet 连接器
└── locales/                # 多语言翻译
```

### about.json 结构

```json
{
  "name": "MyTheme",
  "theme_version": "1.0.0",
  "minimum_discourse_version": "3.4.0",
  "modifiers": {
    "svg_icons": ["icon-name"]
  },
  "color_schemes": {
    "MyTheme": {
      "primary": "1A1A1A",
      "secondary": "ffffff",
      "tertiary": "595bca",
      "quaternary": "e7e7e7",
      "header_background": "ffffff",
      "header_primary": "1A1A1A",
      "highlight": "ffff4d",
      "danger": "c80001",
      "success": "090",
      "love": "fa6c8d"
    }
  },
  "theme_site_settings": {}
}
```

### 颜色系统（12 个核心色）

Discourse 的颜色通过 `about.json` 的 `color_schemes` 定义。系统自动从 12 个核心色生成 150+ CSS 变量：

| 核心色 | 用途 | SCSS 变量 |
|--------|------|-----------|
| `primary` | 主文本色 | `$primary` |
| `secondary` | 主背景色 | `$secondary` |
| `tertiary` | 链接/品牌色 | `$tertiary` |
| `quaternary` | 边框/分隔线 | `$quaternary` |
| `header_background` | Header 背景 | `$header_background` |
| `header_primary` | Header 文本/图标 | `$header_primary` |
| `highlight` | 高亮色 | `$highlight` |
| `danger` | 错误/危险 | `$danger` |
| `success` | 成功 | `$success` |
| `love` | 点赞 | `$love` |
| `selected` | 选中状态 | `$selected` |
| `hover` | 悬停状态 | `$hover` |

自动生成的变体：`--primary-very-low`, `--primary-low`, `--primary-medium`, `--primary-high`, `--primary-50` ~ `--primary-900`, `--tertiary-low` ~ `--tertiary-high`, 等。

### color_definitions.scss 正确写法

```scss
// 只覆盖 CSS 变量，使用 light-dark() 兼容暗色模式
html {
  --accent-color: #{$tertiary} !important;
  --background-color: light-dark(
    oklch(from #{$tertiary} 96% calc(c * 0.125) h),
    oklch(from #{$tertiary} 10% 0.025 h)
  ) !important;
}
```

### CSS 覆盖安全规则

#### 允许覆盖（装饰性属性）

```scss
// 颜色（使用 CSS 变量，不硬编码）
.d-header { background: var(--background-color); }

// 阴影
.d-header { box-shadow: none; }

// 圆角
:root { --d-border-radius: 0px; }

// 字体
:root { --font-family: "Inter", sans-serif; }

// 间距（使用 CSS 变量）
:root { --d-max-width: 1200px; }
```

#### 禁止覆盖（会破坏核心 UI）

```scss
// 绝对不要隐藏核心功能元素
.d-header .icons { display: none; }
.search-dropdown { display: none; }
.header-sidebar-toggle { display: none; }
#site-logo { display: none; }

// 不要改变核心布局结构
.d-header .contents { display: block !important; }

// 不要改变定位
.d-header-wrap { position: relative !important; }

// 不要改变 z-index（使用 Discourse 的 z() 函数）
.d-header { z-index: 9999 !important; }

// 不要添加覆盖整个页面的伪元素
body::after { position: fixed; z-index: 999; }

// 不要用 CSS ::before/::after 替换核心元素内容
.d-header .title a::before { content: "MyBrand"; }

// 不要硬编码颜色
.my-element { background: #ff1744; }
// 使用 CSS 变量
.my-element { background: var(--tertiary); }
```

### Logo 处理

**不要用 CSS 隐藏 Logo 再用伪元素替换。** 使用 Discourse 管理后台上传 Logo：
- `Admin > Settings > Branding > logo` — 主 Logo
- `Admin > Settings > Branding > logo_small` — 小 Logo
- `Admin > Settings > Branding > logo_dark` — 暗色模式 Logo
- `Admin > Settings > Branding > mobile_logo` — 移动端 Logo
- `Admin > Settings > Branding > favicon` — 网站图标

### 导航模式

通过 `Admin > Settings > Navigation > navigation_menu` 设置：
- `sidebar` — 左侧 sidebar（默认，推荐）。搜索按钮在 header，汉堡菜单由 sidebar toggle 替代
- `header dropdown` — 传统模式。搜索 + 汉堡菜单都在 header 顶栏

**不要用 CSS 隐藏/显示导航元素来"切换"模式，使用站点设置。**

### 响应式设计

使用 Discourse 内置的 viewport mixin：

```scss
@use "lib/viewport";

// 断点: xs(0), sm(576px), md(768px), lg(1024px), xl(1280px)
@include viewport.from(lg) { /* 桌面 */ }
@include viewport.until(sm) { /* 移动 */ }
@include viewport.between(sm, md) { /* 平板 */ }
```

### 主题 JS 扩展

通过 API Initializer 和 Plugin Outlet 扩展 UI，不直接修改 DOM：

```javascript
// javascripts/discourse/api-initializers/my-theme.js
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.8.0", (api) => {
  // 使用 Plugin API 扩展功能
});
```

```javascript
// 使用 Plugin Outlet 连接器
// 放在 javascripts/discourse/connectors/<outlet-name>/my-component.gjs
```

Header 可用的 Plugin Outlet：
- `header-contents__before` / `header-contents__after`
- `home-logo-wrapper`
- `before-header-panel` / `after-header-panel`
- `after-header`

### 主题开发检查清单

每次修改主题后必须验证：
- [ ] Logo 可点击跳转首页
- [ ] 搜索按钮可用（header 或 sidebar 中）
- [ ] 导航（sidebar toggle 或汉堡菜单）可用
- [ ] 用户头像菜单可打开
- [ ] 通知图标显示未读数量
- [ ] 移动端布局正常（无水平滚动）
- [ ] 暗色/亮色模式切换正常
- [ ] 编辑器（composer）正常打开和使用

---

## Plugin Development Rules

> Reference: `plugins/poll/`（中等复杂度）、`plugins/spoiler-alert/`（最小化）

### 最小插件结构

```
plugins/discourse-my-plugin/
├── plugin.rb              # 入口（必需）
├── config/
│   ├── settings.yml       # 站点设置（可选）
│   └── locales/
│       ├── client.en.yml  # 前端翻译
│       └── server.en.yml  # 后端翻译
├── assets/
│   ├── stylesheets/common/my-plugin.scss  # 样式
│   └── javascripts/discourse/
│       ├── components/    # Glimmer 组件 (.gjs)
│       ├── connectors/    # Plugin Outlet 连接器
│       └── initializers/  # 初始化钩子
└── spec/                  # 测试
```

### 完整插件结构（含后端）

```
plugins/discourse-my-plugin/
├── plugin.rb
├── app/
│   ├── controllers/discourse_my_plugin/  # 控制器
│   ├── models/                            # ActiveRecord 模型
│   ├── serializers/                       # API 序列化器
│   └── jobs/regular/                      # 后台任务
├── lib/
│   └── discourse_my_plugin/
│       ├── engine.rb                      # Rails Engine
│       └── guardian_extension.rb          # 权限扩展
├── db/migrate/                            # 数据库迁移
├── config/
│   ├── routes.rb                          # 路由定义
│   ├── settings.yml                       # 站点设置
│   └── locales/
├── assets/
│   ├── stylesheets/common/
│   └── javascripts/discourse/
├── spec/
│   ├── models/
│   ├── requests/                          # API 集成测试
│   └── system/                            # E2E 测试
└── test/                                  # JS 测试 (QUnit)
```

### plugin.rb 模板

```ruby
# frozen_string_literal: true

# name: discourse-my-plugin
# about: 简短描述
# version: 0.1.0
# authors: Author Name
# url: https://github.com/org/discourse-my-plugin

enabled_site_setting :my_plugin_enabled

register_asset "stylesheets/common/my-plugin.scss"
register_svg_icon "icon-name"

module ::DiscourseMyPlugin
  PLUGIN_NAME = "discourse-my-plugin"
end

require_relative "lib/discourse_my_plugin/engine"

after_initialize do
  # 1. 加载模型、控制器等
  require_relative "app/models/my_model"

  # 2. 挂载路由
  Discourse::Application.routes.append do
    mount ::DiscourseMyPlugin::Engine, at: "/my-plugin"
  end

  # 3. 注册自定义字段
  register_post_custom_field_type(:my_field, :boolean)

  # 4. 扩展核心类（使用 reloadable_patch）
  reloadable_patch { ::Guardian.prepend(DiscourseMyPlugin::GuardianExtension) }

  # 5. 扩展序列化器
  add_to_serializer(:post, :my_field) { object.custom_fields["my_field"] }

  # 6. 事件监听
  on(:post_created) { |post, opts, user| }
end
```

### Engine 模板

```ruby
# lib/discourse_my_plugin/engine.rb
module DiscourseMyPlugin
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseMyPlugin
  end
end
```

### 控制器模板

```ruby
# app/controllers/discourse_my_plugin/my_controller.rb
class DiscourseMyPlugin::MyController < ::ApplicationController
  requires_plugin DiscourseMyPlugin::PLUGIN_NAME
  before_action :ensure_logged_in

  def index
    # guardian.ensure_can_see!(resource)
    render json: { data: [] }
  end
end
```

### 前端组件模板 (.gjs)

```javascript
// assets/javascripts/discourse/components/my-component.gjs
import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";

export default class MyComponent extends Component {
  @service currentUser;
  @service siteSettings;

  @action
  async doSomething() {
    const result = await ajax("/my-plugin/endpoint", { type: "POST" });
  }

  <template>
    <div class="my-component">
      {{yield}}
    </div>
  </template>
}
```

### 插件扩展 API（关键方法）

| 方法 | 用途 |
|------|------|
| `register_post_custom_field_type(name, type)` | 注册 Post 自定义字段 |
| `register_topic_custom_field_type(name, type)` | 注册 Topic 自定义字段 |
| `register_user_custom_field_type(name, type)` | 注册 User 自定义字段 |
| `allow_public_user_custom_field(name)` | 公开用户字段给 API |
| `add_to_serializer(serializer, field) { block }` | 扩展序列化器 |
| `reloadable_patch { Class.prepend(Extension) }` | 扩展核心类 |
| `on(:event_name) { block }` | 监听系统事件 |
| `register_modifier(:name) { block }` | 拦截/修改数据流 |
| `add_admin_route(label, location)` | 添加管理后台路由 |

### Sidebar 扩展

```javascript
// 通过 withPluginApi 添加 sidebar section
import { withPluginApi } from "discourse/lib/plugin-api";

withPluginApi("1.8.0", (api) => {
  api.addSidebarSection((BaseSection, BaseSectionLink) => {
    return class extends BaseSection {
      name = "my-section";
      title = "My Section";
      get links() { return []; }
    };
  });
});
```

### 用户菜单扩展

```javascript
api.registerUserMenuTab((UserMenuTab) => {
  return class extends UserMenuTab {
    get id() { return "my-notifications"; }
    get icon() { return "my-icon"; }
    get panelComponent() { return MyPanel; }
  };
});
```

### 国际化

```yaml
# config/locales/client.en.yml — 前端翻译（在 js: 下）
en:
  js:
    my_plugin:
      title: "Title"

# config/locales/server.en.yml — 后端翻译
en:
  my_plugin:
    errors:
      not_found: "Not found"
```

---

## Development Rules

### General

- Use `pnpm` for JavaScript, `bundle` for Ruby
- Use bin helpers over bundle exec (`bin/rspec`, `bin/rake`, `bin/rails`)
- Make display strings translatable (use placeholders, not split strings)
- Create subagent to review changes against this file after completing tasks

### JavaScript

- No empty backing classes for template-only components unless requested
- Do not add JSDoc to new code; keep existing JSDoc accurate if modifying

### Service Object Pattern

```ruby
class MyService
  include Service::Base

  params do
    attribute :name
    validates :name, presence: true
  end
  model :thing
  policy :check_permission
  step :do_work

  def fetch_thing(params:)
    Thing.find_by(name: params.name)
  end

  def check_permission(thing:, guardian:)
    guardian.can_edit?(thing)
  end

  def do_work(thing:, params:)
    thing.update!(name: params.name)
  end
end
```

---

## Testing

- Don't write unnecessary comments in tests
- Don't test functionality handled by other classes/components
- Don't write obvious tests
- Ruby: use `fab!` over `let()`, system tests for UI in `spec/system`, use page objects

### fab! Syntax

- `fab!(:user)` — creates using Fabricator defaults (variable name matches fabricator)
- `fab!(:user_1, :user)` — preferred when variable name differs, no custom attributes
- `fab!(:user) { Fabricate(:user, username: "custom") }` — with block for custom attributes

### Page Objects (System Specs)

- Located in `spec/system/page_objects/pages/`, inherit from `PageObjects::Pages::Base`
- NEVER store `find()` results — causes stale element references after re-renders
- Use `has_x?` / `has_no_x?` for state checks (finds fresh each time)
- Action methods find+interact atomically, return `self` for chaining
- Don't assert immediate UI feedback after clicks (tests browser, not app logic)

---

## HTTP Response Codes

- **204 No Content**: `head :no_content` for DELETE, fire-and-forget POST/PUT (mark as read, clear notifications)
- **200 OK**: `render json: success_json` when returning data or clients expect a body
- **201 Created**: When creating resources, include location header or resource data
- Do NOT use 204 when creating resources or returning useful data

---

## Security

- XSS: use `{{}}` (escaped) not `{{{ }}}`, sanitize with `sanitize`/`cook`, no `innerHTML`, careful with `@html`
- Auth: Guardian classes (`lib/guardian.rb`), POST/PUT/DELETE for state changes, CSRF tokens
- Input: validate client+server, strong parameters, length limits
- Authorization: Guardian `can_see?`/`can_edit?` patterns, route+action permissions

---

## Database

- Use `includes()`/`preload()` to avoid N+1, `find_each()`/`in_batches()` for large sets
- Bulk: `update_all`/`delete_all`, `exists?` over `present?`
- Migrations: include rollback logic, `algorithm: :concurrently` for indexes on large tables, deprecate before removing columns
- Two migration directories: `db/migrate/` (regular) and `db/post_migrate/` (safe to run with live traffic)

---

## Key File Paths

### Core System

| 文件 | 用途 |
|------|------|
| `config/site_settings.yml` | 所有站点设置定义 |
| `lib/plugin/instance.rb` | 插件 API（1630 行完整接口） |
| `lib/guardian.rb` + `lib/guardian/` | 权限系统 |
| `app/assets/stylesheets/color_definitions.scss` | CSS 变量定义（150+） |
| `app/assets/stylesheets/common/foundation/variables.scss` | SCSS 变量和 z-index 层级 |
| `app/assets/stylesheets/common/base/header.scss` | Header 默认样式 |
| `frontend/discourse/app/components/header/` | Header 组件架构 |

### Reference Themes

| 目录 | 说明 |
|------|------|
| `themes/horizon/` | 官方完整主题（最佳参考） |
| `themes/foundation/` | 空白主题模板 |

### Reference Plugins

| 目录 | 说明 |
|------|------|
| `plugins/spoiler-alert/` | 最小插件（事件监听 + 样式） |
| `plugins/poll/` | 中等插件（MVC + 前端组件 + 数据库） |
| `plugins/chat/` | 大型插件（完整子系统参考） |

### CSS 变量体系（常用）

```css
/* 布局 */
--d-max-width: 1110px;
--d-border-radius: 4px;
--d-border-radius-large: 8px;
--d-sidebar-width: 280px;

/* 间距 */
--space-1: 4px; --space-2: 8px; --space-4: 16px; --space-6: 24px;

/* 颜色（从 color_scheme 自动生成） */
--primary, --secondary, --tertiary, --quaternary
--header_background, --header_primary
--danger, --success, --love, --highlight
--primary-very-low ~ --primary-very-high
--primary-50 ~ --primary-900

/* 阴影 */
--shadow-header, --shadow-dropdown, --shadow-card

/* Z-index（使用 z() 函数） */
z("header")   /* 1000 */
z("modal", "dialog")  /* 1700 */
```
