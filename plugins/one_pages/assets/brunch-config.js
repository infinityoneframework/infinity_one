exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      // joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      joinTo: {
        "js/one_pages.js": /^(js|node_modules)/,
        "js/one_pages_vendor.js": /^(vendor)/
      }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "vendor/js/jquery-2.1.1.js",
      //     "vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        "css/one_pages.css": [
          /^(css|scss)/
        ]
      }
    },
    templates: {
      joinTo: "js/ene_pages.js"
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
    watched: ["static", "third", "css", "scss", "js", "vendor"],
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
    }
  },

  modules: {
    autoRequire: {
      "js/one_pages.js": ["js/one_pages"]
    }
  },

  npm: {
    enabled: true
  }
};
