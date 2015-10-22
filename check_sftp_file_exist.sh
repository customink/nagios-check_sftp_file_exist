#!/bin/bash

# Author: Doug Wilson
# To-Do:
#        * add ability to set arbitrary ssh options. For example, -oConnectTimeout or
#           or -oConnectionAttempts
#        * ability to specify SSH protocol version. Currently configured to v 2.
#        * ability to specify non-standard port

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PROGNAME=$(basename -- $0)
PROGPATH=$(echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION='0.0.1'
SERVICE_STATE_ON_FAIL="CRITICAL"
DEBUG="false"

# Could use utils.sh and remove some of the Exit function code, but not sure it's work it.
#  Not using utils.sh allows us to run this script outside of nagios.
#. $PROGPATH/utils.sh

# parse command line
usage () {
  echo ""
  echo "USAGE: "
  echo "  $PROGNAME -f \"full path to file to check\" (eg., upload/test_file.txt"
  echo "     -u : \"username to connect as\""
  echo "     -s : \"SFTP server to check\""
  echo "     [-i] : \"path to SSH key identity file\""
  echo "     [-w] : if fail, alert WARNING instead of CRITICAL"
  echo "     [-d] : show debug output"
  exit $STATE_UNKNOWN
}

while getopts "f:u:s:i:wd" opt; do
  case $opt in
    f) FILEPATH=${OPTARG} ;;
    u) USERNAME=${OPTARG} ;;
    s) SFTP_SERVER=${OPTARG} ;;
    i) IDENTITY_FILE=${OPTARG} ;;
    w) SERVICE_STATE_ON_FAIL="WARNING" ;;
    d) DEBUG="true" ;;
    *) usage ;;
  esac
done

if [ -z "${USERNAME}" -o -z "${SFTP_SERVER}" -o -z "${FILEPATH}"  ]; then
  usage
fi

Exit () {
	echo "$1: ${2}" >&3
	if [[ "$1" == "OK" ]]; then status=0; fi
	if [[ "$1" == "WARNING" ]]; then status=1; fi
	if [[ "$1" == "CRITICAL" ]]; then status=2; fi
	if [[ "$1" == "UNKNOWN" ]]; then status=3; fi
	exit $status
}

if [[ "$DEBUG" == "true" ]]; then
  echo "FILEPATH = $FILEPATH"
  echo "USERNAME = $USERNAME"
  echo "SFTP_SERVER = $SFTP_SERVER"
  echo "IDENTITY_FILE = $IDENTITY_FILE"
  echo ""
  echo "Starting SFTP test ..."
fi


# Set default output for following commands based on whether we want debug output or not
if [[ "$DEBUG" == "true" ]]; then
  exec 3>&1
else
  exec 3>&1 &>/dev/null
fi

sftp -2 -q -b /dev/stdin "$USERNAME"@"$SFTP_SERVER" <<EOF
ls "$FILEPATH"
quit
EOF
sftp_exit_code="$?"

if [ "$sftp_exit_code" -eq "0" ]; then
 Exit OK "File $FILEPATH is in place on $SFTP_SERVER."
else
 Exit "$SERVICE_STATE_ON_FAIL" "Unable to confirm file $FILEPATH is in place on $SFTP_SERVER.
  sftp exit code is $sftp_exit_code."
fi
