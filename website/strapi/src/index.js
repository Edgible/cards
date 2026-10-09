'use strict';

module.exports = {
  register() {},

  async bootstrap({ strapi }) {
    const publicRole = await strapi.db.query('plugin::users-permissions.role').findOne({
      where: { type: 'public' },
    });

    for (const action of ['api::page.page.find', 'api::page.page.findOne']) {
      const existing = await strapi.db.query('plugin::users-permissions.permission').findOne({
        where: { action, role: publicRole.id },
      });
      if (!existing) {
        await strapi.db.query('plugin::users-permissions.permission').create({
          data: { action, role: publicRole.id },
        });
      }
    }

    const pages = await strapi.documents('api::page.page').findMany();
    if (pages.length === 0) {
      await strapi.documents('api::page.page').create({
        data: {
          title: 'My site',
          body: 'Served from a box I own.',
        },
      });
    }
  },
};
