#!/bin/bash

###############################################################
#               This section can be removed once understood
#            
# Below is a list of all the bamboo variables used in this script. It include where they
# come from in Bamboo and what they relate to in the script.  This is an example of the script
# that can be used as is for RPM migration provided all the variables are properly set up for
# the Bamboo Project:
#
# ${bamboo_fortifyPath}          - Global Variable.  Path to fortify version.
# ${bamboo_fotifyPlugin}         - Global Variable.  Maven Plugin version used.
# ${bamboo_sslPassword}          - Global Variable.  Keystore password.
# ${bamboo_fortifyVersion}       - Global Variable.  Fortify SCA version to use.
# ${bamboo_fortifyAuthToken}     - Global Variable.  Token used for authenticating to HP Fortify when uploading.
# ${bamboo_fortJdk}              - Global Variable.  Path to JDK used to build project.
# ${bamboo_fortify_url}			 - Global Variable.  URL for fortify server.
# ${bamboo_fortify_cert}         - Global variable.  Cert used for ssl to fortify server.
#
# ${bamboo_fort_fortBuildID}          - Plan Variable.  Goal ID in POM file
# ${bamboo_fort_fortArtifactId}       - Plan Variable.  Artifact Id specified in the fortify section of the POM
# ${bamboo_fort_planFortifyFPR}       - Plan Variable.  Location/name.fpr of the fpr file relative to the working directory
# ${bamboo_fort_planFortifyID}        - Plan Variable.  ID for the project in HP Fortify to load the fpr too
#                                
###############################################################

# Set PATH and JAVA_HOME
export PATH=${bamboo_fortifyPath}/bin/:${bamboo_fortJdk}:$PATH
export JAVA_HOME=${bamboo_fortJdk}

# Clean Sourceanalyzer
sourceanalyzer -clean -b ${bamboo_fort_fortBuildID} -verbose

# Run translate
/opt/atlassian/Development/Tools/Iterations/apache-maven-3.2.5/bin/mvn ${bamboo_fotifyPlugin}:translate \
-Dfortify.sca.verbose=true -Dfortify.sca.debug=true \
-Denv=dev \
-Djavax.net.ssl.keyStore=${bamboo_fortify_cert} \
-Djavax.net.ssl.keyStorePassword=${bamboo_sslPassword} \
-Djavax.net.ssl.trustStore=${bamboo_fortify_cert} \
-Djavax.net.ssl.trustStorePassword=${bamboo_sslPassword} \
-DskipTests \
-Dsca.maven.plugin.version=${bamboo_fortifyVersion}

# Run scan
/opt/atlassian/Development/Tools/Iterations/apache-maven-3.2.5/bin/mvn ${bamboo_fotifyPlugin}:scan \
-Dfortify.sca.verbose=true \
-Dfortify.sca.debug=true \
-Dfortify.sca.artifactId=${bamboo_fort_fortArtifactId} \
-Denv=dev \
-Dfortify.sca.resultsFile=${bamboo_fort_planFortifyFPR} \
-Djavax.net.ssl.keyStore=${bamboo_fortify_cert} \
-Djavax.net.ssl.keyStorePassword=${bamboo_sslPassword} \
-Djavax.net.ssl.trustStore=${bamboo_fortify_cert} \
-Djavax.net.ssl.trustStorePassword=${bamboo_sslPassword} \
-DskipTests \
-Dsca.maven.plugin.version=${bamboo_fortifyVersion}

# Upload FPR if there is a Fortify ID 
if [ "$bamboo_fort_planFortifyID" == "00000" ]; 
then
  echo
  echo "Fortify ID has not been updated."
  echo "Fortify FPR has not been uploaded."
  echo
  exit 0
else
  fortifyclient uploadFPR -f ./target/fortify/${bamboo_fort_planFortifyFPR} \
  -projectVersionID ${bamboo_fort_planFortifyID} -url ${bamboo_fortify_url} \
  -authtoken ${bamboo_fortifyAuthToken}
fi
