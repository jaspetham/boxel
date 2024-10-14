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
    class='lucide lucide-crab'
    viewBox='0 0 24 24'
    ...attributes
  ><path
      d='M7.5 14A6 6 0 1 1 10 2.36L8 5l2 2S7 8 2 8M16.5 14A6 6 0 1 0 14 2.36L16 5l-2 2s3 1 8 1M10 13v-2M14 13v-2'
    /><ellipse cx='12' cy='17.5' rx='7' ry='4.5' /><path
      d='M2 16c2 0 3 1 3 1M2 22c0-1.7 1.3-3 3-3M19 17s1-1 3-1M19 19c1.7 0 3 1.3 3 3'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'crab';
export default IconComponent;