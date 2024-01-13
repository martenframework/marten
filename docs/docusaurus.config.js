const {themes} = require('prism-react-renderer');
const lightTheme = themes.github;
const darkTheme = themes.dracula;

// With JSDoc @type annotations, IDEs can provide config autocompletion
/** @type {import('@docusaurus/types').DocusaurusConfig} */
(module.exports = {
  title: 'Marten',
  url: 'https://martenframework.com',
  baseUrl: '/docs/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'martenframework',
  projectName: 'marten',

  plugins: [
    'docusaurus-plugin-sass',
    // require.resolve('@cmfcmf/docusaurus-search-local'),
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
      image: 'img/1000x420_logo.jpg',
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
            href: 'https://martenframework.com/docs/api/0.3/index.html',
            label: 'API',
            position: 'right',
          },
          {
            href: 'https://github.com/martenframework/marten',
            label: 'GitHub',
            position: 'right',
          },
          {
            href: 'https://martenframework.com',
            label: 'Website',
            position: 'right',
            target: '',
          },
        ],
        hideOnScroll: true,
      },
      prism: {
        theme: themes.okaidia,
        additionalLanguages: ['ruby', 'crystal', 'bash'],
      },
      algolia: {
        appId: 'EQ32BI3T7E',
        apiKey: '784eef906f1329000df262eef9c2960d',
        indexName: 'martenframework',
        contextualSearch: true,
      },
    }),
});
