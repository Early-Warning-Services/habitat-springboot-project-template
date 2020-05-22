# Base Plan variables
pkg_name=%APP_NAME%
pkg_origin=%PKG_ORIGIN%
# USER_NAME and USER_EMAIL are Bamboo variables supplied at build run time
pkg_maintainer="%USER_NAME% <%USER_EMAIL%>"
pkg_license=("Apache-2.0")
# APP_NAME is a Bamboo variable supplied at build run time
pkg_description="%APP_NAME% short description here."
pkg_deps=(core/jre8)
pkg_build_deps=(core/jdk8 core/maven)
pkg_svc_user="hab"
pkg_svc_group=$pkg_svc_user
# Application Ports
pkg_exports=(
  [port]=server.port
)
pkg_exposes=(port)
export SSL_CERT_FILE=/src/certs/ssl-certificate.crt
# Package versioning from pom.xml
pkg_version() {
  cat /src/pom.xml | grep "^    <version>.*</version>$" | awk -F'[><]' '{print $3}'
}
# Make sure to update package versioning from pom.xml before starting
do_before() {
  do_default_before
  update_pkg_version
  echo $pkg_version " is the calculated determined version"
}
# Prepare the build env with JAVA_HOME, m2 location, repo configuration, and artifactory certs/jssecacerts
do_prepare()
{
  export JAVA_HOME=$(hab pkg path core/jdk8)
  mkdir -p ~/.m2
  cp $PLAN_CONTEXT/../mvn/settings.xml ~/.m2/settings.xml
  cp $PLAN_CONTEXT/../certs/jssecacerts /hab/pkgs/core/jdk8/8.192.0/20190115162852/jre/lib/security/jssecacerts
}
# Package the application via maven
do_build()
{
  cp -r $PLAN_CONTEXT/../ $HAB_CACHE_SRC_PATH/$pkg_dirname
  cd ${HAB_CACHE_SRC_PATH}/${pkg_dirname}
  mvn package
}
# Install the application in the chroot location.
do_install()
{
  cp ${HAB_CACHE_SRC_PATH}/${pkg_dirname}/%APP_NAME%.int.jks ${PREFIX}/
  cp ${HAB_CACHE_SRC_PATH}/${pkg_dirname}/target/${pkg_name}-${pkg_version}.jar ${PREFIX}/
  chmod 555 ${PREFIX}/${pkg_name}-${pkg_version}.jar
  chown ${pkg_svc_user}:${pkg_svc_group} ${PREFIX}/${pkg_name}-${pkg_version}.jar
}
