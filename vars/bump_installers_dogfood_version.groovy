def call(String version) {
  //Execute bash script, catch and print output and errors
  node('worker') {
    withCredentials([string(credentialsId: 'githubtoken', variable: 'GITHUB_TOKEN')]) {
      sh "curl -O https://raw.githubusercontent.com/puppetlabs/puppet_jenkins_shared_libraries/main/vars/bash/bump_dogfood_version.sh"
      sh "chmod +x bump_dogfood_version.sh"
      sh "bash bump_dogfood_version.sh $version"
    }
  }
}