#!/bin/bash
aws service-quotas list-services | jq -r -c ".Services[].ServiceCode" > services


while read service; do

>&2 echo "Processing $service..."

aws service-quotas list-service-quotas --service-code $service > $service.quotas
aws service-quotas list-aws-default-service-quotas --service-code $service > $service.default
cat $service.quotas | jq -r -c ".Quotas[].QuotaCode" > $service.quotacodes


while read quotaCode; do

current=`cat $service.quotas | jq -r '.Quotas[] | select(.QuotaCode | contains("'$quotaCode'")) | .Value'`
default=`cat $service.default | jq -r '.Quotas[] | select(.QuotaCode | contains("'$quotaCode'")) | .Value'`

if [[ "$current" != "$default" ]]
then
  echo "aws service-quotas request-service-quota-increase --service-code $service --quota-code $quotaCode --desired-value $current"
fi
 
done <$service.quotacodes

rm $service.quotas; rm $service.default; rm $service.quotacodes

done < services
