const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

// With JSDoc @type annotations, IDEs can provide config autocompletion
/** @type {import('@docusaurus/types').DocusaurusConfig} */
(module.exports = {
  title: 'Marten',
  url: 'https://docs.martenframework.com',
  baseUrl: '/docs/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'martenframework',
  projectName: 'marten',

  plugins: [
    'docusaurus-plugin-sass',
    require.resolve('@cmfcmf/docusaurus-search-local'),
  ],

  presets: [
    [
      '@docusaurus/preset-classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          breadcrumbs: false,
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: '/',
        },
        theme: {
          customCss: require.resolve('./src/scss/custom.scss'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/logo_primary_zoomed_alt_white.png',
      navbar: {
        title: 'Marten',
        logo: {
          alt: 'My Site Logo',
          src: 'img/logo_primary.svg',
        },
        items: [
          {
            type: 'docsVersionDropdown',
            position: 'right',
            dropdownActiveClassDisabled: true,
          },
          {
            href: 'https://martenframework.com/docs/api/index.html',
            label: 'API',
            position: 'right',
          },
          {
            href: 'https://github.com/martenframework/marten',
            label: 'GitHub',
            position: 'right',
          },
        ],
        hideOnScroll: true,
      },
      prism: {
        theme: require('prism-react-renderer/themes/okaidia'),
        additionalLanguages: ['ruby', 'crystal'],
      },
    }),
});
