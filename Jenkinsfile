pipeline {
  agent any 
  stages {
    stage('Execute shell') {
      steps {
        sh "chmod +x -R ${env.WORKSPACE}"
        sh "test.sh"
      }
    }
  }
}
