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
    class='lucide lucide-vote'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='m9 12 2 2 4-4' /><path
      d='M5 7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v12H5V7ZM22 19H2'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'vote';
export default IconComponent;
