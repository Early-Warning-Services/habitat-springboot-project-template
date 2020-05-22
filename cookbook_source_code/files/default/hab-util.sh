#!/bin/bash

habitat () {
        # Get hab binary
        curl -k %HAB_BTSTRP_FILE% \
        | tar -xvzf - -C /tmp --strip-components 1

        # Set SSL cert for hab
        export SSL_CERT_FILE=/hab/cert/ssl-certificate.crt

        echo "Installing Habitat package using temporarily downloaded hab"
                  # NOTE: For people (rightly) wondering why we download hab only to use it
                  # to install hab from Builder, the main reason is because it allows /bin/hab
                  # to be a binlink, meaning that future upgrades can be easily done via
                  # hab pkg install core/hab -bf and everything will Just Work. If we put
                  # the hab we downloaded into /bin, then future hab upgrades done via hab
                  # itself won't work - you'd need to run this script every time you wanted
                  # to upgrade hab, which is not intuitive. Putting it into a place other than
                  # /bin means now you have multiple copies of hab on your system and pathing
                  # shenanigans might ensue. Rather than deal with that mess, we do it this
                  # way.
        "/tmp/hab" pkg install --binlink --force --channel "stable" "core/hab" -u %HAB_BLDR_URL%

        echo "Checking installed hab version"
        hab license accept
        hab --version
}

supervisor () {
        if [ ! -f "/hab/pkgs/core/hab-sup/0.83.0/20190712234724/bin/hab-sup" ]; then
          systemctl stop hab-sup.service
          systemctl start hab-sup.service
        else
          systemctl status hab-sup.service
          retVal=$?
          if [ $retVal -ne 0 ]; then
            systemctl start hab-sup.service
          fi
        fi
}

package () {
    if [ ! -d "/hab/pkgs/$packageName" ]; then
          export HAB_BLDR_URL="%HAB_BLDR_URL%"
          export SSL_CERT_FILE=/hab/cert/ssl-certificate.crt
          hab pkg install -c $channel $packageName
        fi
}

service () {
    hab sup status $packageName
        retVal=$?
        if [ $retVal -ne 0 ]; then
          export SSL_CERT_FILE=/hab/cert/ssl-certificate.crt 
          export HAB_BLDR_URL="%HAB_BLDR_URL%"
          hab svc load --channel $channel --strategy $strategy --topology $topology $packageName
        fi
}

display_help () {
  cat << EOF
  
  The hab-util script provides admins a way to easily manage any changes that need to be done by hand
  on a host machine runing the Habitat Supervisor.  Here are a list of the available commands:
  
    -H or --hab:          Installs or upgrades hab cli to the most current version availabe from the builder depot
    -S or --sup:          Install the specified version of hab-sup and makes sure it is running
    -P or --pkg:          Installs a given package from a specified channel using the format
                          ./hab-util.sh -P <channel> <origin>/<package>

                            example: ./hab-util.sh -P unstable dev_app/unicorn

    -V or --svc:          Installs and runs a package as a service from a specified channel using the format
                          ./hab-util.sh -V <channel> <origin>/<package> <strategy> <topology>

                            example: ./hab-util.sh -V unstable dev_app/unicorn at-once standalone

EOF
}

while :
do
    case "$1" in
      -H | --hab)
          habitat
          exit 0
          ;;
      -S | --sup)
          supervisor
          exit 0
      ;;
      -P | --pkg)
          channel="$2"
          packageName="$3"
          package
          exit 0
          ;;
      -V | --svc)
          channel="$2"
          packageName="$3"
          strategy="$4"
          topology="$5"
          service
          exit 0
          ;;
      -h | --help)
          display_help  # Call help function
          exit 0
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          display_help  # Call help function
          exit 1 
          ;;
      *)  # No more options
          break
          ;;
    esac
done
