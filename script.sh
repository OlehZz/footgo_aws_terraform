#!/bin/bash
cp /home/ubuntu/footgo/src/main/resources/application.properties.example /home/ubuntu/footgo/src/main/resources/application.properties
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
sed -i 's/spring.datasource.username=root/spring.datasource.username=footgo/g' /home/ubuntu/footgo/src/main/resources/application.properties
sed -i 's/spring.datasource.password=pwd/spring.datasource.password=footgodb/g' /home/ubuntu/footgo/src/main/resources/application.properties
sed -i 's/spring.datasource.url=jdbc:mysql:\/\/localhost/spring.datasource.url=jdbc:mysql:\/\/terraform-20200802200643446600000001.cnowmm0u4gtt.us-east-1.rds.amazonaws.com/g' /home/ubuntu/footgo/src/main/resources/application.properties
