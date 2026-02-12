import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class RedhiveBrainTag extends Component {
  get post() {
    return this.args.outletArgs?.post;
  }

  get isAi() {
    return this.post?.redhive_role === "ai";
  }

  get username() {
    return this.post?.username;
  }

  <template>
    {{#if this.isAi}}
      <div class="redhive-brain-tag">
        <span class="redhive-brain-tag__icon">
          {{icon "brain"}}
        </span>
        <span class="redhive-brain-tag__text">
          {{i18n "discourse_redhive.brain_tag.powered_by"}}
          <a
            class="redhive-brain-tag__username"
            href="/u/{{this.username}}"
          >@{{this.username}}</a>
        </span>
      </div>
    {{/if}}
  </template>
}
