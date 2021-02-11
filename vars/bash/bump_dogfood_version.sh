#USAGE: ./bump_dogfood_version.sh <version>

readonly VERSION=$1 # PE build we're testing upgrades from in the dogfood job, examle: 2021.0.0-rc5-94-g6b3daba
readonly TEMP_BRANCH="auto/master/bumping_dogfood_build_to_${VERSION}"

main() {
  rm -rf ./ci-job-configs
  git clone git@github.com:puppetlabs/ci-job-configs ./ci-job-configs
  cd ci-job-configs

  git checkout -b $TEMP_BRANCH
  sed -i "/p_dogfooding_upgrade_from_rc_build:/c\    p_dogfooding_upgrade_from_rc_build: '${VERSION}'" ./jenkii/enterprise/projects/pe-integration.yaml
  git add ./jenkii/enterprise/projects/pe-integration.yaml
  git commit -m "Installer team bump for dogfooding upgrade build to ${VERSION}"

  echo 'Pushing changes to upstream...'
  git push origin $TEMP_BRANCH

  echo 'Creating PR...'
  PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
}

error_exit() {
  local msg=$1
  echo $msg
  exit 1
}
main || error_exit 'Release job creation failed'
echo "Successfully Opened PR for $(pwd): ${PULL_REQUEST}"
