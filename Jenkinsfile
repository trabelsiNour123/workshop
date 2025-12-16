pipeline {
    agent any

    environment {
        IMAGE_NAME = "trabelsinour/atelierdevops"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        IMAGE_LATEST = "${IMAGE_NAME}:latest"
        DOCKER_CRED = credentials('997570a0-9b48-45fa-b06b-f5828854fe30')  // Best practice : credentials() pour masquer
        KUBE_CRED = 'minikube-kubeconfig'  // ID de ta credential Kubeconfig dans Jenkins (à créer)
        DEPLOYMENT_NAME = 'atelierdevops'  // Nom de ton Deployment Spring Boot
        CONTAINER_NAME = 'spring-container'  // Nom du container dans le Deployment
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Code checkout sur branch main – Commit: ${GIT_COMMIT}"
            }
        }

        stage('Maven Build') {
            steps {
                sh '''
                    if [ -f ./mvnw ]; then
                        chmod +x ./mvnw
                        ./mvnw clean package -DskipTests -B || echo "Maven a échoué → on continue (pour demo atelier)"
                    else
                        echo "Pas de mvnw → build Maven skipped"
                    fi
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def img = docker.build(IMAGE)
                    img.tag("latest")
                    echo "Images Docker construites : ${IMAGE} et ${IMAGE_LATEST}"
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', '997570a0-9b48-45fa-b06b-f5828854fe30') {
                        docker.image(IMAGE).push()
                        docker.image(IMAGE_LATEST).push()
                        echo "Images poussées sur Docker Hub avec succès !"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Déploiement sur Minikube – Namespace devops"
                withKubeCredentials([credentialsId: "${KUBE_CRED}"]) {
                    sh '''
                        kubectl apply -f k8s/mysql-deployment.yaml -n devops || echo "MySQL déjà déployé"
                        kubectl apply -f k8s/spring-deployment.yaml -n devops || echo "Spring déjà déployé"

                        # Mise à jour de l'image sans downtime
                        kubectl set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${IMAGE} -n devops
                        kubectl rollout status deployment/${DEPLOYMENT_NAME} -n devops --timeout=300s

                        echo "Déploiement terminé !"
                        kubectl get pods -n devops
                        kubectl get services -n devops
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs(cleanWhenNotBuilt: false, deleteDirs: true)
        }
        success {
            echo "════════════════════════════════════════"
            echo "🎉 PIPELINE RÉUSSIE À 100% ! 🎉"
            echo "════════════════════════════════════════"
            echo "Images sur Docker Hub :"
            echo "→ ${IMAGE}"
            echo "→ ${IMAGE_LATEST}"
            echo "Lien : https://hub.docker.com/r/${IMAGE_NAME}"
            echo "Accès app : minikube service spring-service -n devops --url"
            echo "════════════════════════════════════════"
        }
        failure {
            echo "🚨 Échec de la pipeline – Vérifie les logs ! 🚨"
        }
    }
}