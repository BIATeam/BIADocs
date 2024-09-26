import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'BIA Framework',
  tagline: 'The BIA Framework is a set of components. It give the possibility to build quickly a modern application at the state of art in 2024 (Green IT, Cyber Security, Structured, RWD, Ergonomic, Fast, Powerful, Open to web component integration)',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://biateam.github.io/',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/BIADocs/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'BIATeam', // Usually your GitHub org/user name.
  projectName: 'BIA Framework', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        // Config to hide 3.10.0
        docs: {
          sidebarPath: './sidebars.ts',
          lastVersion: '3.9.0', // '3.9.0' to hide last version // 'current' to display last version
          onlyIncludeVersions: ['3.9.0','older'], // comment to display the current version
          versions: {
            current: {
              label: '3.10.0',
              path: '3.10.0', // '3.10.0' to hide 3.10.0 // '/' to display 3.10.0
            },
            "3.9.0": {
              label: '3.9.0',
              path: '/', // '/' to hide 3.10.0  // '3.9.0' to display 3.10.0
            },
            older: {
              label: 'Older',
              path: 'older',
            },
          },
        },
        // Config to display 3.10.0
        // docs: {
        //   sidebarPath: './sidebars.ts',
        //   lastVersion: 'current', // '3.9.0' to hide last version // 'current' to display last version
        //   //onlyIncludeVersions: ['3.9.0','older'], // comment to display the current version
        //   versions: {
        //     current: {
        //       label: '3.10.0',
        //       path: '/', // '3.10.0' to hide 3.10.0 // '/' to display 3.10.0
        //     },
        //     "3.9.0": {
        //       label: '3.9.0',
        //       path: '3.9.0', // '/' to hide 3.10.0  // '3.9.0' to display 3.10.0
        //     },
        //     older: {
        //       label: 'Older',
        //       path: 'older',
        //     },
        //   },
        // },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          // Useful options to enforce blogging best practices
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/LogoWithTitleBig.jpg',
    navbar: {
      title: '',
      logo: {
        alt: 'BIA Framework Logo',
        src: 'img/LogoAvecTitre.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'leftSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {to: '/blog', label: 'Blog', position: 'left'},
        {
          type: 'docsVersionDropdown',
          position: 'right',
          dropdownActiveClassDisabled: true,
        },
        {
          href: 'https://github.com/BIATeam',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Introduction',
              to: '/docs/Introduction/What_is_BIA_Framework',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/BIATeam',
            },
          ],
        },
      ],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['csharp']
    },
  } satisfies Preset.ThemeConfig,
  plugins: [require.resolve('docusaurus-lunr-search')],
};

export default config;
