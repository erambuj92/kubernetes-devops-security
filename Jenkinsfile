pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
        }   
        stage('Unit Tests') {
            steps {
              sh "mvn test"
            }
          post {
            always {
              junit 'target/surefire-reports/*.xml'
              jacoco execPattern: 'target/jacoco.exec'
            }
          }
        }

    stage('Check PIT Classes') {
    steps {
        sh '''
            echo "=== Compiled classes ==="
            find target/classes -type f -name "*.class"

            echo "=== Test classes ==="
            find target/test-classes -type f -name "*.class"
        '''
    }
}

    stage('PIT Mutation Testing') {
            steps {
                sh 'mvn org.pitest:pitest-maven:mutationCoverage'
            }
        }

    stage('Publish PIT Report') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'target/pit-reports',
                    reportFiles: 'index.html',
                    reportName: 'PIT Mutation Testing Report'
                ])
            }
        }
    
    stage('Docker Build and push') {
            steps {
              withDockerRegistry([credentialsId:"docker-hub",url: ""]) {
                sh 'printenv'
                sh 'docker build -t erambuj92/numeric-app:""$GIT_COMMIT"" .'
                sh 'docker push erambuj92/numeric-app:""$GIT_COMMIT""'
              }
            }
        }

    stage('Kubernetes Deployment - DEV') {
          steps {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                  sh "sed -i 's#replace#erambuj92/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                  sh "kubectl apply -f k8s_deployment_service.yaml"
              }
          }
      }

    
    }
}
