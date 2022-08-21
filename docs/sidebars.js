module.exports = {
  tutorialSidebar: [
    'prologue',
    {
      type: 'category',
      label: 'Getting Started',
      link: {type: 'doc', id: 'getting-started'},
      items: [
        'getting-started/installation',
        'getting-started/tutorial',
      ],
    },
    {
      type: 'category',
      label: 'Models and databases',
      link: {type: 'doc', id: 'models-and-databases'},
      items: [
        'models-and-databases/introduction',
        'models-and-databases/queries',
        'models-and-databases/validations',
        'models-and-databases/callbacks',
        'models-and-databases/migrations',
        {
          type: 'category',
          label: "How-To's",
          items: [
            'models-and-databases/how-to/create-custom-model-fields',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'models-and-databases/reference/fields',
            'models-and-databases/reference/query-set',
            'models-and-databases/reference/migration-operations',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Views and HTTP',
      link: {type: 'doc', id: 'views-and-http'},
      items: [
        'views-and-http/introduction',
        'views-and-http/routing',
        'views-and-http/generic-views',
        'views-and-http/error-views',
        'views-and-http/middlewares',
        'views-and-http/sessions',
        {
          type: 'category',
          label: "How-To's",
          items: [
            'views-and-http/how-to/create-custom-route-parameters',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'views-and-http/reference/generic-views',
            'views-and-http/reference/middlewares',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Templates',
      link: {type: 'doc', id: 'templates'},
      items: [
        'templates/introduction',
        {
          type: 'category',
          label: "How-To's",
          items: [
            'templates/how-to/create-custom-filters',
            'templates/how-to/create-custom-tags',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'templates/reference/filters',
            'templates/reference/tags',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Schemas',
      link: {type: 'doc', id: 'schemas'},
      items: ['schemas/introduction'],
    },
    {
      type: 'category',
      label: 'Files',
      link: {type: 'doc', id: 'files'},
      items: [
        'files/uploading-files',
        'files/managing-files',
        'files/asset-handling',
      ],
    },
    {
      type: 'category',
      label: 'Development',
      link: {type: 'doc', id: 'development'},
      items: [
        'development/settings',
        'development/applications',
        'development/management-commands',
        'development/testing',
        {
          type: 'category',
          label: "How-To's",
          items: [
            'development/how-to/create-custom-commands',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'development/reference/settings',
            'development/reference/management-commands',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Security',
      link: {type: 'doc', id: 'security'},
      items: [
        'security/csrf',
      ],
    },
    {
      type: 'category',
      label: 'Internationalization',
      link: {type: 'doc', id: 'i18n'},
      items: [
        'i18n/introduction',
      ],
    },
  ],
};
