FROM jenkins/jenkins
# if we want to install via apt
USER root
RUN apt-get update && apt-get install -y python build-essential libffi-dev python-dev python3-pip xmlstarlet
# drop back to the regular jenkins user - good practice
COPY --chown=jenkins:jenkins ./jenkins-master-slave/externals/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins