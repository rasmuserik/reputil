#!/usr/bin/env coffee
#{{{1 Reputil
#
#{{{2 Versions 
#
# - 0.0.4 Making it work without coffee installed (ie. on ci-servers). Autocompile bugfix.
# - 0.0.3 Fix autocompile for multiple files. Make `reputil.coffee` the executable.
# - 0.0.2 `build` action which does all the usual stuff: compile, generate readme, etc.
# - 0.0.1 
#   - action: `genreadme` automatically generate README.md from package.json and literate coffeescript, 
#   - action: `autocompile` autorestart `coffee -wc`
#   - reputil own infrastructure: git-hook, npm prepublish build binary etc.
#
#{{{2 TODO
#
# - package.json
#   - call reputil from prepublish
#   - autoinclude reputil in devDependencies
# - bower.json
#   - autogen as much as possible from package.json, quit if bower.json is present, but misses data
# - git commit-hook npm prepublish
# - dist with increment version in package, tag, npm publish, bower publish 
#
#{{{1 about.yml content
#    
#     name: name-of-app                 # must be present, and must match name-of-app.coffee
#     title: Human readable app title
#     desc: description of the app
#     tags: [keyword1, foo, bar]
#     license: "MIT"
#     links:                            # used for entry in solsort.com
#       web_app: http://example.com/
#     date: 2014-03                     # for solsort.com, YYYY-MM-DD optionally omitting DD or MM
#     repos: github-user/repos-name     # defaults to $USER/$name
#     html:                             # if present generate index.html
#       body: <h1>hello</h1>
#       css:
#         - "foo/bar.css"
#       js:
#         - "foo/jquery.min.js"
#     phonegap:                         # if present, generate config.xml
#       orientation: landscape
#       fullscreen: true
#       splash: true
#       exitOnSuspend: true             # iOS 
#       androidVersion: 7
#       permissions: none
#       plugins:                        # full list on https://build.phonegap.com/plugins
#         - org.apache.cordova.camera
#     package:                          # extend package.json with this object
#       testling:                       # sample adding testling
#         html: test.html
#         browsers: 
#           - ie/7..latest
#           - chrome/27..canary
#           - firefox/22..nightly
#           - safari/5.0.5..latest
#           - opera/11.6..next
#           - iphone/6
#           - ipad/6
#           - android-browser/4.2
#     bower: {}                         # extend bower.json with this object
#
#{{{1 Actual implementation
#
# This is a quick hack...

#{{{2 globals
#
# Modules
fs = require "fs"
glob = require "glob"
child_process = require "child_process"

# package.json, and bower.json for the repository we are working on
pkg = undefined
cfg = undefined
bower = undefined

# action dispatch
actions = {}

#{{{2 util
deepExtend = (target, src) ->
  return if !src
  for key, val of src
    if typeof val == "object" && typeof target[key] == "object"
      deepExtend target[key], val
    else
      target[key] = val

exec = (cmd, fn) ->
  console.log "> #{cmd}"
  child = child_process.exec cmd
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr
  child.on "exit", (result) -> fn?(result)

#{{{2 build
actions.build = ->
  actions.compile()
  actions.genreadme()
  actions.genbower()
  actions.genconfigxml()
  actions.genManifestWebapp()

#{{{2 genpackage
actions.genpackage = ->
  try
    pkg = fs.readFileSync "package.json"
  catch e
    pkg = "{}"
  pkg = JSON.parse pkg
  pkg.version ?= "0.0.0"
  pkg.version = cfg.version if cfg.version
  pkg.name = cfg.name
  pkg.description = cfg.desc
  pkg.license = cfg.license
  pkg.keywords = cfg.tags
  pkg.authors = [cfg.author]
  pkg.repository =
    type: "git"
    url: "https://github.com/#{cfg.repos}.git"
  deepExtend pkg, cfg.package
  fs.writeFileSync "package.json", JSON.stringify(pkg, null, 2) + "\n"

#{{{2 genbower
actions.genbower = ->
  try
    bower = JSON.parse fs.readFileSync "bower.json"
  catch e
    bower = {}
  bower.name = pkg.name
  bower.version = pkg.version
  bower.description = pkg.description
  bower.license = pkg.license
  bower.keywords = pkg.keywords
  bower.authors = pkg.author
  bower.repository = pkg.repository
  deepExtend bower, cfg.bower
  fs.writeFileSync "bower.json", JSON.stringify(bower, null, 2) + "\n"

#{{{2 genManifestWebapp - for firefox marketplace
actions.genManifestWebapp = ->
  return if !cfg.phonegap

  exec "convert -resize 128x128 icon.png icon128.png"
  
  basedir = cfg.phonegap.basedir || "/#{cfg.name}/"
  webapp =
    version: cfg.version
    name: cfg.title
    description: cfg.desc
    launch_path: "#{basedir}index.html"
    icons:
      "512": "#{basedir}icon.png"
      "128": "#{basedir}icon128.png"
    developer:
      name: cfg.author
      url: "http://#{cfg.site}"
    appcache_path: "#{basedir}cache.manifest"

  webapp.orientation = [cfg.phonegap.orientation] if cfg.phonegap.orientation
  webapp.fullscreen = true if cfg.phonegap.fullscreen
  
  fs.writeFileSync "manifest.webapp", JSON.stringify webapp

#{{{2 genconfigxml - for cordova / phonegap
actions.genconfigxml = ->
  return if !cfg.phonegap
  fs.writeFileSync "config.xml", """
<?xml version="1.0" encoding="UTF-8"?>
<widget xmlns = "http://www.w3.org/ns/widgets"
        xmlns:gap = "http://phonegap.com/ns/1.0"
        id = "#{cfg.site.split(".").reverse().join(".")}.#{cfg.name}"
        version = "#{pkg.version}">

    <!-- AUTOGENERATED DO NOT EDIT -->

    <name>#{cfg.title}</name>
    <description>#{pkg.description}</description>
    <author href="http://#{cfg.site}" email="#{pkg.name}@#{cfg.site}">#{cfg.author}</author>
    <preference name="phonegap-version" value="3.3.0" />
    <preference name="orientation" value="#{cfg.phonegap.orientation || "default"}" />
    <preference name="target-device" value="universal" />
    <preference name="fullscreen" value="#{!!cfg.phonegap.fullscreen}" />
    <preference name="prerendered-icon" value="true" />
    <preference name="ios-statusbarstyle" value="black-opaque" />
    <preference name="detect-data-types" value="false" />
    <preference name="exit-on-suspend" value="#{!!cfg.phonegap.exitOnSuspend}" />
    <preference name="auto-hide-splash-screen" value="true" />
    <preference name="android-minSdkVersion" value="#{cfg.phonegap.androidVersion || 10}" />
    <preference name="android-installLocation" value="auto" />
    <preference name="permissions" value="#{cfg.phonegap.permissions || "none"}" />
    #{("    <gap:plugin name=\"#{plugin}\" />" for plugin in cfg.phonegap.plugins || []).join "\n"}
    <icon src="icon.png" />
    #{if cfg.phonegap.splash then '<gap:splash src="splash.png" />' else ""}
    <access origin="*" />
</widget>\n"""

#{{{2 genhtml
actions.genhtml = ->
  return if !cfg.html
  viewport = cfg.html.viewport || "width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=0"
  css = cfg.html.css || []
  js = cfg.html.js || []
  fnames = []

  for module, _ of bower.dependencies || {}
    if !(module in (cfg.html.exclude || []))
      moduleMain = (JSON.parse fs.readFileSync "bower_components/#{module}/bower.json").main
      moduleMain = [moduleMain] if !Array.isArray moduleMain
      for file in moduleMain
        fname = "bower_components/#{module}/#{file}"
        css.push fname if file.match /\.css$/
        js.push fname if file.match /\.js$/
        fnames.push fname
  fnames = fnames.concat cfg.files if cfg.files
  exec "git add -f #{fnames.join " "}"

  js.push cfg.src.replace /.coffee$/, ".js"
  fnames.push cfg.src.replace /.coffee$/, ".js"

  actualHtml = (opt) ->
    opt ?= {}
    """<!DOCTYPE html>
      <html#{if opt.manifest then ' manifest="cache.manifest"' else ""}>
      <!-- AUTOGENERATED DO NOT EDIT -->
      <head>
        <title>#{cfg.title}</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <meta name="HandheldFriendly" content="True">
        <meta name="viewport" content="#{viewport}">
        <meta name="format-detection" content="telephone=no">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black">
        <link rel="apple-touch-icon-precomposed" href="icon.png">
        <link rel="icon" type="image/png" href="icon.png">
        <link rel="shortcut icon" href="icon.png">
        \ #{("<link rel=\"stylesheet\" href=\"#{src}\">" for src in css).join "\n    "}
      </head>
      <body>
       \ #{cfg.html.body || ""}
       \ #{("<script src=\"#{src}\"></script>" for src in js).join "\n    "}
      </body>
    </html>\n"""

  fs.writeFileSync "index.html", actualHtml {manifest: true}
  fs.writeFileSync "dev.html", actualHtml {manifest: false}
  fs.writeFileSync "cache.manifest", "CACHE MANIFEST\n# #{new Date()}\n#{fnames.join "\n"}\n"

#{{{2 gencoffee
actions.gencoffee = ->
  return if fs.existsSync cfg.src
  fs.writeFileSync cfg.src, """
  \# {\{{1 Boilerplate
  \# predicates that can be optimised away by uglifyjs
  if typeof isNodeJs == "undefined" or typeof runTest == "undefined" then do ->
    root = if typeof window == "undefined" then global else window
    root.isNodeJs = (typeof process != "undefined") if typeof isNodeJs == "undefined"
    root.isWindow = (typeof window != "undefined") if typeof isWindow == "undefined"
    root.isPhoneGap = typeof document?.ondeviceready != "undefined" if typeof isPhoneGap == "undefined"
    root.runTest = (if isNodeJs then process.argv[2] == "test" else location.hash.slice(1) == "test") if typeof runTest == "undefined"

  \# use - require/window.global with non-require name to avoid being processed in firefox plugins
  use = if isNodeJs then ((module) -> require module) else ((module) -> window[module]) 
  \# execute main
  onReady = (fn) ->
    if isWindow
      if document.readystate != "complete" then fn() else setTimeout (-> onReady fn), 17 
  \# {\{{1 Actual code

  onReady ->
    console.log "HERE"
  \n"""

#{{{2 genreadme
actions.genreadme = ->
  source = fs.readFileSync cfg.src, "utf-8"
  readme = "# #{cfg.title} #{pkg.version}\n\n"

  readme += pkg.description || ""
  readme += "\n"

  if fs.existsSync ".travis.yml"
    readme += "[![ci](https://secure.travis-ci.org/#{cfg.repos}.png)](http://travis-ci.org/#{cfg.repos})\n\n"
  if cfg.testling
    readme += "[![browser support](https://ci.testling.com/#{cfg.repos}.png)](http://ci.testling.com/#{cfg.repos})\n\n"

  for line in source.split("\n")
    continue if line.trim() in ["#!/usr/bin/env coffee"]

    if (line.search /^\s*#/) == -1
      line = "    " + line
      isCode = true
    else
      line = line.replace /^\s*# ?/, ""
      line = line.replace new RegExp("(.*){{" + "{(\\d)(.*)"), (_, a, header, b) ->
        ("#" for i in [1..+header]).join("") + " " + (a + b).trim()
      isCode = false


    if isCode != prevWasCode
      readme += "\n"
    prevWasCode = isCode

    readme += line + "\n"

  readme += "\n----\n\nREADME.md autogenerated from `#{cfg.src}` "
  readme += "![solsort](https://ssl.solsort.com/_reputil_#{cfg.repos.replace "/", "_"}.png)\n"

  fs.writeFileSync "README.md", readme


#{{{2 autocompile
#
# When using vim, `coffee -wc` sometimes exit when new version is saved (due to vims way of saving). This action keeps running `coffee -wc` on the files in the directory.
#
actions.autocompile = ->
  spawnChild = (fname) ->
    cmd = "#{__dirname}/node_modules/.bin/coffee -wc #{fname}"
    console.log cmd
    child = child_process.exec cmd
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr
    child.on "exit", -> spawnChild fname
  spawnChild cfg.src


#{{{2 compile
#
actions.compile = ->
  child = child_process.exec "#{__dirname}/node_modules/.bin/coffee -c #{cfg.src}"
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

#{{{2 main dispatch
if !actions[process.argv[2]]
  console.log "usage: reputil #{Object.keys(actions).join "|"}"
  process.exit 1

#{{{3 about.yml
try
  cfg = (require "js-yaml").safeLoad fs.readFileSync "about.yml", "utf-8"
catch e
  console.log e
  console.log "Could not find/read/parse \"about.yml\" in current directory."
  process.exit 1
throw "about.yml missing name" if !cfg.name

cfg.title ?= cfg.name
cfg.repos ?= "#{process.env.USER}/#{cfg.name}"
cfg.src ?= cfg.name + ".coffee"
cfg.author ?= process.env.USER
cfg.site ?= "#{process.env.USER}.username"
if cfg.author == "rasmuserik"
  cfg.author = "Rasmus Erik Voel Jensen (solsort.com)"
  cfg.site= "solsort.com"


#{{{3 generate files
actions.genpackage()
actions.genbower()
actions.gencoffee()
actions.genhtml()

#{{{3 dispatch
actions[process.argv[2]]()
