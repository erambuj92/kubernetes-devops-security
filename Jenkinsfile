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
        }

    stage('Mutation Tests') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
        }

   stage('Sonarqube - SAST') {
            steps {
              withSonarQubeEnv('SonarQube') {
              sh '''
                  mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                  -Dsonar.projectKey=numeric-application \
                  -Dsonar.projectName='numeric-application' \
                  -Dsonar.host.url=http://devsecops.eastus.cloudapp.azure.com:9000
                  '''
              }
              timeout(time: 2, unit: 'MINUTES') {
                 script {
                   waitForQualityGate abortPipeline: true
                 }
              }
            }
        }   
    
    stage('Vulnerability Scan - Docker') {
            parallel {
                stage('Dependency Scan') {
                    steps {
                        sh 'mvn dependency-check:check'
                    }
                }
                stage('Trivy Scan') {
                    steps {
                        sh 'bash trivy-docker-image-scan.sh'
                    }
                }
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
    post {
            always {
              junit 'target/surefire-reports/*.xml'
              jacoco execPattern: 'target/jacoco.exec'
              script {
                  if (fileExists('target/pit-reports')) {
                      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                  } else {
                      echo 'PIT report directory not found. Skipping PIT publisher.'
                  }
              }
              // pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
            }
    }
    
    
}
