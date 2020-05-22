name '%APP_CB_NAME%'
maintainer 'Who are you'
maintainer_email '%USER_NAME% <%USER_EMAIL%>'
license 'All Rights Reserved'
description 'Installs/Configures %APP_NAME%'
long_description 'Installs/Configures %APP_NAME%'
version '0.0.1'
chef_version '>= 12.21' if respond_to?(:chef_version)
supports 'centos', '>= 7.0'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
issues_url 'https://%JIRA_URL%/projects/%JIRA_PROJECT_KEY%/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
source_url '%CBSOURCE%'
