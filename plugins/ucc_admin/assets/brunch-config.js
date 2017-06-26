exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^(js)|(node_modules)/,
        'js/talon/admin-lte/jquery-2.2.3.min.js': 'vendor/talon/admin-lte/plugins/jQuery/jquery-2.2.3.min.js',
        'js/talon/admin-lte/bootstrap.min.js': 'vendor/talon/admin-lte/bootstrap/js/bootstrap.min.js',
        'js/talon/admin-lte/app.min.js': 'vendor/talon/admin-lte/dist/js/app.min.js',
        'js/talon/admin-lte/sweetalert.min.js': 'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.min.js'
      }
    },
    // javascripts: {
    //   joinTo: "js/app.js"

    //   // To use a separate vendor.js bundle, specify two files path
    //   // http://brunch.io/docs/config#-files-
    //   // joinTo: {
    //   //  "js/app.js": /^(js)/,
    //   //  "js/vendor.js": /^(vendor)|(deps)/
    //   // }
    //   //
    //   // To change the order of concatenation of files, explicitly mention here
    //   // order: {
    //   //   before: [
    //   //     "vendor/js/jquery-2.1.1.js",
    //   //     "vendor/js/bootstrap.min.js"
    //   //   ]
    //   // }
    // },
    stylesheets: {
      joinTo: {
        'css/app.css': /^(css)/,
        'css/talon/admin-lte/talon.css': [
          'css/talon/admin-lte/talon.css',
          'vendor/talon/admin-lte/dist/css/skins/all-skins.css',
          'vendor/talon/admin-lte/bootstrap/css/bootstrap.min.css',
          'vendor/talon/admin-lte/dist/css/AdminLTE.min.css',
          'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.css'
        ]
      }
    },
    // stylesheets: {
    //   joinTo: "css/app.css"
    // },
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
      "js/app.js": ["js/app", "js/talon/admin-lte/talon"]
      // "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true
  }
};

// To add the Talon generated assets to your brunch build, do the following:
//
// Replace
//
//     javascripts: {
//       joinTo: "js/app.js"
//     },
//
// With
//
//     javascripts: {
//       joinTo: {
//         'js/app.js': /^(js)|(node_modules)/,
//         'js/talon/admin-lte/jquery-2.2.3.min.js': 'vendor/talon/admin-lte/plugins/jQuery/jquery-2.2.3.min.js',
//         'js/talon/admin-lte/bootstrap.min.js': 'vendor/talon/admin-lte/bootstrap/js/bootstrap.min.js',
//         'js/talon/admin-lte/app.min.js': 'vendor/talon/admin-lte/dist/js/app.min.js',
//         'js/talon/admin-lte/sweetalert.min.js': 'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.min.js'
//       }
//     },
//
// Replace
//
//     stylesheets: {
//       joinTo: "css/app.css"
//     },
//
// With
//
//     stylesheets: {
//       joinTo: {
//         'css/app.css': /^(css)/,
//         'css/talon/admin-lte/talon.css': [
//           'css/talon/admin-lte/talon.css',
//           'vendor/talon/admin-lte/dist/css/skins/all-skins.css',
//           'vendor/talon/admin-lte/bootstrap/css/bootstrap.min.css',
//           'vendor/talon/admin-lte/dist/css/AdminLTE.min.css',
//           'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.css'
//         ]
//       }
//     },
//
// Replace
//
//     autoRequire: {
//       "js/app.js": ["js/app"]
//     }
//
// With
//
//     autoRequire: {
//       "js/app.js": ["js/app", "js/talon/admin-lte/talon"]
//     }


// To add the Talon generated assets to your brunch build, do the following:
//
// Replace
//
//     javascripts: {
//       joinTo: "js/app.js"
//     },
//
// With
//
//     javascripts: {
//       joinTo: {
//         'js/app.js': /^(js)|(node_modules)/,
//         'js/talon/admin-lte/jquery-2.2.3.min.js': 'vendor/talon/admin-lte/plugins/jQuery/jquery-2.2.3.min.js',
//         'js/talon/admin-lte/bootstrap.min.js': 'vendor/talon/admin-lte/bootstrap/js/bootstrap.min.js',
//         'js/talon/admin-lte/app.min.js': 'vendor/talon/admin-lte/dist/js/app.min.js',
//         'js/talon/admin-lte/sweetalert.min.js': 'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.min.js'
//       }
//     },
//
// Replace
//
//     stylesheets: {
//       joinTo: "css/app.css"
//     },
//
// With
//
//     stylesheets: {
//       joinTo: {
//         'css/app.css': /^(css)/,
//         'css/talon/admin-lte/talon.css': [
//           'css/talon/admin-lte/talon.css',
//           'vendor/talon/admin-lte/dist/css/skins/all-skins.css',
//           'vendor/talon/admin-lte/bootstrap/css/bootstrap.min.css',
//           'vendor/talon/admin-lte/dist/css/AdminLTE.min.css',
//           'vendor/talon/admin-lte/plugins/sweetalert/dist/sweetalert.css'
//         ]
//       }
//     },
//
// Replace
//
//     autoRequire: {
//       "js/app.js": ["js/app"]
//     }
//
// With
//
//     autoRequire: {
//       "js/app.js": ["js/app", "js/talon/admin-lte/talon"]
//     }

