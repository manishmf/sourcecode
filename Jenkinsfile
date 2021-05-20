pipeline {
    node {
            withCleanup {
                unstash 'source'
                withRvm('ruby-2.5.1') {
                    sh 'rvm use 2.5.1'
                    sh 'fastlane bootstrap'

                }
            }
        }

    stages {
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
