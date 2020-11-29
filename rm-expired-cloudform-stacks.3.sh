#!/bin/bash
#set -xe

if [[ $# < 2 ]]; then
	echo 'Usage:'
	echo 'rm-expired-cloudform.*.sh <regex to fetch stack names> <how many days old stacks are> [-dry (for dry run)]'
	echo 'sample: rm-expired-cloudform.*.sh -qa- 4 -dry'
	exit 1
fi

mask=$1
let period=$2*86400
echo $mask $period

function listStacks
{
	echo func $mask $period
	aws --profile mfa cloudformation list-stacks --stack-status-filter CREATE_COMPLETE |  \
	jq '.StackSummaries[] | {StackName,CreationTime,CreationTimeAWS: .CreationTime,CreationTimeISO: .CreationTime} |.CreationTimeISO |= (.[:-13]) |.CreationTime |= (.[:-13]|strptime("%Y-%m-%dT%H:%M:%S")|mktime) | select(.StackName|test("'$mask'"))' | \
	jq 'if .CreationTime < (now - '$period') then . else empty end | .CreationTimeISO + " " + .StackName' | \
	sed 's/"//g'
}

if [[ $3 = "-dry" ]]; then
	echo dry-run 
	listStacks
	exit 0
fi

echo run
for s in \
    $(aws --profile mfa cloudformation list-stacks --stack-status-filter CREATE_COMPLETE |  \
    jq '.StackSummaries[] | {StackName,CreationTime,CreationTimeISO: .CreationTime} |.CreationTime |= (.[:-13]|strptime("%Y-%m-%dT%H:%M:%S")|mktime) | select(.StackName|test("'$mask'"))' | \
	#tee >(cat) | \
	jq 'if .CreationTime < (now - '$period') then . else empty end | .StackName' | \
    sed 's/"//g');
do
	echo $s
    if [[ $3 != "-plan" ]]; then 
		echo deleting stack: $s
		aws --profile mfa cloudformation delete-stack --stack-name $s; 2> /dev/null
	fi
done

