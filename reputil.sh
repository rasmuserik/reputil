#!/usr/bin/env bash
dir=`dirname $0`
if [ -e $dir/reputil.js ]; then
  /usr/bin/env node $dir/reputil.js "$@"
elif [ -e $dir/../reputil/reputil.js ]; then
  /usr/bin/env node $dir/../reputil/reputil.js "$@"
else
  /usr/bin/env node $dir/../lib/node_modules/reputil/reputil.js "$@"
fi
