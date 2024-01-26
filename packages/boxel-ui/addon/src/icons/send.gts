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
  ><path
      fill='var(--icon-color, #000)'
      fill-rule='evenodd'
      d='M11.329 18.867a1.047 1.047 0 0 0 1.306 1.084s-.392.111.048-.013a10 10 0 1 0-5.344.006c.433.121.026.007.026.007a1.052 1.052 0 0 0 1.306-1.084V10.38c0-.187-.105-.232-.236-.1 0 0-1.078 1.1-1.465 1.5a1.341 1.341 0 1 1-1.891-1.9l4.07-4.114a1.17 1.17 0 0 1 1.658 0l4.113 4.119a1.341 1.341 0 0 1-1.879 1.905c-.4-.411-1.476-1.509-1.476-1.509-.131-.133-.236-.089-.236.1z'
    /></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'Send';
export default IconComponent;
