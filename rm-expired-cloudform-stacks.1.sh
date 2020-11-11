#!/bin/bash
#set -xe
lmask=$1
let period=$2*86400
echo $1 $mask $2 $period

function listStacks
{
	echo func $mask $period
	aws --profile mfa cloudformation list-stacks --stack-status-filter CREATE_COMPLETE |  \
	jq '.StackSummaries[] | {StackName,CreationTime,CreationTimeAWS: .CreationTime,CreationTimeISO: .CreationTime} |.CreationTimeISO |= (.[:-13]) |.CreationTime |= (.[:-13]|strptime("%Y-%m-%dT%H:%M:%S")|mktime) | select(.StackName|test("'$1'"))' | \
	jq 'if .CreationTime < (now - '$period') then . else empty end | .CreationTimeISO + " " + .StackName' | \
	sed 's/"//g'
}

if [[ $3 = "-plan" ]]; then
	echo plan
	listStacks
fi

echo run
for s in \
    $(aws --profile mfa cloudformation list-stacks --stack-status-filter CREATE_COMPLETE |  \
    jq '.StackSummaries[] | {StackName,CreationTime,CreationTimeISO: .CreationTime} |.CreationTime |= (.[:-13]|strptime("%Y-%m-%dT%H:%M:%S")|mktime) | select(.StackName|test("'$1'"))' | \
	#tee >(cat) | \
	jq 'if .CreationTime < (now - '$period') then . else empty end | .StackName' | \
    sed 's/"//g');
do
	echo $s
    if [[ $3 != "-plan" ]]; then 
		echo deleting stack: $s
		#aws --profile mfa cloudformation delete-stack --stack-name $s; > /dev/null
	fi
done

