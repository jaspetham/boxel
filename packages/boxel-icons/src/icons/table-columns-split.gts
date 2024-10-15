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
    class='lucide lucide-table-columns-split'
    viewBox='0 0 24 24'
    ...attributes
  ><path
      d='M14 14v2M14 20v2M14 2v2M14 8v2M2 15h8M2 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H2M2 9h8M22 15h-4M22 3h-2a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h2M22 9h-4M5 3v18'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'table-columns-split';
export default IconComponent;
