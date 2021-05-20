pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'rvm use 2.5.1'
                sh 'fastlane bootstrap'
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
