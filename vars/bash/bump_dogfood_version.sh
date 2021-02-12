#!/bin/sh
## USAGE: ./bump_dogfood_version.sh

rm -rf ./ci-job-configs
git clone git@github.com:puppetlabs/ci-job-configs ./ci-job-configs
cd ci-job-configs || exit

readonly CJC_DOGFOOD_VERSION=$(sed -n "s/^    p_dogfooding_upgrade_from_rc_build: '\(.*\)'$/\1/gp" ./jenkii/enterprise/projects/pe-integration.yaml) # Example 2021.4.0-rc0
readonly PE_FAMILY='2021.0'
readonly LATEST_RELEASE_VERSION=$(curl -k https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/archives/internal/${PE_FAMILY}/LATEST)
readonly TEMP_BRANCH="auto/master/bumping_dogfood_build_to_${LATEST_RELEASE_VERSION}"

echo "CJC_DOGFOOD_VERSION=${CJC_DOGFOOD_VERSION}"
echo "LATEST_RELEASE_VERSION=${LATEST_RELEASE_VERSION}"

main() {
  git checkout -b "$TEMP_BRANCH"
  sed -i "/p_dogfooding_upgrade_from_rc_build:/c\    p_dogfooding_upgrade_from_rc_build: '${LATEST_RELEASE_VERSION}'" ./jenkii/enterprise/projects/pe-integration.yaml
  git add ./jenkii/enterprise/projects/pe-integration.yaml
  git commit -m "Installer team bump for dogfooding upgrade build to ${LATEST_RELEASE_VERSION}"

  echo 'Pushing changes to upstream...'
  git push origin "$TEMP_BRANCH"

  echo 'Creating PR...'
  PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
}

error_exit() {
  local msg=$1
  echo "$msg"
  exit 1
}

if [ "${CJC_DOGFOOD_VERSION}" = "${LATEST_RELEASE_VERSION}" ]; then
  echo 'Dogfood version is up to date'
  exit 0
else
  main || error_exit 'Release job creation failed'
  echo "Successfully Opened PR for $(pwd): ${PULL_REQUEST}"
fi
