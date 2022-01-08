module.exports = {
  tutorialSidebar: [
    'prologue',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'getting-started/installation',
        'getting-started/tutorial',
      ],
    },
    {
      type: 'category',
      label: 'Models',
      /*link: {
        type: 'generated-index',
        title: 'Models',
        description: 'Models define what data can be persisted and manipulated by a Marten application. They explicitly define fields and rules that map to database tables.',
        slug: '/models',
      },*/
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
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Views',
      items: ['views/overview'],
    },
    {
      type: 'category',
      label: 'Templates',
      items: ['templates/overview'],
    },
    {
      type: 'category',
      label: 'Guides',
      items: ['guides/overview'],
    },
  ],
};
