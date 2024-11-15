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
    class='lucide lucide-pond'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='M4 3v2' /><rect width='4' height='7' x='10' y='4' rx='2' /><path
      d='M4 12v10M12 2v2'
    /><rect width='4' height='7' x='2' y='5' rx='2' /><path
      d='M12 11v4.35M15 18.5V22c-3.8 0-7-1.6-7-3.5s3.2-3.5 7-3.5 7 1.6 7 3.5c0 1.3-1.5 2.5-3.9 3.1Z'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'pond';
export default IconComponent;
