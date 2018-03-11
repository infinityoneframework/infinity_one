exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/one_chat.js"

    },
    stylesheets: {
      joinTo: {
        "css/one_chat.css": [
          /^(css)/,
          "node_modules/highlight.js/styles/default.css"
        ],
        "css/channel_settings.css": ["scss/channel_settings.scss"],
        "css/emojipicker.css": ["vendor/emojiPicker.css"]
      },
      order: {
        // after: ["web/static/css/theme/main.scss", "web/static/css/app.css"] // concat app.css last
        // after: ["web/static/css/livechat.scss", "web/static/css/app.css"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/one_chat.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor"],

    // Where to compile files to
    public: "../../../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    postcss: {
      processors: [
        require("autoprefixer")
      ]
    },
    sass: {
      mode: "native", // This is the important part!
      options: {
        // includePaths: [ 'node_modules' ]
      }
    },
  },

  modules: {
    autoRequire: {
      "js/one_chat.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    whitelist: ["highlight.js"],
    styles: {
      "highlight.js": ['styles/default.css']
    },
    globals: {
      // $: 'jquery',
      // JQuery: 'jquery',
      _: 'underscore'
    }
  }
};
