import { defineConfig } from 'astro/config';
import { typst } from 'astro-typst';

export default defineConfig({
  site: 'https://tejasprabhune.github.io',
  integrations: [
    typst({
      options: { remPx: 14 },
      target: (id) => id.endsWith('.html.typ') ? 'html' : 'svg',
    }),
  ],
});
