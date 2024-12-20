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
    class='lucide lucide-hat-beanie'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='M10.4 6.2C6.7 6.9 4 10.1 4 14v1' /><circle
      cx='12'
      cy='5'
      r='2'
    /><path d='M20 15v-1c0-3.9-2.7-7.1-6.4-7.8' /><rect
      width='20'
      height='5'
      x='2'
      y='15'
      rx='1'
    /><path d='M6 15v5M10 15v5M14 15v5M18 15v5' /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'hat-beanie';
export default IconComponent;
