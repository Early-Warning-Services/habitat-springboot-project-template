#!/bin/bash
#
# set -x
set -e

# Set the script variables from Bamboo Build Variables (where appropriate)
# Set the following values in the environment variables in Build Plan
REPO_SLUG=$bamboo_appName 						# Name for the source code repo
REPO_PRJCT=$bamboo_repoPrjct					# Key for the source code project
REPO_KEY=$bamboo_buildPlanKey 					# Bamboo build plan key
APP_NAME=$bamboo_appName 						# Name of the application
APP_CB_NAME="$bamboo_appName"					# Name of the cookbook
CB_REPO_SLUG="cookbook $bamboo_appName"			# Name of the cb source code repo
JIRA_PROJECT_KEY=$bamboo_jiraProjectKey			# JIRA project key for project issue
USER_NAME=$bamboo_userName						# User name for responsible party
USER_EMAIL=$bamboo_userEmail					# User email for responsible party
BUILD_NUM=$bamboo_buildNumber               	# Grab the build number
TMPLT_VRSN=$bamboo_inject_tmplt_vrsn        	# Get the template version being used
SOURCE_URL=$bamboo_source_url					# The base source url
POLICYFILE_PROJECT=$bamboo_policyfile_project	# The project key for policyfiles
JIRA_URL=$bamboo_jira_url						# The base url for jira
BUILD_RESULTS_URL=$bamboo_buildResultsUrl		# The build results url
SUPERMARKET=$bamboo_supermarket					# The supermarket url
PROJECT_KEY=$bamboo_project_key					# The Bamboo project key where the build plan will be created
VAULT_ADDR=$bamboo_vault_addr					# The URL for hashicorp vault
HAB_JSSE_URL=$bamboo_hab_jsse_url				# The download url for the jssecacert file used by java in hart
HAB_SSL_CERT_URL=$bamboo_hab_ssl_cert_url		# The download url for the Habitat builder depot cert
HAB_BLDR_URL=$bamboo_hab_bldr_url				# The url for the Habitat builder depot
MAVEN_URL=$bamboo_maven_url						# The URL for maven repo
ISSUE_PROJECT=$bamboo_issue_project             # The JIRA Project key to be used for generating the necessary JIRA Issues
HAB_BTSTRP_FILE=$bamboo_hab_btstrp_file			# The location of the habitat tar file used to bootstrap a new server with habitat
KTCHN_RBY_URL=$bamboo_ktchn_rby_url				# The ruby gems url for kitchen
KTCHN_DKKN_IMAGE=$bamboo_ktchn_dkkn_image		# The dokken image to use for test kitchen
BAMBOO_URL=$bamboo_bamboo_url					# The Bamboo application base url
PKG_ORIGIN=$bamboo_pkg_origin                   # The origin to use with Habitat

# Test to make sure all variable have been entered
if [ -z "$REPO_PRJCT" ]; then
  echo
  echo "No repository project has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable repoPrjct with the name of the new docker container repo.";
  echo "Formatted like: cpt";
  echo
  exit 1;
fi

if [ -z "$REPO_KEY" ]; then
  echo
  echo "No build plan key has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable buildPlanKey with a unique key identifier 6 characters in length (letter and numbers only).";
  echo "Formatted like: ABCDEF";
  echo
  exit 1;
fi

if [ -z "$APP_NAME" ]; then
  echo
  echo "No application name has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable appName with the name of the new application.";
  echo "Formatted like: my new app";
  echo
  exit 1;
fi

if [ -z "$JIRA_PROJECT_KEY" ]; then
  echo
  echo "No JIRA project has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable jiraProjectKey with the key of the JIRA project for this applicaiton.";
  echo "Formatted like: APIA";
  echo
  exit 1;
fi

if [ -z "$USER_NAME" ]; then
  echo
  echo "No user name has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable userName with your name.";
  echo "Formatted like: John Doe";
  echo
  exit 1;
fi

if [ -z "$USER_EMAIL" ]; then
  echo
  echo "No user email has been set.  Please re-run the build plan as a custom execution.";
  echo "Over-ride the value of variable userEmail with your email.";
  echo "Formatted like: firstname.lastname@earlywarning.com";
  echo
  exit 1;
fi

# Clean up variables to be the correct state needed
REPO_SLUG=${REPO_SLUG// /_} #cannot contain spaces
REPO_SLUG=${REPO_SLUG,,} #must be lower case
REPO_KEY=${REPO_KEY// /} #cannot contain spaces
REPO_KEY=${REPO_KEY^^} #must be upper case
REPO_KEY=${REPO_KEY:0:6} #No more than 6 characters
REPO_PRJCT=${REPO_PRJCT// /_} #cannot contain spaces
REPO_PRJCT=${REPO_PRJCT,,} #must be lower case
APP_NAME=${APP_NAME// /-} #cannot contain spaces
APP_NAME=${APP_NAME//_/-} #cannot contain underscores
APP_NAME=${APP_NAME,,} #must be lower case
APP_CB_NAME=${APP_CB_NAME// /_} #cannot contain spaces
APP_CB_NAME=${APP_CB_NAME//-/_} #cannot contain hyphens
APP_CB_NAME=${APP_CB_NAME,,} #must be lower case
CB_REPO_SLUG=${CB_REPO_SLUG// /_} #cannot contain spaces
CB_REPO_SLUG=${CB_REPO_SLUG//-/_} #should be underscores
CB_REPO_SLUG=${CB_REPO_SLUG,,} #must be lower case
JIRA_PROJECT_KEY=${JIRA_PROJECT_KEY^^} #must be upper case
FROMAPPSOURCE=ssh://git@$SOURCE_URL:7999/$REPO_PRJCT/$REPO_SLUG.git
FROMCBSOURCE=ssh://git@$SOURCE_URL:7999/$REPO_PRJCT/$CB_REPO_SLUG.git
APPSOURCE=https://$SOURCE_URL/projects/$REPO_PRJCT/repos/$REPO_SLUG/browse
CBSOURCE=https://$SOURCE_URL/projects/$REPO_PRJCT/repos/$CB_REPO_SLUG/browse
APP_HAB_PKG=ews_dev_app/$APP_NAME
TODAY=$(date +%F)

# ########################################################################
# Build Application project                                              #
# ########################################################################

# Create the repo
curl -u ${bamboo_stashuser}:${bamboo_stashpassword} -X POST -H "Accept: application/json"  \
-H "Content-Type: application/json" \
"https://$SOURCE_URL/rest/api/1.0/projects/$REPO_PRJCT/repos/" \
-d '{"name": "'$REPO_SLUG'"}'

# Checkout new repo
git clone $FROMAPPSOURCE

# Change directory to checkout
cd $REPO_SLUG

# Copy app template
cp -r ../projectTemplate/app_source_code/. ./

# Edit necessary files
sed -i -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%REPO_SLUG%;$REPO_SLUG;g" -e "s;%REPO_PRJCT%;$REPO_PRJCT;g" -e "s;%SOURCE_URL%;$SOURCE_URL;g" ./pom.xml
sed -i -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%REPO_KEY%;$REPO_KEY;g" -e "s;%TMPLT_VRSN%;$TMPLT_VRSN;g" ./README.md
sed -i -e "s;%DATE%;$TODAY;g" -e "s;%APP_NAME%;$APP_NAME;g" ./CHANGELOG.md
sed -i -e "s;%REPO_KEY%;$REPO_KEY;g" -e "s;%REPO_SLUG%;$REPO_SLUG;g" -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%PROJECT_KEY%;$PROJECT_KEY;g" -e "s;%VAULT_ADDR%;$VAULT_ADDR;g" -e "s;%HAB_JSSE_URL%;$HAB_JSSE_URL;g" -e "s;%HAB_SSL_CERT_URL%;$HAB_SSL_CERT_URL;g" -e "s;%HAB_BLDR_URL%;$HAB_BLDR_URL;g" -e "s;%PKG_ORIGIN%;$PKG_ORIGIN;g" ./bamboo-specs/bamboo.yml
sed -i -e "s;%MAVEN_URL%;$MAVEN_URL;g" ./mvn/settings.xml
sed -i -e "s;%APP_NAME%;$APP_NAME;g" ./habitat/README.md
sed -i -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%USER_NAME%;$USER_NAME;g" -e "s;%USER_EMAIL%;$USER_EMAIL;g" -e "s;%PKG_ORIGIN%;$PKG_ORIGIN;g" ./habitat/plan.sh
sed -i -e "s;%APP_NAME%;$APP_NAME;g" ./habitat/default.toml
sed -i -e "s;%APP_NAME%;$APP_NAME;g" ./fortify/fortVars.txt

# Commit files and create development branch
git add --all
git commit -m "Generated project $REPO_SLUG from template"
git push
git checkout -b develop
git push --set-upstream origin develop

cd ..

# ########################################################################
# Build Cookbook project                                                 #
# ########################################################################

# Create the repo
curl -u ${bamboo_stashuser}:${bamboo_stashpassword} -X POST -H "Accept: application/json"  \
-H "Content-Type: application/json" \
"https://$SOURCE_URL/rest/api/1.0/projects/$REPO_PRJCT/repos/" \
-d '{"name": "'$CB_REPO_SLUG'"}'

# Checkout new repo
git clone $FROMCBSOURCE

# Change directory to checkout
cd $CB_REPO_SLUG

# Copy app template
cp -r ../projectTemplate/cookbook_source_code/. ./

# Edit necessary files
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%REPO_KEY%;$REPO_KEY;g" -e "s;%USER_NAME%;$USER_NAME;g" -e "s;%USER_EMAIL%;$USER_EMAIL;g" -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%APP_HAB_PKG%;$APP_HAB_PKG;g" -e "s;%TMPLT_VRSN%;$TMPLT_VRSN;g" -e "s;%BAMBOO_URL%;$BAMBOO_URL;g" -e "s;%HAB_BLDR_URL%;$HAB_BLDR_URL;g" ./README.md
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%USER_NAME%;$USER_NAME;g" -e "s;%USER_EMAIL%;$USER_EMAIL;g" -e "s;%JIRA_PROJECT_KEY%;$JIRA_PROJECT_KEY;g" -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%CBSOURCE%;$CBSOURCE;g" -e "s;%JIRA_URL%;$JIRA_URL;g" ./metadata.rb
sed -i -e "s;%DATE%;$TODAY;g" -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" ./CHANGELOG.md
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%APP_HAB_PKG%;$APP_HAB_PKG;g" -e "s;%HAB_BLDR_URL%;$HAB_BLDR_URL;g" ./attributes/default.rb
sed -i -e "s;%REPO_KEY%;$REPO_KEY;g" -e "s;%CB_REPO_SLUG%;$CB_REPO_SLUG;g" -e "s;%FROMCBSOURCE%;$FROMCBSOURCE;g" -e "s;%PROJECT_KEY%;$PROJECT_KEY;g" ./bamboo-specs/bamboo.yml
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%HAB_SSL_CERT_URL%;$HAB_SSL_CERT_URL;g" -e "s;%HAB_BLDR_URL%;$HAB_BLDR_URL;g" ./recipes/default.rb
sed -i -e "s;%APP_HAB_PKG%;$APP_HAB_PKG;g" ./test/integration/habitat_test/habitat_test.rb
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" ./test/integration/fixtures/cookbooks/habitat_test/metadata.rb
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" ./test/integration/fixtures/cookbooks/habitat_test/recipes/default.rb
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%KTCHN_RBY_URL%;$KTCHN_RBY_URL;g" -e "s;%KTCHN_DKKN_IMAGE%;$KTCHN_DKKN_IMAGE;g" ./.kitchen.dokken.yml
sed -i -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" ./spec/unit/recipes/default_spec.rb
sed -i -e "s;%HAB_BTSTRP_FILE%;$HAB_BTSTRP_FILE;g" -e "s;%HAB_BLDR_URL%;$HAB_BLDR_URL;g" ./files/default/hab-util.sh
sed -i -e "s;%SUPERMARKET%;$SUPERMARKET;g" ./test/integration/fixtures/cookbooks/habitat_test/Berksfile
sed -i -e "s;%SUPERMARKET%;$SUPERMARKET;g" ./Berksfile

# Commit files and create development branch
git add --all
git commit -m "Generated project $REPO_SLUG from template"
git push
git checkout -b develop
git push --set-upstream origin develop

cd ..

# ########################################################################
# Add Policyfile                                                         #
# ########################################################################

# Checkout the policyfile repo
git clone -b master --single-branch ssh://git@$SOURCE_URL:7999/$POLICYFILE_PROJECT/chef_policyfiles.git

# Change directory to checkout
cd chef_policyfiles

# Copy in new policy files
sed -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%APP_CB_NAME%;$APP_CB_NAME;g" -e "s;%TMPLT_VRSN%;$TMPLT_VRSN;g" -e "s;%SUPERMARKET%;$SUPERMARKET;g" ../projectTemplate/policyfile_source_code/policy_sample_app.rb > ./policy_$APP_NAME.rb

# Commit new policyfile
git add --all
git commit -m "Generated policyfile policy_ews_$APP_NAME.rb from template"
git push

cd ..

# ########################################################################
# Submit JIRA Tickets                                                    #
# ########################################################################

# Edit the New JIRA json
sed -e "s;%APPSOURCE%;$APPSOURCE;g" -e "s;%CBSOURCE%;$CBSOURCE;g" -e "s;%BUILD_NUM%;$BUILD_NUM;g" -e "s;%APP_NAME%;$APP_NAME;g" -e "s;%BUILD_RESULTS_URL%;$BUILD_RESULTS_URL;g" -e "s;%ISSUE_PROJECT%;$ISSUE_PROJECT;g" ./projectTemplate/newjira.json > ./newjira.json

# Section below commented out As JIRA instance not available during demo
#
# Submit ticket to link created repos
# curl \
#    -D- \
#    -u $bamboo_jiraUser:$bamboo_jiraUserPassword \
#    -X POST \
#    --data @newjira.json \
#    -H "Content-Type: application/json" \
#    https://$JIRA_URL/rest/api/2/issue/

# ########################################################################
# Ascii art for the heck of it                                           #
# ########################################################################

cat << "EOF"



                         ______                     
 _________        .---"""      """---.              
:______.-':      :  .--------------.  :             
| ______  |      | :                : |             
|:______B:|      | |  Wouldn't you  | |             
|:______B:|      | |  prefer a good | |             
|:______B:|      | |  game of       | |             
|         |      | |  chess?        | |             
|:_____:  |      | |                | |             
|    ==   |      | :                : |             
|       O |      :  '--------------'  :             
|       o |      :'---...______...---'              
|       o |-._.-i___/'             \._              
|'-.____o_|   '-.   '-...______...-'  `-._          
:_________:      `.____________________   `-.___.-. 
                 .'.eeeeeeeeeeeeeeeeee.'.      :___:
    apia       .'.eeeeeeeeeeeeeeeeeeeeee.'.         
              :____________________________:
			  
EOF
