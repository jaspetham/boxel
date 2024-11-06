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
    class='icon icon-tabler icons-tabler-outline icon-tabler-math-max'
    viewBox='0 0 24 24'
    ...attributes
  ><path stroke='none' d='M0 0h24v24H0z' /><path
      d='M5 6a2 2 0 1 0 4 0 2 2 0 0 0-4 0'
    /><path
      d='M3 15s.616-5.544 2.332-7.93M8.637 7.112C11.354 10.425 14.519 20 17 20c2 0 3.333-3 4-9'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'math-max';
export default IconComponent;
