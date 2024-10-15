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
    class='icon icon-tabler icons-tabler-outline icon-tabler-vip-off'
    viewBox='0 0 24 24'
    ...attributes
  ><path stroke='none' d='M0 0h24v24H0z' /><path
      d='M3 5h2m4 0h12M3 19h16M4 9l2 6h1l2-6M12 12v3M16 12V9h2a2 2 0 1 1 0 4h-1M3 3l18 18'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'vip-off';
export default IconComponent;
