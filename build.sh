#!/bin/sh
mkdir -p libs
curl -L "https://raw.githubusercontent.com/chrisdone/jquery-console/master/jquery.console.js" > libs/jquery.console.js
curl -L "http://www.preludels.com/prelude-browser.js" > libs/prelude.js
curl -L "https://raw.githubusercontent.com/gkz/LiveScript/master/browser/livescript.js" > libs/livescript.js

stylus *.styl
lsc -c *.ls
