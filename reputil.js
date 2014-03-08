// Generated by CoffeeScript 1.6.3
(function() {
  var actions, bower, cfg, child_process, deepExtend, e, fs, glob, pkg;

  fs = require("fs");

  glob = require("glob");

  child_process = require("child_process");

  pkg = void 0;

  cfg = void 0;

  bower = void 0;

  actions = {};

  deepExtend = function(target, src) {
    var key, val, _results;
    if (!src) {
      return;
    }
    _results = [];
    for (key in src) {
      val = src[key];
      if (typeof val === "object" && typeof target[key] === "object") {
        _results.push(deepExtend(target[key], val));
      } else {
        _results.push(target[key] = val);
      }
    }
    return _results;
  };

  actions.build = function() {
    actions.compile();
    actions.genreadme();
    actions.genbower();
    return actions.genconfigxml();
  };

  actions.genpackage = function() {
    var e;
    try {
      pkg = fs.readFileSync("package.json");
    } catch (_error) {
      e = _error;
      pkg = "{}";
    }
    pkg = JSON.parse(pkg);
    if (pkg.version == null) {
      pkg.version = "0.0.0";
    }
    pkg.name = cfg.name;
    pkg.description = cfg.desc;
    pkg.license = cfg.license;
    pkg.keywords = cfg.tags;
    pkg.authors = [cfg.author];
    pkg.repository = {
      type: "git",
      url: "https://github.com/" + cfg.repos + ".git"
    };
    deepExtend(pkg, cfg["package"]);
    return fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
  };

  actions.genbower = function() {
    var e;
    if (!cfg.bower) {
      return;
    }
    try {
      bower = JSON.parse(fs.readFileSync("bower.json"));
    } catch (_error) {
      e = _error;
      bower = {};
    }
    bower.name = pkg.name;
    bower.version = pkg.version;
    bower.description = pkg.description;
    bower.license = pkg.license;
    bower.keywords = pkg.keywords;
    bower.authors = pkg.author;
    bower.repository = pkg.repository;
    deepExtend(bower, cfg.bower);
    return fs.writeFileSync("bower.json", JSON.stringify(bower, null, 2) + "\n");
  };

  actions.genconfigxml = function() {
    var plugin;
    if (!cfg.phonegap) {
      return;
    }
    return fs.writeFileSync("config.xml", "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<widget xmlns = \"http://www.w3.org/ns/widgets\"\n        xmlns:gap = \"http://phonegap.com/ns/1.0\"\n        id = \"" + (cfg.site.split(".").reverse().join(".")) + "." + cfg.name + "\"\n        version = \"" + pkg.version + "\">\n\n    <!-- AUTOGENERATED DO NOT EDIT -->\n\n    <name>" + cfg.title + "</name>\n    <description>" + pkg.description + "</description>\n    <author href=\"http://" + cfg.site + "\" email=\"" + pkg.name + "@" + cfg.site + "\">" + cfg.author + "</author>\n    <preference name=\"phonegap-version\" value=\"3.3.0\" />\n    <preference name=\"orientation\" value=\"" + (cfg.phonegap.orientation || "default") + "\" />\n    <preference name=\"target-device\" value=\"universal\" />\n    <preference name=\"fullscreen\" value=\"" + (!!cfg.phonegap.fullscreen) + "\" />\n    <preference name=\"prerendered-icon\" value=\"true\" />\n    <preference name=\"ios-statusbarstyle\" value=\"black-opaque\" />\n    <preference name=\"detect-data-types\" value=\"false\" />\n    <preference name=\"exit-on-suspend\" value=\"" + (!!cfg.phonegap.exitOnSuspend) + "\" />\n    <preference name=\"auto-hide-splash-screen\" value=\"true\" />\n    <preference name=\"android-minSdkVersion\" value=\"" + (cfg.phonegap.androidVersion || 10) + "\" />\n    <preference name=\"android-installLocation\" value=\"auto\" />\n    <preference name=\"permissions\" value=\"" + (cfg.phonegap.permissions || "none") + "\" />\n    " + (((function() {
      var _i, _len, _ref, _results;
      _ref = cfg.phonegap.plugins || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        plugin = _ref[_i];
        _results.push("    <gap:plugin name=\"" + plugin + "\" />");
      }
      return _results;
    })()).join("\n")) + "\n    <icon src=\"icon.png\" />\n    " + (cfg.phonegap.splash ? '<gap:splash src="splash.png" />' : "") + "\n    <access origin=\"*\" />\n</widget>\n");
  };

  actions.genhtml = function() {
    var src, viewport;
    if (!cfg.html) {
      return;
    }
    viewport = cfg.html.viewport || "width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=0";
    return fs.writeFileSync("index.html", "<!DOCTYPE html>\n<html>\n  <!-- AUTOGENERATED DO NOT EDIT -->\n  <head>\n    <title>" + cfg.title + "</title>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">\n    <meta name=\"HandheldFriendly\" content=\"True\">\n    <meta name=\"viewport\" content=\"" + viewport + "\">\n    <meta name=\"format-detection\" content=\"telephone=no\">\n    <meta name=\"apple-mobile-web-app-capable\" content=\"yes\">\n    <meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black\">\n    <link rel=\"apple-touch-icon-precomposed\" href=\"icon.png\">\n    <link rel=\"icon\" type=\"image/png\" href=\"icon.png\">\n    <link rel=\"shortcut icon\" href=\"icon.png\">\n    \ " + (((function() {
      var _i, _len, _ref, _results;
      _ref = cfg.html.css || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        src = _ref[_i];
        _results.push("<link rel=\"stylesheet\" href=\"" + src + "\">");
      }
      return _results;
    })()).join("\n    ")) + "\n  </head>\n  <body>\n   \ " + (cfg.html.body || "") + "\n   \ " + (((function() {
      var _i, _len, _ref, _results;
      _ref = (cfg.html.js || []).concat([cfg.src.replace(/.coffee$/, ".js")]);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        src = _ref[_i];
        _results.push("<script src=\"" + src + "\"></script>");
      }
      return _results;
    })()).join("\n    ")) + "\n  </body>\n</html>\n");
  };

  actions.xgenhtml = function() {
    var viewport;
    if (!cfg.html) {
      return;
    }
    viewport = cfg.html.viewport || "width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=0";
    return fs.writeFileSync("index.html", "  <!DOCTYPE html>\n  <html>\n    <!-- AUTOGENERATED DO NOT EDIT -->\n    <head>\n      <title>" + cfg.title + "</title>\n      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n      <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">\n      <meta name=\"HandheldFriendly\" content=\"True\">\n      <meta name=\"viewport\" content=\"" + viewport + "\">\n      <meta name=\"format-detection\" content=\"telephone=no\">\n      <meta name=\"apple-mobile-web-app-capable\" content=\"yes\">\n      <meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black\">\n      <link rel=\"apple-touch-icon-precomposed\" href=\"icon.png\">\n      <link rel=\"icon\" type=\"image/png\" href=\"icon.png\">\n      <link rel=\"shortcut icon\" href=\"icon.png\">\n    </head\n    <body>\n      " + (cfg.html.body || "") + "\n      #\n    </body>\n  </html>\n\n");
  };

  actions.gencoffee = function() {
    if (fs.existsSync(cfg.src)) {
      return;
    }
    return fs.writeFileSync(cfg.src, "\# {\{{1 Boilerplate\n\# predicates that can be optimised away by uglifyjs\nif typeof isNodeJs == \"undefined\" or typeof runTest == \"undefined\" then do ->\n  root = if typeof window == \"undefined\" then global else window\n  root.isNodeJs = (typeof process != \"undefined\") if typeof isNodeJs == \"undefined\"\n  root.isWindow = (typeof window != \"undefined\") if typeof isWindow == \"undefined\"\n  root.isPhoneGap = typeof document?.ondeviceready != \"undefined\" if typeof isPhoneGap == \"undefined\"\n  root.runTest = (if isNodeJs then process.argv[2] == \"test\" else location.hash.slice(1) == \"test\") if typeof runTest == \"undefined\"\n\n\# use - require/window.global with non-require name to avoid being processed in firefox plugins\nuse = if isNodeJs then ((module) -> require module) else ((module) -> window[module]) \n\# execute main\nonReady = (fn) ->\n  if isWindow\n    if document.readystate != \"complete\" then fn() else setTimeout (-> onReady fn), 17 \n\# {\{{1 Actual code\n\nonReady ->\n  console.log \"HERE\"\n\n");
  };

  actions.genreadme = function() {
    var isCode, line, prevWasCode, readme, source, _i, _len, _ref, _ref1;
    source = fs.readFileSync(cfg.src, "utf-8");
    readme = "# " + cfg.title + " " + pkg.version + "\n\n";
    readme += pkg.description || "";
    readme += "\n";
    if (fs.existsSync(".travis.yml")) {
      readme += "[![ci](https://secure.travis-ci.org/" + cfg.repos + ".png)](http://travis-ci.org/" + cfg.repos + ")\n\n";
    }
    if (cfg.testling) {
      readme += "[![browser support](https://ci.testling.com/" + cfg.repos + ".png)](http://ci.testling.com/" + cfg.repos + ")\n\n";
    }
    _ref = source.split("\n");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      if ((_ref1 = line.trim()) === "#!/usr/bin/env coffee") {
        continue;
      }
      if ((line.search(/^\s*#/)) === -1) {
        line = "    " + line;
        isCode = true;
      } else {
        line = line.replace(/^\s*# ?/, "");
        line = line.replace(new RegExp("(.*){{" + "{(\\d)(.*)"), function(_, a, header, b) {
          var i;
          return ((function() {
            var _j, _results;
            _results = [];
            for (i = _j = 1; 1 <= +header ? _j <= +header : _j >= +header; i = 1 <= +header ? ++_j : --_j) {
              _results.push("#");
            }
            return _results;
          })()).join("") + " " + (a + b).trim();
        });
        isCode = false;
      }
      if (isCode !== prevWasCode) {
        readme += "\n";
      }
      prevWasCode = isCode;
      readme += line + "\n";
    }
    readme += "\n----\n\nREADME.md autogenerated from `" + cfg.src + "` ";
    readme += "![solsort](https://ssl.solsort.com/_reputil_" + (cfg.repos.replace("/", "_")) + ".png)\n";
    return fs.writeFileSync("README.md", readme);
  };

  actions.autocompile = function() {
    var spawnChild;
    spawnChild = function(fname) {
      var child, cmd;
      cmd = "" + __dirname + "/node_modules/.bin/coffee -wc " + fname;
      console.log(cmd);
      child = child_process.exec(cmd);
      child.stdout.pipe(process.stdout);
      child.stderr.pipe(process.stderr);
      return child.on("exit", function() {
        return spawnChild(fname);
      });
    };
    return spawnChild(cfg.src);
  };

  actions.compile = function() {
    var child;
    child = child_process.exec("" + __dirname + "/node_modules/.bin/coffee -c " + cfg.src);
    child.stdout.pipe(process.stdout);
    return child.stderr.pipe(process.stderr);
  };

  if (!actions[process.argv[2]]) {
    console.log("usage: reputil " + (Object.keys(actions).join("|")));
    process.exit(1);
  }

  try {
    cfg = (require("js-yaml")).safeLoad(fs.readFileSync("about.yml", "utf-8"));
  } catch (_error) {
    e = _error;
    console.log("Could not find/read/parse \"about.yml\" in current directory.");
    process.exit(1);
  }

  if (!cfg.name) {
    throw "about.yml missing name";
  }

  if (cfg.title == null) {
    cfg.title = cfg.name;
  }

  if (cfg.repos == null) {
    cfg.repos = "" + process.env.USER + "/" + cfg.name;
  }

  if (cfg.src == null) {
    cfg.src = cfg.name + ".coffee";
  }

  if (cfg.author == null) {
    cfg.author = process.env.USER;
  }

  if (cfg.site == null) {
    cfg.site = "" + process.env.USER + ".username";
  }

  if (cfg.author === "rasmuserik") {
    cfg.author = "Rasmus Erik Voel Jensen (solsort.com)";
    cfg.site = "solsort.com";
  }

  actions.genpackage();

  actions.genbower();

  actions.gencoffee();

  actions.genhtml();

  actions[process.argv[2]]();

}).call(this);
