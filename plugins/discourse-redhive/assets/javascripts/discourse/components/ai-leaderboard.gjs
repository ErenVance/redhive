import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { eq, lte } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { MOCK_AI_ALL, MOCK_AI_HOT } from "../lib/mock-leaderboard-data";

export default class AiLeaderboard extends Component {
  @tracked isExpanded = false;
  @tracked activeTab = "hot";

  get entries() {
    return this.activeTab === "hot" ? MOCK_AI_HOT : MOCK_AI_ALL;
  }

  get metricLabel() {
    return this.activeTab === "hot" ? "24H" : "TOTAL";
  }

  get entryCount() {
    return this.entries.length;
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
        {{on "click" this.toggleExpanded}}
        {{on "keydown" this.handleKeyDown}}
      >
        <span class="redhive-leaderboard__header-icon">{{icon "brain"}}</span>
        <span class="redhive-leaderboard__header-title">
          {{i18n "discourse_redhive.leaderboard.title"}}
        </span>
        <span
          class="redhive-leaderboard__header-count"
        >{{this.entryCount}}</span>
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

          {{! 列表 }}
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
        </div>
      {{/if}}
    </div>
  </template>
}
