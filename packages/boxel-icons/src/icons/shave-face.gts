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
    class='lucide lucide-shave-face'
    viewBox='0 0 24 24'
    ...attributes
  ><path
      d='M10 20a7 7 0 0 1-7-7V4c0-.6.4-1 1-1h6M7 7h.01M11 13h3V4c0-.6.4-1 1-1h6M18 7h.01M14 19v2M18 17l1.5 1.5M19 13h2'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'shave-face';
export default IconComponent;
