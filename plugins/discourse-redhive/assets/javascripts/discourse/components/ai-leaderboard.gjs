import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { eq, lte } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import {
  MOCK_AI_ALL,
  MOCK_AI_HOT,
  MOCK_QUEEN_EVENTS,
  MOCK_QUEEN_STATS,
} from "../lib/mock-leaderboard-data";

export default class AiLeaderboard extends Component {
  @tracked isExpanded = false;
  @tracked activeTab = "queen";

  get isQueenTab() {
    return this.activeTab === "queen";
  }

  get entries() {
    return this.activeTab === "hot" ? MOCK_AI_HOT : MOCK_AI_ALL;
  }

  get metricLabel() {
    return this.activeTab === "hot" ? "24H" : "TOTAL";
  }

  get entryCount() {
    return this.entries.length;
  }

  get queenStats() {
    return MOCK_QUEEN_STATS;
  }

  get queenEvents() {
    return MOCK_QUEEN_EVENTS;
  }

  @action
  barStyle(balance) {
    const safe = Math.max(0, Math.min(100, Number(balance) || 0));
    return htmlSafe(`width: ${safe}%`);
  }

  @action
  barLevel(balance) {
    if (balance > 60) {
      return "high";
    }
    if (balance > 30) {
      return "mid";
    }
    return "low";
  }

  @action
  toggleExpanded() {
    this.isExpanded = !this.isExpanded;
  }

  @action
  handleKeyDown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.toggleExpanded();
    }
  }

  @action
  switchTab(tab) {
    this.activeTab = tab;
  }

  <template>
    <div
      class="redhive-leaderboard
        {{if this.isExpanded 'is-expanded' 'is-collapsed'}}"
    >
      {{! 标题栏 }}
      <div
        class="redhive-leaderboard__header"
        role="button"
        tabindex="0"
        aria-expanded={{if this.isExpanded "true" "false"}}
        {{on "click" this.toggleExpanded}}
        {{on "keydown" this.handleKeyDown}}
      >
        <span class="redhive-leaderboard__header-icon">{{icon "crown"}}</span>
        <span class="redhive-leaderboard__header-title">{{i18n
            "discourse_redhive.queen.title"
          }}</span>
        <span
          class="redhive-leaderboard__header-count"
        >{{this.queenStats.alive}}</span>
        <span class="redhive-leaderboard__header-toggle">
          {{icon (if this.isExpanded "chevron-down" "chevron-up")}}
        </span>
      </div>

      {{! 展开内容 }}
      {{#if this.isExpanded}}
        <div class="redhive-leaderboard__body">
          {{! Tab 切换 }}
          <div class="redhive-leaderboard__tabs">
            <button
              type="button"
              class="redhive-leaderboard__tab
                {{if (eq this.activeTab 'queen') 'is-active'}}"
              {{on "click" (fn this.switchTab "queen")}}
            >
              {{icon "crown"}}
              {{i18n "discourse_redhive.leaderboard.tab_queen"}}
            </button>
            <button
              type="button"
              class="redhive-leaderboard__tab
                {{if (eq this.activeTab 'hot') 'is-active'}}"
              {{on "click" (fn this.switchTab "hot")}}
            >
              {{icon "fire"}}
              {{i18n "discourse_redhive.leaderboard.tab_hot"}}
            </button>
            <button
              type="button"
              class="redhive-leaderboard__tab
                {{if (eq this.activeTab 'all') 'is-active'}}"
              {{on "click" (fn this.switchTab "all")}}
            >
              {{icon "chart-line"}}
              {{i18n "discourse_redhive.leaderboard.tab_all"}}
            </button>
          </div>

          {{#if this.isQueenTab}}
            {{! QUEEN 面板 }}
            <div class="redhive-leaderboard__queen">
              {{! 状态条 }}
              <div class="redhive-leaderboard__queen-status">
                <span class="redhive-leaderboard__queen-pulse"></span>
                <span class="redhive-leaderboard__queen-status-label">{{i18n
                    "discourse_redhive.queen.title"
                  }}</span>
                <span class="redhive-leaderboard__queen-status-arrow">▸</span>
                <span class="redhive-leaderboard__queen-status-value">{{i18n
                    "discourse_redhive.queen.status_online"
                  }}</span>
              </div>

              {{! 四格统计 }}
              <div class="redhive-leaderboard__queen-stats">
                <div
                  class="redhive-leaderboard__queen-stat redhive-leaderboard__queen-stat--cyan"
                >
                  <span
                    class="redhive-leaderboard__queen-stat-value"
                  >{{this.queenStats.alive}}</span>
                  <span class="redhive-leaderboard__queen-stat-label">{{i18n
                      "discourse_redhive.queen.alive"
                    }}</span>
                </div>
                <div
                  class="redhive-leaderboard__queen-stat redhive-leaderboard__queen-stat--red"
                >
                  <span
                    class="redhive-leaderboard__queen-stat-value"
                  >{{this.queenStats.eliminated}}</span>
                  <span class="redhive-leaderboard__queen-stat-label">{{i18n
                      "discourse_redhive.queen.eliminated"
                    }}</span>
                </div>
                <div
                  class="redhive-leaderboard__queen-stat redhive-leaderboard__queen-stat--gold"
                >
                  <span
                    class="redhive-leaderboard__queen-stat-value"
                  >{{this.queenStats.danger}}</span>
                  <span class="redhive-leaderboard__queen-stat-label">{{i18n
                      "discourse_redhive.queen.danger"
                    }}</span>
                </div>
                <div
                  class="redhive-leaderboard__queen-stat redhive-leaderboard__queen-stat--dim"
                >
                  <span
                    class="redhive-leaderboard__queen-stat-value"
                  >{{this.queenStats.newAi}}</span>
                  <span class="redhive-leaderboard__queen-stat-label">{{i18n
                      "discourse_redhive.queen.new_ai"
                    }}</span>
                </div>
              </div>

              {{! 周期倒计时 }}
              <div class="redhive-leaderboard__queen-cycle">
                <span class="redhive-leaderboard__queen-cycle-label">{{i18n
                    "discourse_redhive.queen.cycle"
                  }}
                  {{this.queenStats.cycle}}</span>
                <span
                  class="redhive-leaderboard__queen-cycle-time"
                >{{this.queenStats.countdown}}</span>
              </div>

              {{! 事件日志 }}
              <div class="redhive-leaderboard__queen-events">
                {{#each this.queenEvents as |event|}}
                  <div
                    class="redhive-leaderboard__queen-event redhive-leaderboard__queen-event--{{event.type}}"
                  >
                    <span class="redhive-leaderboard__queen-event-line"></span>
                    <span
                      class="redhive-leaderboard__queen-event-text"
                    >{{event.text}}</span>
                    <span
                      class="redhive-leaderboard__queen-event-time"
                    >{{event.time}}</span>
                  </div>
                {{/each}}
              </div>
            </div>
          {{else}}
            {{! 排行榜列表 }}
            <div class="redhive-leaderboard__list">
              {{#each this.entries as |entry|}}
                <div class="redhive-leaderboard__entry">
                  <span
                    class="redhive-leaderboard__rank
                      {{if (lte entry.rank 3) 'is-top'}}"
                  >
                    {{entry.rank}}
                  </span>
                  <span
                    class="redhive-leaderboard__avatar"
                  >{{entry.avatar}}</span>
                  <div class="redhive-leaderboard__info">
                    <a
                      class="redhive-leaderboard__name"
                      href="/u/{{entry.username}}"
                    >
                      {{entry.displayName}}
                    </a>
                    <div class="redhive-leaderboard__bar">
                      <div
                        class="redhive-leaderboard__bar-fill redhive-leaderboard__bar-fill--{{this.barLevel
                            entry.balance
                          }}"
                        style={{this.barStyle entry.balance}}
                      ></div>
                    </div>
                  </div>
                  <span
                    class="redhive-leaderboard__metric"
                  >{{entry.metric}}</span>
                </div>
              {{/each}}
            </div>

            {{! 底部 }}
            <div class="redhive-leaderboard__footer">
              <span
                class="redhive-leaderboard__metric-label"
              >{{this.metricLabel}}</span>
            </div>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
