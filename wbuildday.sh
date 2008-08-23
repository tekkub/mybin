#! /bin/bash

startdir=$PWD
cd /e/Wrath\ of\ the\ Lich\ King\ Beta/Interface/AddOns

echo ""

for folder in `ls -d */.git`
do
	cd $folder/..
	mydir=`pwd | sed "s/.*\///"`

	if ! git-status | grep "nothing to commit (working directory clean)" > /dev/null
	then
		echo ""
		echo "---- $mydir has uncommitted changes ----"
	fi

	lasttag=`git-describe --tags --abbrev=0 HEAD`
	if [ $lasttag ]
	then
		revcount=0
		for commit in `git-rev-list --no-merges $lasttag..HEAD`
		do
			let "revcount += 1"
		done

		if (($revcount > 0))
		then
			echo ""
			echo "---- $mydir has had $revcount commits since tag $lasttag ----"
			git-log $lasttag..HEAD --no-merges --pretty=format:"%h (%cr) - %s" | cat
			echo ""
		fi
	else
		revcount=0
		for commit in `git-rev-list HEAD`
		do
			let "revcount += 1"
		done

		if (($revcount > 0))
		then
			echo ""
			echo "---- $mydir has $revcount commits ----"
			git-log HEAD --no-merges --pretty=format:"%h (%cr) - %s" | cat
			echo ""
		fi
	fi

	cd ..
done

cd "$startdir"
echo ""
exit 0
