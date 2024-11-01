FROM openjdk:8-jdk

ENV JAVA_FX_VERSION 11.0.2
ENV JAVA_FX_SDK /opt/javafx-sdk

RUN apt-get update && apt-get install -y wget 
RUN wget https://download2.gluonhq.com/openjfx/11.0.2/openjfx-11.0.2_linux-x64_bin-sdk.zip
RUN wget https://github.com/janmotl/linkifier/files/8103473/linkifier.zip
RUN wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
RUN unzip linkifier.zip
RUN unzip openjfx-11.0.2_linux-x64_bin-sdk.zip
RUN rm linkifier.zip
RUN rm openjfx-11.0.2_linux-x64_bin-sdk.zip
RUN mv /postgresql-42.7.4.jar /linkifier/lib/postgresql-9.4.1212.jar

WORKDIR /linkifier

RUN rm connection.properties

CMD ["java", "-cp", "./linkifier-3.2.9.jar", "main.CLI"]