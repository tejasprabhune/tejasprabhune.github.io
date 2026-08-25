import { defineConfig } from 'astro/config';
import { typst } from 'astro-typst';

export default defineConfig({
  site: 'https://tejasprabhune.github.io',
  redirects: {
    '/canon': '/reading',
    '/blog': '/writing',
    '/blog/charting_a_course': '/writing',
    '/blog/marginalia': '/writing',
  },
  integrations: [
    typst({
      options: { remPx: 14 },
      target: (id) => id.endsWith('.html.typ') ? 'html' : 'svg',
      fontArgs: [{ fontPaths: ['./fonts'] }],
    }),
  ],
});
