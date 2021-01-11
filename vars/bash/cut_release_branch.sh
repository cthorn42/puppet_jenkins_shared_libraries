#USAGE: ./cut_release_branch.sh <version> <branch_from>

version=$1
branch_from=$2

rm -rf ./${GITHUB_PROJECT}
git clone git@github.com:puppetlabs/${GITHUB_PROJECT} ./${GITHUB_PROJECT}
cd ${GITHUB_PROJECT}

git ls-remote | grep "${version}"-release

if [[ ( "$?" == 0 ) ]]
then
  echo "${version}-release branch already exists. Exiting release creation."
  exit 1
fi

git checkout ${branch_from}
if [[ ("$?" == 0) ]]
then
  git checkout -b ${version}-release
  git push origin ${version}-release
else
  FAMILY=`echo ${version} | sed "s/\(.*\..*\)\..*/\1/"`

  git checkout ${FAMILY}.x
  git checkout -b ${version}-release
  git push origin ${version}-release
fi

cd ..
rm -rf ${GITHUB_PROJECT}
