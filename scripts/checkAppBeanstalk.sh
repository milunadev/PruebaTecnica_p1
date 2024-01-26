#!/bin/bash

# Declarando variables
APP_NAME=$1
ENV_NAME=$2
INSTANCE_PROFILE=$3
REGION=$4
BUCKET_NAME=$5

SECURITY_GROUP_NAME="FlaskHTTPSecurityGroup"

# Verificar si el grupo de seguridad ya existe
GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$SECURITY_GROUP_NAME --query 'SecurityGroups[*].GroupId' --output text --region $REGION)

if [ -z "$GROUP_ID" ]; then
    echo "El grupo de seguridad no existe. Creando grupo: $SECURITY_GROUP_NAME"
    GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Grupo de seguridad para permitir trafico en el puerto 80" --query 'GroupId' --output text --region $REGION)
    # Agregando regla inbound HTTP
    aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
else
    echo "El grupo de seguridad ya existe: $SECURITY_GROUP_NAME"
fi

## VALIDAR APP BEANSTALK ##
if ! aws elasticbeanstalk describe-applications --application-names $APP_NAME --region $REGION | grep -q $APP_NAME; 
then
  echo "Creando aplicación: $APP_NAME"
  aws elasticbeanstalk create-application --application-name $APP_NAME --region $REGION
  ## Crear una nueva versión de la aplicación ##
  aws elasticbeanstalk create-application-version --application-name $APP_NAME --version-label "v0" --source-bundle S3Bucket=$BUCKET_NAME,S3Key=artifact.zip --region $REGION
else
    echo "La aplicacion $APP_NAME ya existe en beanstalk."
fi

## VALIDAR ENVIRONMENT BEANSTALK ##
if ! aws elasticbeanstalk describe-environments --application-name $APP_NAME --environment-names $ENV_NAME --region $REGION | grep -q $ENV_NAME; 
then
    echo "Creando entorno: $ENV_NAME"
    aws elasticbeanstalk create-environment --application-name $APP_NAME --environment-name $ENV_NAME --version-label "v0" --solution-stack-name "64bit Amazon Linux 2 v3.5.10 running Python 3.8" --option-settings Namespace=aws:autoscaling:launchconfiguration,OptionName=SecurityGroups,Value=$SECURITY_GROUP_NAME --region $REGION --option-settings Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value=$INSTANCE_PROFILE
else
    echo "El ambiente $ENV_NAME ya existe en beanstalk."
fi

## VALIDAR EL ESTADO DEL AMBIENTE 
while true; do
    STATUS=$(aws elasticbeanstalk describe-environments --application-name $APP_NAME --environment-names $ENV_NAME --region $REGION --query 'Environments[0].Status' --output text)
    if [ "$STATUS" == "Ready" ]; then
        echo "El entorno está listo para la actualización."
        break
    else
        echo "Esperando que el entorno esté listo... (Estado actual: $STATUS)"
        sleep 30
    fi
done

echo "Script finalizado"