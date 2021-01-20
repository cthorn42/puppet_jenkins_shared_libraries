import com.puppet.jenkinsSharedLibraries.BeakerHostgenerator
import com.puppet.jenkinsSharedLibraries.Beaker
import com.puppet.jenkinsSharedLibraries.BundleInstall
import com.puppet.jenkinsSharedLibraries.BundleExec

def call(String rubyVersion, String platform, String peFamily) {
    def setup_gems = new BundleInstall(rubyVersion)
    def bundle_exec = new BundleExec(rubyVersion, 'rake gettext:build_mo[ja]')

    def pe_version = sh (
            script: "redis-cli -h redis.delivery.puppetlabs.net get ${peFamily}_pe_version",
            returnStdout: true
    ).trim()

    sh "${setup_gems.bundleInstall}"
    sh "${bundle_exec.bundleExec}"

    def acceptance_gems = new BundleInstall(rubyVersion)
    def generate_beaker_hosts = new BeakerHostgenerator(rubyVersion, "https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/${peFamily}/ci-ready", pe_version, platform, 'vmpooler', 'hosts.cfg')
    def run_beaker = new Beaker(rubyVersion, '--xml --debug --root-keys --repo-proxy --hosts hosts.cfg --type pe --keyfile /var/lib/jenkins/.ssh/id_rsa-acceptance --tests tests --preserve-hosts never --pre-suite pre-suite')

    sh """#!/bin/bash
cd acceptance/ && ${acceptance_gems.bundleInstall}"""
    sh """#!/bin/bash
cd acceptance/ && ${generate_beaker_hosts.hostgeneratorScript}
"""
    sh """#!/bin/bash
cd acceptance/ && ${run_beaker.beakerScript}
"""
}
