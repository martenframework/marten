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
      label: 'Models',
      link: {type: 'doc', id: 'models'},
      items: [
        'models/introduction',
        'models/queries',
        'models/validations',
        'models/callbacks',
        'models/migrations',
        {
          type: 'category',
          label: "How-To's",
          items: [
            'models/how-to/create-custom-model-fields',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'models/reference/fields',
            'models/reference/query_set',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Views',
      link: {type: 'doc', id: 'views'},
      items: [
        'views/introduction',
        'views/routing',
        'views/generic-views',
        'views/error-views',
        'views/middlewares',
      ],
    },
    {
      type: 'category',
      label: 'Templates',
      link: {type: 'doc', id: 'templates'},
      items: ['templates/introduction'],
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
      items: ['files/introduction'],
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
        {
          type: 'category',
          label: 'Reference',
          items: [
            'development/reference/settings',
          ],
        },
      ],
    },
  ],
};
