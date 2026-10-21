pipeline {
    agent {
        label 'todo-docker'
    }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def source = checkout scm
                    env.IMAGE_TAG = "jenkins-${source.GIT_COMMIT}"
                }
            }
        }

        stage('Build backend') {
            steps {
                sh '''
                    docker build \
                      -t "tranchandong/todo-backend:$IMAGE_TAG" \
                      ./backend
                '''
            }
        }

        stage('Build frontend') {
            steps {
                sh '''
                    docker build \
                      -t "tranchandong/todo-frontend:$IMAGE_TAG" \
                      ./frontend
                '''
            }
        }

        stage('Push images') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set +x
                        set -eu

                        DOCKER_CONFIG=$(mktemp -d)
                        export DOCKER_CONFIG
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                        printf '%s' "$DOCKER_PASS" |
                          docker login \
                            --username "$DOCKER_USER" \
                            --password-stdin

                        docker push "tranchandong/todo-backend:$IMAGE_TAG"
                        docker push "tranchandong/todo-frontend:$IMAGE_TAG"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Images pushed with tag: ${env.IMAGE_TAG}"
        }
    }
}