#! /bin/bash

echo "New TOC number? "
read -e TOC

startdir=$PWD
cd /c/Users/Tekkub/Documents/-\ WoW\ Gits/

for folder in `ls -d */`
do
	cd $folder

	#~ echo "Pulling $folder"
	#~ git pull

	echo "Updating tocs in $folder"
	for toc in `find -name "*.toc"`
	do
		sed "s/\(.*\)Interface: .*/\1Interface: $TOC/" $toc > newtoc
		mv newtoc $toc
	done

	echo "Committing and pushing"
	git commit --all --message="Updating TOC to $TOC"
	git push
	cd ..
done

cd "$startdir"
exit 0
