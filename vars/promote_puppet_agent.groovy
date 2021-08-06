import com.puppet.jenkinsSharedLibraries.BundleInstall

def call(String version, String branch_from, String next_pe_version) {

  rubyVersion = "2.5.1"
  def setup_gems = new BundleInstall(rubyVersion)

  sh "${setup_gems.bundleInstall}"

  if (version =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)$') {
    println "${version} is a valid version"
  } else {
    println "${version} is an invalid version"
    throw new Exception("Invalid version")
  }
  //Execute bash script, catch and print output and errors
  node('k8s-worker') {
    writeFile file:'promote_puppet_agent.sh', text:libraryResource('promote_puppet_agent.sh')
    sh "bash promote_puppet_agent.sh $version $branch_from $next_pe_version"
  }
}
