#!/bin/sh

# This mechanism could offer simple variations on the build.
# Features could be productively grouped for smaller file size
# eg: I/O, Affine Transforms, Bitmap Operations, Gamma Curves, and Layers
# Initial Build includes everything except file IO, which is browser-incompatible
cd ${0%/*}
export PATH=$(npm bin):$PATH
echo "Browserifying browser/jimp.js..."
ENVIRONMENT=BROWSER \
browserify -t envify -t [ babelify --presets es2015 ] ../index.js > tmp.js
echo "Translating for ES5..."


# A TRUE hack. Use strict at the top seems to cause problems for ie10 interpreting this line from bmp-js:
# https://github.com/shaozilee/bmp-js/blob/master/lib/decoder.js
# module.exports = decode = function(bmpData) { ...
# For some reason, babeljs misses this "error" but IE can parse the code fine without strict mode.
echo "Removing Strict Mode."
sed "s/^\"use strict\";//; s/ret = Z_BUF_ERROR;//" tmp.js > tmp-nostrict.js

echo "Adding Web Worker wrapper functions..."
cat tmp-nostrict.js src/jimp-wrapper.js > tmp.jimp.js
echo "Minifying browser/jimp.min.js..."
uglifyjs tmp.jimp.js --compress warnings=false --mangle -o tmp.jimp.min.js

echo "Including the License and version number in the jimp.js and jimp.min.js"
PACKAGE_VERSION=$(cat ../package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g')
{ echo "/*";
echo "Jimp v$PACKAGE_VERSION";
echo "https://github.com/oliver-moran/jimp";
echo "Ported for the Web by Phil Seaton";
echo "";
cat ../LICENSE;
echo "*/";
echo ""; } > tmp.web_license.txt

cat tmp.web_license.txt tmp.jimp.js > lib/jimp.js
cat tmp.web_license.txt tmp.jimp.min.js > lib/jimp.min.js

echo "Cleaning up...."
rm tmp*