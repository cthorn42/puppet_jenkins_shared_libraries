package com.puppet.jenkinsSharedLibraries

import groovy.transform.InheritConstructors

class BeakerHostgenerator extends RvmEnvironment {
    String hostgeneratorScript
    BeakerHostgenerator(String rubyVersion,
                        String peDir,
                        String peVersion,
                        String platform,
                        String hypervisor,
                        String hostfile=null) {
        super(rubyVersion)
        pooling_api = (hypervisor == 'vmpooler') ? ',pooling_api=https://vmpooler-prod.k8s.infracore.puppet.net/api/v1' : ''
        String hostgeneratorString = "bundle exec beaker-hostgenerator ${platform} --hypervisor ${hypervisor}\
 --global-config '{forge_host=forge-aio01-petest.puppetlabs.com${pooling_api}}' --pe_dir ${peDir} --pe_ver ${peVersion} >&1 | tee ${hostfile}"
        this.hostgeneratorScript = this.rvmCommand + """
export BUNDLE_BIN=.bundle/bin
export BUNDLE_PATH=.bundle/gems
${hostgeneratorString}
"""
    }
}
