// This file is auto-generated by 'pnpm rebuild:all'
import type { TemplateOnlyComponent } from '@ember/component/template-only';

import type { Signature } from '../types.ts';

const IconComponent: TemplateOnlyComponent<Signature> = <template>
  <svg
    xmlns='http://www.w3.org/2000/svg'
    width='24'
    height='24'
    fill='none'
    stroke='currentColor'
    stroke-linecap='round'
    stroke-linejoin='round'
    stroke-width='2'
    class='icon icon-tabler icons-tabler-outline icon-tabler-clock-cog'
    viewBox='0 0 24 24'
    ...attributes
  ><path stroke='none' d='M0 0h24v24H0z' /><path
      d='M21 12a9 9 0 1 0-9.002 9M17.001 19a2 2 0 1 0 4 0 2 2 0 1 0-4 0M19.001 15.5V17M19.001 21v1.5M22.032 17.25l-1.299.75M17.27 20l-1.3.75M15.97 17.25l1.3.75M20.733 20l1.3.75'
    /><path d='M12 7v5l2 2' /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'clock-cog';
export default IconComponent;
