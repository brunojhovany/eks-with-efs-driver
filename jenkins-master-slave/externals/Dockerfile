FROM python:3.9-alpine3.16
# update and install build-essentials
RUN apk update && apk add --no-cache build-base && apk add --update alpine-sdk

# install aditional tools for run bootstrap script for admin user
RUN apk add bash libffi-dev xmlstarlet 

WORKDIR /usr/src/app

COPY jenkins-master-slave/externals/jenkins.sh .

RUN pip install bcrypt

CMD ["bash", "-c", "jenkins.sh"]