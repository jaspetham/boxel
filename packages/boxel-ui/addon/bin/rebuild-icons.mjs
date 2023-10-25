import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { optimize } from 'svgo';

const srcDir = new URL('../raw-icons', import.meta.url).pathname;
const destDir = new URL('../src/icons', import.meta.url).pathname;

const PREFIX = `
// This file is auto-generated by 'pnpm rebuild:icons'
import type { TemplateOnlyComponent } from '@ember/component/template-only';

import type { Signature } from './types.ts';

const IconComponent: TemplateOnlyComponent<Signature> = <template>
`;
const SUFFIX = `
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = "__ICON_COMPONENT_NAME__";
export default IconComponent;
`;
let componentsToGenerate = fs.readdirSync(srcDir).map((filename) => {
  return {
    name: toPascalCase(path.parse(filename).name),
    sourceFile: filename,
    outFile: filename.replace('.svg', '.gts'),
  };
});
componentsToGenerate.sort((a, b) => a.name.localeCompare(b.name));

for (const c of componentsToGenerate) {
  let fullPath = path.resolve(srcDir, c.sourceFile);
  let contents = fs.readFileSync(fullPath, 'utf-8');
  contents = optimize(contents, {
    path: fullPath,
    plugins: [
      {
        name: 'preset-default',
        params: {
          overrides: {
            removeTitle: false,
            removeDesc: { removeAny: false },
            removeViewBox: false,
          },
        },
      },
    ],
  }).data;
  contents = contents.replace(/<svg(.*?)>/, '<svg$1 ...attributes>');
  let suffix = SUFFIX.replace('__ICON_COMPONENT_NAME__', c.name);
  contents = `${PREFIX}${contents}${suffix}`;
  fs.writeFileSync(path.resolve(destDir, c.outFile), contents);
}

let indexContents = `// This file is auto-generated by 'pnpm rebuild:icons'
/* eslint-disable simple-import-sort/imports */

import type { Icon } from './icons/types.ts';

`;
indexContents += componentsToGenerate
  .map((c) => `import ${c.name} from './icons/${c.outFile}';`)
  .join('\n');
indexContents += '\n\n';
let componentNameArray = componentsToGenerate.map((c) => c.name);
indexContents += `export const ALL_ICON_COMPONENTS = [\n  ${componentNameArray.join(
  ',\n  ',
)},\n];\n`;
indexContents += `export {\n  type Icon,\n  ${componentNameArray.join(
  ',\n  ',
)},\n};\n`;
fs.writeFileSync(path.resolve(destDir, '../icons.gts'), indexContents);

execSync(`prettier -w ${destDir}/*`);

function toPascalCase(text) {
  return text.replace(/(^\w|-\w)/g, clearAndUpper);
}

function clearAndUpper(text) {
  return text.replace(/-/, '').toUpperCase();
}
