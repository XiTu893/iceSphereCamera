# 第一阶段：Maven构建
FROM maven:3.8-openjdk-8 AS builder
WORKDIR /app
COPY pom.xml .
# 先下载依赖（利用Docker缓存层）
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

# 第二阶段：运行时
FROM openjdk:8-jre-slim
WORKDIR /app

# 安装OpenCV所需的系统库
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/*.jar app.jar

# 创建上传文件存储目录
RUN mkdir -p /app/uploads

EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE=prod

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --spring.profiles.active=$SPRING_PROFILES_ACTIVE"]
