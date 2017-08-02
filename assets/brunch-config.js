exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      // joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      joinTo: {
       "js/app.js": /^(js|..\/deps|node_modules)/,
       "js/adapter.js": ["vendor/adapter.js"],
       "js/textarea-autogrow.js": ["vendor/textarea-autogrow.js"]
       // "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      order: {
        before: [
          "js/ucc_chat.js"
        ],
        after: [
          "js/typing.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": [
          /^(css)/,
          "node_modules/highlight.js/styles/default.css",
          "node_modules/sweetalert/dist/sweetalert.css"
          // "node_modules/emojionearea/dist/emojionearea.min.css",

        ],
        "css/channel_settings.css": ["scss/channel_settings.scss"],
        "css/toastr.css": ["css/toastr.css"],
        "css/emojipicker.css": ["vendor/emojiPicker.css"]
        // "css/toastr.css": ["web/static/scss/toastr.scss"]
      },
      order: {
        // after: ["web/static/css/theme/main.scss", "web/static/css/app.css"] // concat app.css last
        // after: ["web/static/css/livechat.scss", "web/static/css/app.css"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor", "scss"],
    // Where to compile files to
    public: "../priv/static"
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
    coffeescript: {
      // bare: true
    },
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    // whitelist: ["highlight.js"],
    styles: {
      // toastr: ["toastr.css"],
      "highlight.js": ['styles/default.css'],
      sweetalert: ['dist/sweetalert.css']
      // emojionearea: ['dist/emojionearea.min.css']
      // emojipicker: ['dist/emojipicker.css']
    },
    globals: {
      sweetAlert: 'sweetalert',
      // $: 'jquery',
      // JQuery: 'jquery',
      _: 'underscore'
    }
  }
};
