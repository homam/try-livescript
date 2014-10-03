./build.sh
mkdir -p temp
cp index.html temp/
cp try-livescript.css temp/
cp try-livescript.js temp/

git checkout gh-pages
cp -f temp .

git add .
git commit
