def call(String version, String codename, String hour) {

  if (version =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)$') {
    println "${version} is a valid version"
  } else {
    println "${version} is an invalid version"
    throw new Exception("Invalid version")
  }
  if (hour =~ '^[0-9]?[0-9]$') {
    println "${hour} is a valid time"
  } else {
    println "${hour} is an invalid time"
    throw new Exception("Invalid hour")
  }
  //Execute bash script, catch and print output and errors
  node('worker') {
    withCredentials([string(credentialsId: 'githubtoken', variable: 'GITHUB_TOKEN')]) {
      writeFile file:'installer_team_release_creation_job.sh', text:libraryResource('installer_team_release_creation_job.sh')
      sh "chmod +x installer_team_release_creation_job.sh"
      sh "bash installer_team_release_creation_job.sh $version $codename $hour"
    }
  }
}
