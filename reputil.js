// Generated by CoffeeScript 1.6.3
(function() {
  var actions, bower, child_process, e, fs, glob, pkg, sourceFiles;

  fs = require("fs");

  glob = require("glob");

  child_process = require("child_process");

  sourceFiles = glob.sync("*.coffee");

  pkg = void 0;

  bower = void 0;

  actions = {};

  actions.build = function() {
    actions.compile();
    actions.genreadme();
    return actions.genbower();
  };

  actions.genbower = function() {
    if (bower.name == null) {
      bower.name = pkg.name;
    }
    bower.version = pkg.version;
    return fs.writeFileSync("bower.json", JSON.stringify(bower, null, 2) + "\n");
  };

  actions.genreadme = function() {
    var file, isCode, line, prevWasCode, readme, reposPath, source, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4;
    source = ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = sourceFiles.length; _i < _len; _i++) {
        file = sourceFiles[_i];
        _results.push(fs.readFileSync(file));
      }
      return _results;
    })()).join("\n");
    readme = "# " + pkg.name + " " + pkg.version + "\n\n";
    reposPath = (_ref = pkg.repository) != null ? (_ref1 = _ref.url) != null ? (_ref2 = _ref1.match(/https:\/\/github.com\/([^/]*\/[^/]*).git$/)) != null ? _ref2[1] : void 0 : void 0 : void 0;
    if (!reposPath) {
      console.log('"repository":{"url":"https://github.com/???/???.git",...} missing in package.json');
      process.exit(1);
    }
    readme += pkg.description || "";
    if (fs.existsSync(".travis.yml")) {
      readme += "![ci](https://secure.travis-ci.org/" + reposPath + ".png)\n";
    }
    if (pkg.testling) {
      readme += "![browser support](https://ci.testling.com/" + reposPath + ".png)\n";
    }
    _ref3 = source.split("\n");
    for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
      line = _ref3[_i];
      if ((_ref4 = line.trim()) === "#!/usr/bin/env coffee") {
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
    readme += "\n----\n\nREADME.md autogenerated from `" + (sourceFiles.join("`, `")) + "` ";
    readme += "![solsort](https://ssl.solsort.com/_reputil_" + (reposPath.replace("/", "_")) + ".png)\n";
    return fs.writeFileSync("README.md", readme);
  };

  actions.autocompile = function() {
    var fname, spawnChild, _i, _len, _results;
    spawnChild = function(fname) {
      var child, cmd;
      cmd = "coffee -wc " + fname;
      console.log(cmd);
      child = child_process.exec(cmd);
      child.stdout.pipe(process.stdout);
      child.stderr.pipe(process.stderr);
      return child.on("exit", spawnChild(fname));
    };
    _results = [];
    for (_i = 0, _len = sourceFiles.length; _i < _len; _i++) {
      fname = sourceFiles[_i];
      _results.push(spawnChild(fname));
    }
    return _results;
  };

  actions.compile = function() {
    var child;
    child = child_process.exec("coffee -c " + (sourceFiles.join(" ")));
    child.stdout.pipe(process.stdout);
    return child.stderr.pipe(process.stderr);
  };

  if (!actions[process.argv[2]]) {
    console.log("usage: reputil " + (Object.keys(actions).join("|")));
    process.exit(1);
  }

  try {
    pkg = JSON.parse(fs.readFileSync("package.json"));
  } catch (_error) {
    e = _error;
    console.log("Could not find/read/parse \"package.json\" in current directory.");
    process.exit(1);
  }

  try {
    bower = JSON.parse(fs.readFileSync("bower.json"));
  } catch (_error) {
    e = _error;
    bower = {};
  }

  actions[process.argv[2]]();

}).call(this);
