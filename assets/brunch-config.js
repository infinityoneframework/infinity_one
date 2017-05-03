exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      // joinTo: "js/app.js"
      joinTo: {
       "js/app.js": /^(js)/,
       "js/jquery-3.1.1.min.js": "vendor/jquery-3.1.1.min.js",
       "js/jquery-ui.min.js": "vendor/jquery-ui.min.js",
       "js/bootstrap.min.js": "vendor/bootstrap.min.js",
       "js/material.min.js": "vendor/material.min.js",
       "js/perfect-scrollbar.jquery.min.js": "vendor/perfect-scrollbar.jquery.min.js",
       "js/jquery.validate.min.js": "vendor/jquery.validate.min.js",
       "js/moment.min.js": "vendor/moment.min.js",
       "js/bootstrap-notify.js": "vendor/bootstrap-notify.js",
       "js/bootstrap-datetimepicker.js": "vendor/bootstrap-datetimepicker.js",
       "js/jquery-jvectormap.js": "vendor/jquery-jvectormap.js",
       "js/nouislider.min.js": "vendor/nouislider.min.js",
       "js/jquery.select-bootstrap.js": "vendor/jquery.select-bootstrap.js",
       "js/jquery.datatables.js": "vendor/jquery.datatables.js",
       "js/sweetalert2.js": "vendor/sweetalert2.js",
       "js/jquery.tagsinput.js": "vendor/jquery.tagsinput.js",
       "js/material-dashboard.js": "vendor/material-dashboard.js",
       "js/vendor.js": /^(deps|node_modules).*/,
      },
      order: {
        before: [
          "/js/jquery-ui.min.js",
          "/js/bootstrap.min.js",
          "/js/material.min.js",
          "/js/perfect-scrollbar.jquery.min.js",
          "/js/jquery.validate.min.js",
          "/js/bootstrap-notify.js",
          "/js/moment.min.js",
          "/js/bootstrap-datetimepicker.js",
          "/js/jquery-jvectormap.js",
          "/js/nouislider.min.js",
          "/js/jquery.select-bootstrap.js",
          "/js/jquery.datatables.js",
          "/js/sweetalert2.js",
          "/js/jquery.tagsinput.js",
          "/js/material-dashboard.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(css)/,
        "css/bootstrap.min.css": "vendor/bootstrap.min.css",
        "css/material-dashboard.css": "vendor/material-dashboard.css",
        "css/demo.css": "vendor/demo.css"
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
    watched: ["static", "css", "js", "vendor"],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true
  }
};
