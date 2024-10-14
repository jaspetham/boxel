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
    class='lucide lucide-razor'
    viewBox='0 0 24 24'
    ...attributes
  ><path
      d='m22 11-1.6 1.6c-.8.8-2 .8-2.8 0l-6.2-6.2c-.8-.8-.8-2 0-2.8L13 2M15.8 4.8l3.4 3.4'
    /><path d='M17 12c-1.4 1.4-3.6 1.4-4.9 0s-1.4-3.6-.1-5' /><path
      d='m11.1 10.1-8.5 8.5a1.95 1.95 0 1 0 2.8 2.8l8.4-8.4'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'razor';
export default IconComponent;