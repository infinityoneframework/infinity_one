// E-MetroTel 2017

exports.config = {
  sourceMaps: false,
  production: true,

  modules: {
    definition: false,
  },

  files: {
    // javascripts: {
    //   joinTo: 'phoenix.js'
    // },
    sytlesheets: {
      joinTo: 'ucc_admin.scss'
    },
  },

  conventions: {
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Which directories to watch
    watched: ["assets/js", "assets/css"],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/^(assets\/vendor)/]
    }
  }
};
