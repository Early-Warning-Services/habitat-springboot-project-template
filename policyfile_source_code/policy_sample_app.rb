# Policyfile.rb - Describe how you want Chef to build your system.
#
# Built from version %TMPLT_VRSN% of [springboot_habitat_project](!missing_URL)
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html
# Manage Rubocop
# A name that describes what the system you're building with Chef does.
name 'policy_%APP_NAME%'

# Where to find external cookbooks:
default_source :supermarket, '%SUPERMARKET%'

# run_list: chef-client will run these recipes in the order specified.
run_list 'poise-hoist', '%APP_CB_NAME%'

# Policy groups by environment.  Put environment specific attributes here.
# We could remove some of the logic in cookbooks like zabbix that define
# environment attributes like the zabbix server with this.

default['dev'] = {
  %APP_CB_NAME%: {
    channel: 'unstable'
  }
}

default['qa'] = {
  %APP_CB_NAME%: {
    channel: 'qa'
  }
}