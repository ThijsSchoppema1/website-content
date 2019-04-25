# #!/usr/bin/env bash

# Break build on error, prevents websites going offline in case of pelican errors
set -e

# Optimize the images before building the website`
cd imgoptim
echo "Starting image optimization script"
node optimize.js

ls -al optimized_images

echo "Commit new images to repository"
git config --global user.email "webteamdiag@gmail.com"
git config --global user.name "DIAGWebTeam"

git checkout master

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
# if git diff --quiet; then
#     echo "No changes to the output on this push."
# else
git add -A ./optimized_images
git commit --message "Adding optimized images to repository. [ci skip]"
git remote add origin https://${GH_TOKEN}@github.com/diagnijmegen/website-content.git
git push origin master
# fi
cd ..

# List of websites to build
declare -a websites=("website-pathology" "website-rse" "website-retina")

# Distribute the content pages
python parse_content.py

for website in "${websites[@]}"
do
  echo "Building $website"

  # Copy default base pages
  cp -r content/pages/defaults/. $website/content/pages/
  # Copy images
  cp -r --no-clobber content/images $website/content
  # Copy bib generator script
  cp -r plugins/bibtex $website/plugins
  cp plugins/bib_writer.py $website/plugins/bib_writer.py

  # Copy literature
  cp content/diag.bib $website/content/diag.bib

  cd $website
  pwd

  # Generate publications
  python plugins/bib_writer.py

  # Build pelican website
  pelican content -s publishconf.py

  # Copy files for github
  #cp CNAME output/CNAME
  cp README.md output/README.md
  # Go back to root directory
  cd ..
done
