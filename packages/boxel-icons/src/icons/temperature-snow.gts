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
    class='icon icon-tabler icons-tabler-outline icon-tabler-temperature-snow'
    viewBox='0 0 24 24'
    ...attributes
  ><path stroke='none' d='M0 0h24v24H0z' /><path
      d='M4 13.5a4 4 0 1 0 4 0V5a2 2 0 1 0-4 0v8.5M4 9h4M14.75 4l1 2H18'
    /><path d='m17 4-3 5 2 3M20.25 10 19 12l1.25 2' /><path
      d='M22 12h-6l-2 3M18 18h-2.25l-1 2'
    /><path d='m17 20-3-5h-1M12 9l2.088.008' /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'temperature-snow';
export default IconComponent;
