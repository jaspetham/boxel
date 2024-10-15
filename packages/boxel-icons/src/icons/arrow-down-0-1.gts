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
    class='lucide lucide-arrow-down-0-1'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='m3 16 4 4 4-4M7 20V4' /><rect
      width='4'
      height='6'
      x='15'
      y='4'
      ry='2'
    /><path d='M17 20v-6h-2M15 20h4' /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'arrow-down-0-1';
export default IconComponent;
