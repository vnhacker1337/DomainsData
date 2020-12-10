#!/bin/sh

TARGET=$1
WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)


function run_auto()
{
	$WORKING_DIR/docker_quick_get_subdomain.sh -d $domain 

}

cat $TARGET | while read domain; 
do
	run_auto $domain
done
