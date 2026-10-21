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

        stage('Deploy') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'todo-server-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        set +x
                        set -eu

                        remote() {
                            ssh -i "$SSH_KEY" \
                              -o IdentitiesOnly=yes \
                              -o BatchMode=yes \
                              -o StrictHostKeyChecking=yes \
                              -o UserKnownHostsFile=scripts/known_hosts \
                              "$SSH_USER@127.0.0.1" "$@"
                        }

                        remote "mkdir -p /opt/todo-app/releases/$IMAGE_TAG"

                        scp -i "$SSH_KEY" \
                          -o IdentitiesOnly=yes \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o UserKnownHostsFile=scripts/known_hosts \
                          docker-compose.prod.yml \
                          "$SSH_USER@127.0.0.1:/opt/todo-app/releases/$IMAGE_TAG/docker-compose.prod.yml"

                        remote "bash -s -- '$IMAGE_TAG'" < scripts/deploy.sh

                        curl --fail --silent --show-error \
                          --retry 5 --retry-delay 5 --retry-all-errors \
                          --connect-timeout 5 --max-time 15 \
                          https://todo.dongtran.dev/ > /dev/null
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