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
      label: 'Development',
      link: {type: 'doc', id: 'development'},
      items: ['development/applications'],
    },
  ],
};
