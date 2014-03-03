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
#{{{1 Actual implementation
#
# This is a quick hack...

#{{{2 globals
#
# Modules
fs = require "fs"
glob = require "glob"
child_process = require "child_process"

# List of source files
sourceFiles = glob.sync "*.coffee"

# package.json, and bower.json for the repository we are working on
pkg = undefined
bower = undefined

# action dispatch
actions = {}

#{{{2 build

actions.build = ->
  actions.compile()
  actions.genreadme()
  actions.genbower()
  actions.genconfigxml()

#{{{2 genbower
actions.genbower = ->
  bower.name = pkg.name
  bower.version = pkg.version
  bower.description = pkg.description
  bower.license = pkg.license
  bower.keywords = pkg.keywords
  bower.authors = pkg.author
  bower.repository = pkg.repository
  fs.writeFileSync "bower.json", JSON.stringify(bower, null, 2) + "\n"

#{{{2 genconfigxml
actions.genconfigxml = ->
  return if !pkg.phonegap
  fs.writeFileSync "config.xml", """
<?xml version="1.0" encoding="UTF-8"?>
<!-- AUTOGENERATED FROM package.json -->
<!-- DO NOT EDIT -->
<widget xmlns = "http://www.w3.org/ns/widgets"
        xmlns:gap = "http://phonegap.com/ns/1.0"
        id = "com.solsort.#{pkg.name}"
        version = "#{pkg.version}">

    <name>#{pkg.title || pkg.name}</name>
    <description>#{pkg.description}</description>
    <author href="http://solsort.com" email="#{pkg.name}@solsort.com">solsort.com</author>
    <preference name="phonegap-version" value="3.3.0" />
    <preference name="orientation" value="#{pkg.phonegap.orientation || "default"}" />
    <preference name="target-device" value="universal" />
    <preference name="fullscreen" value="#{!!pkg.phonegap.fullscreen}" />
    <preference name="prerendered-icon" value="true" />
    <preference name="ios-statusbarstyle" value="black-opaque" />
    <preference name="detect-data-types" value="false" />
    <preference name="exit-on-suspend" value="#{!!pkg.phonegap.exitOnSuspend}" />
    <preference name="auto-hide-splash-screen" value="true" />
    <preference name="android-minSdkVersion" value="#{pkg.phonegap.androidVersion || 10}" />
    <preference name="android-installLocation" value="auto" />
    <preference name="permissions" value="#{pkg.phonegap.permissions || "none"}"/>
    #{("    <gap:plugin name=\"#{plugin}\" />" for plugin in pkg.phonegap.plugins || []).join "\n"}
    <icon src="icon.png" />
    #{if pkg.phonegap.splash then '<gap:splash src="splash.png" />' else ""}
    <access origin="*" />
</widget>
"""

#{{{2 genreadme
actions.genreadme = ->
  source = (fs.readFileSync file for file in sourceFiles).join "\n"
  readme = "# #{pkg.name} #{pkg.version}\n\n"
  reposPath = pkg.repository?.url?.match(/https:\/\/github.com\/([^/]*\/[^/]*).git$/)?[1]
  if not reposPath
    console.log '"repository":{"url":"https://github.com/???/???.git",...} missing in package.json'
    process.exit 1

  readme += pkg.description || ""
  readme += "\n"

  if fs.existsSync ".travis.yml"
    readme += "[![ci](https://secure.travis-ci.org/#{reposPath}.png)](http://travis-ci.org/#{reposPath})\n\n"
  if pkg.testling
    readme += "[![browser support](https://ci.testling.com/#{reposPath}.png)](http://ci.testling.com/#{reposPath})\n\n"

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

  readme += "\n----\n\nREADME.md autogenerated from `#{sourceFiles.join "`, `"}` "
  readme += "![solsort](https://ssl.solsort.com/_reputil_#{reposPath.replace "/", "_"}.png)\n"

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
  spawnChild fname for fname in sourceFiles


#{{{2 compile
#
actions.compile = ->
  child = child_process.exec "#{__dirname}/node_modules/.bin/coffee -c #{sourceFiles.join " "}"
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

#{{{2 main dispatch
if !actions[process.argv[2]]
  console.log "usage: reputil #{Object.keys(actions).join "|"}"
  process.exit 1

try
  pkg = JSON.parse fs.readFileSync "package.json"
catch e
  console.log "Could not find/read/parse \"package.json\" in current directory."
  process.exit 1

try
  bower = JSON.parse fs.readFileSync "bower.json"
catch e
  bower = {}

actions[process.argv[2]]()
