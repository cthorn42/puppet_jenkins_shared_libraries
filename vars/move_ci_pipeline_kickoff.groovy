def call(String branch, String hour) {

  node('k8s-worker') {
    withCredentials([string(credentialsId: 'githubtoken', variable: 'GITHUB_TOKEN')]) {
      writeFile file:'move_ci_pipeline_kickoff.sh', text:libraryResource('move_ci_pipeline_kickoff.sh')
      sh "chmod +x move_ci_pipeline_kickoff.sh"
      sh "bash move_ci_pipeline_kickoff.sh $branch $hour"
    }
  }
}