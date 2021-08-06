def call(String version) {

  if (version =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)$') {
    println "${version} is a valid version"
  } else {
    println "${version} is an invalid version"
    throw new Exception("Invalid version")
  }
  //Execute bash script, catch and print output and errors
  node('k8s-worker') {
    withCredentials([string(credentialsId: 'githubtoken', variable: 'GITHUB_TOKEN')]) {
      writeFile file:'update_statusboard_for_release.sh', text:libraryResource('update_statusboard_for_release.sh')
      sh "chmod +x update_statusboard_for_release.sh"
      sh "bash update_statusboard_for_release.sh $version"
    }
  }
}
