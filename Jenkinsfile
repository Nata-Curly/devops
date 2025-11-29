pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--sleep"]
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
      - cat
    tty: true
  volumes:
    - name: kaniko-secret
      secret:
        secretName: kaniko-secret
'''
    }
  }
  environment {
    AWS_REGION = 'eu-central-1'
    ECR_REPO = '' // will be provided via parameters or credentials
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build & Push image (Kaniko)') {
      steps {
        container('kaniko') {
          sh '''
/kaniko/executor \
  --context $WORKSPACE \
  --dockerfile $WORKSPACE/Dockerfile \
  --destination $ECR_REPO:${GIT_COMMIT} \
  --insecure-registry=false \
  --skip-tls-verify=false
'''
        }
      }
    }
    stage('Update values.yaml in helm repo and push') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'GIT_CREDENTIALS', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
            sh '''
chmod +x ./scripts/update_values.sh
./scripts/update_values.sh "https://$GIT_USER:$GIT_PASS@github.com/your-org/your-django-helm-repo.git" "$ECR_REPO:${GIT_COMMIT}"
'''
          }
        }
      }
    }
  }
  post {
    success {
      echo 'Build and push succeeded.'
    }
    failure {
      echo 'Build failed.'
    }
  }
}
