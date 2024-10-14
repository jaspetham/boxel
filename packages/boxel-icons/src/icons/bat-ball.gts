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
    class='lucide lucide-bat-ball'
    viewBox='0 0 24 24'
    ...attributes
  ><circle cx='18' cy='18' r='4' /><path
      d='m4 8 10 10M20.8 15.2c1.9-3.4 1.4-7.7-1.4-10.6-3.5-3.5-9.1-3.5-12.5 0-4.7 4.7-5.1 6.9-1.4 11.1l-2.9 2.9c-.8.8-.8 2 0 2.8.8.8 2 .8 2.8 0l2.9-2.9c2.6 2.3 4.5 3 6.6 2.1'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'bat-ball';
export default IconComponent;