# %APP_CB_NAME%

Description
===========

Installs and configures %APP_NAME%.

---
## Bamboo Build status
-	[Master:  
			![build status badge](%BAMBOO_URL%/plugins/servlet/buildStatusImage/CHEF-%REPO_KEY%)](%BAMBOO_URL%/browse/CHEF-%REPO_KEY%)

---

Requirements
============

Platform
--------

* CentOS w/ habitat

Tested on:

* CentOS 6, 7

Cookbooks
---------

Requires Chef's Habitat cookbook to manage and configure Habitat Supervisor.


Resources and Providers
=======================


Attributes
==========

- default['%APP_CB_NAME%']['habpkg'] = '%APP_HAB_PKG%'
- default['%APP_CB_NAME%']['bldr_url'] = '%HAB_BLDR_URL%'
- default['%APP_CB_NAME%']['channel'] = 'stable'
- default['%APP_CB_NAME%']['strategy'] = 'rolling'
- default['%APP_CB_NAME%']['topology'] = 'standalone'

Usage
=====



License and Author
==================

Author:: %USER_NAME% (<%USER_EMAIL%>)

Copyright:: All Rights Reserved.
---
Built from version %TMPLT_VRSN% of [springboot_habitat_project](https://stash.ews.int/projects/CPT/repos/springboot_habitat_project/browse)
