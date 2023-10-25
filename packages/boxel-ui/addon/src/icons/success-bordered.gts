// This file is auto-generated by 'pnpm rebuild:icons'
import type { TemplateOnlyComponent } from '@ember/component/template-only';

import type { Signature } from './types.ts';

const IconComponent: TemplateOnlyComponent<Signature> = <template>
  <svg
    xmlns='http://www.w3.org/2000/svg'
    width='20'
    height='20'
    viewBox='0 0 20 20'
    ...attributes
  ><g fill='#37eb77' stroke='rgba(0,0,0,0.1)'><circle
        cx='10'
        cy='10'
        r='10'
        stroke='none'
      /><circle cx='10' cy='10' r='9.5' fill='none' /></g><path
      fill='none'
      stroke='#000'
      stroke-linecap='round'
      stroke-linejoin='round'
      stroke-width='2'
      d='m14.727 7-6 6L6 10.273'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'SuccessBordered';
export default IconComponent;
