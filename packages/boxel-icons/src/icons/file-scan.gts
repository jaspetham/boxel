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
    class='lucide lucide-file-scan'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='M20 10V7l-5-5H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h4' /><path
      d='M14 2v4a2 2 0 0 0 2 2h4M16 14a2 2 0 0 0-2 2M20 14a2 2 0 0 1 2 2M20 22a2 2 0 0 0 2-2M16 22a2 2 0 0 1-2-2'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'file-scan';
export default IconComponent;