# ===============================
# Étape 1 : Build de l'application avec Maven
# ===============================
FROM maven:3.9.9-eclipse-temurin-17-alpine AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier uniquement le pom.xml d'abord pour profiter du cache Docker
COPY pom.xml .

# Télécharger les dépendances (couche mise en cache si pom.xml inchangé)
RUN mvn dependency:go-offline -B

# Copier le code source
COPY src ./src

# Construire le JAR (skip tests + mode batch pour logs propres)
RUN mvn clean package -DskipTests -B

# ===============================
# Étape 2 : Image d'exécution ultra-légère
# ===============================
FROM eclipse-temurin:17-jre-alpine

# Définir le répertoire de travail
WORKDIR /app

# Créer un groupe et un utilisateur non-root pour la sécurité
RUN addgroup -S spring && adduser -S spring -G spring

# Copier le JAR avec les bons droits directement (pas besoin de chown supplémentaire)
COPY --from=build --chown=spring:spring /app/target/*.jar app.jar

# Passer à l'utilisateur non-root
USER spring:spring

# Exposer le port standard Spring Boot / Java
EXPOSE 8080

# Permettre l'injection d'options Java via variable d'environnement
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar /app/app.jar"]