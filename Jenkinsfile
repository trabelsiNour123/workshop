pipeline {
	agent any

	environment {
		IMAGE_NAME = "ameniferjeni/projet_devops"
		IMAGE_TAG  = "latest"
	}

	//triggers {
	//	pollSCM('* * * * *')  // vérification chaque minute
	//}


	stages {

		stage('Checkout') {
			steps {
				echo "Récupération du code depuis GitHub..."
				git branch: 'main', url: 'https://github.com/ameniferjeni/pipline_projet.git'
			}
		}

		stage('Clean & Build') {
			steps {
				echo "Nettoyage + Build Maven..."
				sh 'mvn clean install -DskipTests -B'
			}
		}

		stage('Build Docker Image') {
			steps {
				echo "Construction de l'image Docker..."
				sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
			}
		}

		stage('Docker Login & Push') {
			steps {
				echo "Connexion + push vers DockerHub..."
				withCredentials([usernamePassword(credentialsId: '3ce804e0-ee34-42a2-b245-c75c40e801ac',
					usernameVariable: 'DOCKER_USER',
					passwordVariable: 'DOCKER_PASS')]) {
					sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    """
				}
			}
		}
	}


	post {
		always {
			echo "Pipeline terminé"
		}
		success {
			echo "Build et Push effectués avec succès!"
		}
		failure {
			echo "Le pipeline a échoué."
		}
	}
}

