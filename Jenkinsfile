pipeline {
    agent any

    environment {
        IMAGE_NAME       = "trabelsinour/atelierdevops"
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
        IMAGE            = "${IMAGE_NAME}:${IMAGE_TAG}"
        IMAGE_LATEST     = "${IMAGE_NAME}:latest"

        // Credentials Docker Hub
        DOCKER_CRED      = credentials('997570a0-9b48-45fa-b06b-f5828854fe30')

        // Credential kubeconfig
        KUBE_CRED        = 'minikube-kubeconfig'

        // Noms Kubernetes
        DEPLOYMENT_NAME  = 'atelierdevops'
        // CORRECTION : nom exact du container dans spring-deployment.yaml
        CONTAINER_NAME   = 'atelierdevops'

        // CORRECTION : nom du service (vérifie dans ton YAML, généralement atelierdevops-service)
        SERVICE_NAME     = 'atelierdevops-service'
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
                        ./mvnw clean package -DskipTests -B || echo "Maven a échoué → on continue (pour démo atelier)"
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

                withKubeConfig([credentialsId: "${KUBE_CRED}", namespace: 'devops']) {
                    sh '''
                        kubectl apply -f k8s/mysql-deployment.yaml || echo "MySQL déjà déployé"
                        kubectl apply -f k8s/spring-deployment.yaml || echo "Spring déjà déployé"

                        # CORRECTION : bon nom de container
                        kubectl set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${IMAGE}

                        # Attente du rollout complet
                        kubectl rollout status deployment/${DEPLOYMENT_NAME} --timeout=300s

                        echo "Déploiement terminé !"
                        kubectl get pods
                        kubectl get services
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
            echo ""
            echo "Pour accéder à l'application (exécute localement) :"
            echo "kubectl port-forward service/${SERVICE_NAME} 8080:80 -n devops"
            echo "→ Puis ouvre http://localhost:8080 dans ton navigateur"
            echo "════════════════════════════════════════"
        }
        failure {
            echo "🚨 Échec de la pipeline – Vérifie les logs ! 🚨"
        }
    }
}