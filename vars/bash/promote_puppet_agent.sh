#!/bin/bash
#USAGE: ./promote_puppet_agent.sh <version> <branch_from>

version=$1
branch_from=$2 
next_pe_version=${3:-}

if [[ $branch_from != "main" ]]; then
  exit 0
fi

source /usr/local/rvm/scripts/rvm
rvm use "2.5.1"
set -x

export BUNDLE_PATH=.bundle/gems
export BUNDLE_BIN=.bundle/bin
mkdir -p pkg

export SIGNING_SERVER=mozart.delivery.puppetlabs.net
export OSX_SIGNING_SSH_KEY=/home/jenkins/.ssh/id_signing
export GPG_KEY=7F438280EF8D349F
export IPS_SIGNING_SSH_KEY=/home/jenkins/.ssh/id_signing
export MSI_SIGNING_SSH_KEY=/home/jenkins/.ssh/id_signing
export MSI_SIGNING_SERVER=windowssigning-aio1-prod.delivery.puppetlabs.net

rm -rf ./${GITHUB_PROJECT}
git clone git@github.com:puppetlabs/${GITHUB_PROJECT} ./${GITHUB_PROJECT}
cd ${GITHUB_PROJECT}

git checkout main

PE_version_XY=$next_pe_version
if [[ -z $PE_version_XY ]] ; then 
  # Set PE_version_XY from enterprise-dist git describe
  # Get the X.Y version from the tag
  PE_version_XY=$(git describe | cut -d'.' -f 1-2)
fi 

filename_string=$(grep --max-count=1 '"filename": "puppet-agent-' packages.json)
suite_commit=$(echo $filename_string | cut -d'-' -f 3-3 )

if [[ $filename_string =~ g[a-zA-Z0-9]{8} ]] ; then
  short_sha=$(echo $filename_string | cut -d'.' -f 5-5 | cut -c 2-9)
  git clone git@github.com:puppetlabs/puppet-agent
  suite_commit=$(cd puppet-agent; git rev-parse $short_sha)
fi

: === Preparing internal ship
: === Retrieving artifacts

# Retrieve the artifacts to get at the params file ($suite_commit.yaml)
# suite_commit is the sha of the version of puppet_agent on enterprise/dist/main that is currently promoted in the main branch
vanagon_project_name=puppet-agent
/usr/bin/wget -r -np -nH --cut-dirs 3 -P pkg --reject 'index*' http://builds.delivery.puppetlabs.net/$vanagon_project_name/$suite_commit/artifacts/$suite_commit.yaml
if [[ ! -f pkg/$suite_commit.yaml ]] ; then
  : === "The params file is required to ship this build to the nightly repos. Please ensure that $suite_commit of $vanagon_project_name has finished building before this job is executed."
  exit 1
fi


# Now we use the yaml file to find the signing bundle, which we will use to run the rake tasks
pa_version=$(ruby -ryaml -e "puts YAML.load_file('pkg/$suite_commit.yaml')[:version]")
package=$(ruby -ryaml -e "puts YAML.load_file('pkg/$suite_commit.yaml')[:project]")
signing_bundle=$package-$pa_version-signing_bundle.tar.gz
/usr/bin/wget -r -np -nH --cut-dirs 3 -P pkg --reject 'index*' http://builds.delivery.puppetlabs.net/$vanagon_project_name/$suite_commit/artifacts/$signing_bundle
if [[ ! -f pkg/$signing_bundle ]] ; then
  : === "The signing bundle is required to ship this build to the nightly repos. Please ensure that $suite_commit of $vanagon_project_name has finished building before this job is executed."
  exit 1
fi

# Unpack the signing bundle
tar xf "pkg/$signing_bundle"

: === Cloning signing bundle
# Clone the bundle so we have somewhere to invoke rake tasks
git clone ${signing_bundle%%.tar.gz} $package-$pa_version

set -e

: === Executing internal agent ship

cd $package-$pa_version

major_agent_reported_version=$(echo $pa_version | cut -d '.' -f 1)
git_describe=$(git describe)
major_suite_version=$(echo $git_describe | cut -d '.' -f 1)

if [[ $major_agent_reported_version != $major_suite_version ]]; then
  agent_reported_version=$(echo $pa_version)
  commit_number=$(echo $git_describe | cut -d '-' -f 2)
  package_reported_version="$agent_reported_version-$commit_number"
  bundle update
  export PACKAGING_PACKAGE_VERSION="$package_reported_version"
fi

bundle install --path $BUNDLE_PATH --retry 3
bundle exec rake pl:jenkins:link_signed_repos[agent-downloads.delivery.puppetlabs.net,/opt/puppet-agent,version,$PE_version_XY] --trace
