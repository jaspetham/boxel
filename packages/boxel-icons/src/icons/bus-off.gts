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
    class='icon icon-tabler icons-tabler-outline icon-tabler-bus-off'
    viewBox='0 0 24 24'
    ...attributes
  ><path stroke='none' d='M0 0h24v24H0z' /><path
      d='M4 17a2 2 0 1 0 4 0 2 2 0 1 0-4 0M16.18 16.172a2 2 0 0 0 2.652 2.648'
    /><path
      d='M4 17H2V6a1 1 0 0 1 1-1h2m4 0h8c2.761 0 5 3.134 5 7v5h-1m-5 0H8'
    /><path d='m16 5 1.5 7H22M2 10h8m4 0h3M7 7v3M12 5v3M3 3l18 18' /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'bus-off';
export default IconComponent;