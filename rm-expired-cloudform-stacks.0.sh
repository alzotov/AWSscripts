#!/bin/bash
set -xe
for s in \
    $(aws --profile mfa cloudformation list-stacks --stack-status-filter CREATE_COMPLETE |  \
    jq '.StackSummaries[] | {StackName,CreationTime,CreationTimeISO: .CreationTime} |.CreationTime |= (.[:-13]|strptime("%Y-%m-%dT%H:%M:%S")|mktime) | select(.StackName|test("-qa")) |  if .CreationTime < (now - 345600) then . else empty end | .StackName' | \
    sed 's/"//g');
do
    aws --profile mfa cloudformation delete-stack --stack-name $s;
done
