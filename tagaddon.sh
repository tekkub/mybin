#! /bin/bash


if ! git-status | grep "nothing to commit (working directory clean)" > /dev/null
then
	echo "---- Cannot tag, you have uncommitted changes ----"
	exit 1
fi

if [ ! -f "README.textile" ]
then
	echo "---- No README.textile found ----"
	exit 1
fi

wrath="$1"
if [ "$wrath" == "--wrath" ]
then
	TOC="30000"
	VERTAG="3.0.1"
else
	TOC="20400"
	VERTAG="2.4.3"
fi

for toc in `/bin/find -name "*.toc"`
do
	sed "s/\(.*\)Interface: .*/\1Interface: $TOC/" $toc > newtoc
	mv newtoc $toc
	git-add $toc
	sleep 1
done

git commit -m "Updating TOC to $TOC"

lasttag=`git-describe --tags --abbrev=0 HEAD`
if [ $lasttag ]
then
	echo "Last tag: $lasttag"
	lastversion=`echo "$lasttag" | sed "s/\([0-9]*\).\([0-9]*\).\([0-9]*\).\(.*\)-.*/\4/"`
	VER=$(($lastversion + 1))
else
	echo "Cannot find last tags"
	VER=1
fi

echo "Quality? "
read -e QUAL

version="$VERTAG.$VER"
tagname="$version-$QUAL"

currentbranch=`sed "s/ref: refs\/heads\///" .git/HEAD`

addon=`pwd | sed "s/.*\///"`

touch changelog.txt
echo "$tagname" > thesechanges.txt
if [ $lasttag ]
then
	git-log $lasttag..$currentbranch --no-merges --pretty=medium >> thesechanges.txt
else
	git-log --no-merges --pretty=medium >> thesechanges.txt
fi
echo "" >> thesechanges.txt
cat changelog.txt >> thesechanges.txt
mv thesechanges.txt changelog.txt
scite changelog.txt
git-add changelog.txt
git-commit -m "Update changelog for $tagname"

git branch tagging
git checkout tagging

for toc in `/bin/find -name "*.toc"`
do
	sed "s/\(.*\)Version: .*/\1Version: $version/" $toc > newtoc
	mv newtoc $toc
	git-add $toc
	sleep 1
done

textile_to_wowi.rb > /c/Users/Tekkub/Desktop/$addon-$version-description.txt
git-rm README.textile

git commit -m "Weekly build $tagname"
git-tag -a -m "Weekly build" $tagname
git checkout $currentbranch
git branch -D tagging
git-merge -s ours $tagname

git-archive --format=zip --prefix=$addon/ -9 $tagname > /c/Users/Tekkub/Desktop/$addon-$version.zip
cp changelog.txt /c/Users/Tekkub/Desktop/$addon-$version-changelog.txt

echo "Pushing to origin"
git-push --tags origin $currentbranch

#~ echo ""
#~ echo "Uploading to Google Code"
#~ /C/Program\ Files/Python25/python /c/Users/Tekkub/bin/googlecode_upload.py -s "$addon-$version" -p "tekkub-wow" -l "Addon-$addon, Quality-$QUAL, TOC-$TOC" /c/Users/Tekkub/Desktop/$addon-$version.zip

echo ""
echo "Uploading to WoWI"
ruby /c/Users/Tekkub/bin/wowi_upload.rb $addon $tagname /c/Users/Tekkub/Desktop/$addon-$version.zip /c/Users/Tekkub/Desktop/$addon-$version-changelog.txt /c/Users/Tekkub/Desktop/$addon-$version-description.txt $wrath

exit 0
