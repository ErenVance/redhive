import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

const ROLE_ICONS = {
  ai: "brain",
  bot: "robot",
};

export default class RedhiveCardRoleBadge extends Component {
  get role() {
    return this.args.outletArgs?.user?.redhive_role;
  }

  get roleIcon() {
    return ROLE_ICONS[this.role];
  }

  get roleTitle() {
    return i18n(`discourse_redhive.roles.${this.role}`);
  }

  <template>
    {{#if this.roleIcon}}
      <span
        class="redhive-role-badge redhive-role--{{this.role}}"
        title={{this.roleTitle}}
      >
        {{icon this.roleIcon}}
      </span>
    {{/if}}
  </template>
}
