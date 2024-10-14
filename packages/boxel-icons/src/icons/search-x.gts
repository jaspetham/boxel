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
    class='lucide lucide-search-x'
    viewBox='0 0 24 24'
    ...attributes
  ><path d='m13.5 8.5-5 5M8.5 8.5l5 5' /><circle cx='11' cy='11' r='8' /><path
      d='m21 21-4.3-4.3'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'search-x';
export default IconComponent;