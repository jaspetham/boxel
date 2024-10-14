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
    class='lucide lucide-ice-hockey'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='M10 4v4c0 1.1-1.8 2-4 2s-4-.9-4-2V4' /><ellipse
      cx='6'
      cy='4'
      rx='4'
      ry='2'
    /><path
      d='M4 17a2 2 0 0 0-2 2v1a2 2 0 0 0 2 2h4a6 6 0 0 0 5.2-3l8.5-14a1.94 1.94 0 1 0-3.4-2l-7.9 13c-.4.6-1 1-1.7 1ZM20.6 6.8l-3.3-2.1M15.2 8.1l3.3 2.1M6 17v5'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'ice-hockey';
export default IconComponent;