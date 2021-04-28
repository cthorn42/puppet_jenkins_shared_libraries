def call(String version, String branch_from) {

  if (version =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)$') {
    println "${version} is a valid version"
  } else {
    println "${version} is an invalid version"
    throw new Exception("Invalid version")
  }
  //Execute bash script, catch and print output and errors
  node('worker') {
    writeFile file:'cut_release_branch.sh', text:libraryResource('cut_release_branch.sh')
    sh "chmod +x cut_release_branch.sh"
    sh "bash cut_release_branch.sh $version $branch_from"
  }
}
