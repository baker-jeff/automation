#/bin/bash
#script to pull, compare, and report on lifecycle of used resources

grep -v '^#' ./eol-versions > ./eol-versions.tmp && mapfile -t products < ./eol-versions.tmp
eolcheck=60
daydate=`date '+%d'`
dowdate=`date '+%u'`
heartbeat_slack_channel='[insert slack channel for heartbeat notification]'
slack_channel_url='[insert slack channel for output notification]'

#monthly run
if [ $daydate == 01 ]; then
    #iterate through the list of products
    for product in ${products[@]};
    do
        prodsplit=(${product//,/ })
        payload_current=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}/${prodsplit[1]}.json)
        payload_full=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}.json)
        eol=$(echo $payload_current | jq .eol | sed -e 's/^"//' -e 's/"$//')
        cversion=$(echo $payload_full | jq -r '.[0].cycle')
        crelease=$(echo $payload_full | jq -r '.[0].releaseDate')
        alert=""

        #check if eol is less than eolcheck variable days and ping @channel each product that is within the threshold
        if [[ $eol != "false" ]]; then 
            eoldate=`date -d "$eol" '+%s'`
            checkdate=`date '+%s'`
            #time difference between new SSL date and current date
            checkdiff="$(((${eoldate}-${checkdate})/60/60/24))"
            if [ $checkdiff -lt $eolcheck ]; then
                alert=" <!channel>"
            fi
        fi

        #create payload for the product and send to Slack
        #set eol to not listed if no value returned for eol
        if [[ $eol == "false" ]]; then
        eol="Not Listed"
        fi
        slack_payload="Release In Production - ${prodsplit[0]} - ${prodsplit[1]}
        End of Life: $eol
        Current Release: $cversion
        Release Date: $crelease
        More Info found here: https://endoflife.date/${prodsplit[0]}
        "
        curl -X POST -k -H 'Content-type: application/json' --data "{text:'$slack_payload$alert'}" $slack_channel_url
    done
#weekly run
elif [ $dowdate == 1 ]; then
    #iterate through the list of products
    for product in ${products[@]};
    do
        prodsplit=(${product//,/ })
        payload_current=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}/${prodsplit[1]}.json)
        payload_full=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}.json)
        eol=$(echo $payload_current | jq .eol | sed -e 's/^"//' -e 's/"$//')
        cversion=$(echo $payload_full | jq -r '.[0].cycle')
        crelease=$(echo $payload_full | jq -r '.[0].releaseDate')
        alert=""

        #check if eol is less than eolcheck variable days and ping @channel each product that is within the threshold
        if [[ $eol != "false" ]]; then 
            eoldate=`date -d "$eol" '+%s'`
            checkdate=`date '+%s'`
            #time difference between new SSL date and current date
            checkdiff="$(((${eoldate}-${checkdate})/60/60/24))"
            #set alert if product is within threshold of eol
            if [ $checkdiff -lt $eolcheck ]; then
                alert=" <!channel>"
            fi
        fi
        #only send a notice for a product if the alert is within the threshold
        if [[ $alert != '' ]]; then
        #create payload for the product and send to Slack
        #set eol to not listed if no value returned for eol
        if [[ $eol == "false" ]]; then
        eol="Not Listed"
        fi
        slack_payload="Release In Production - ${prodsplit[0]} - ${prodsplit[1]}
        End of Life: $eol
        Current Release: $cversion
        Release Date: $crelease
        More Info found here: https://endoflife.date/${prodsplit[0]}
        "
        curl -X POST -k -H 'Content-type: application/json' --data "{text:'$slack_payload$alert'}" $slack_channel_url
        fi
    done
#daily run
else
    #iterate through the list of products
    for product in ${products[@]};
    do
        prodsplit=(${product//,/ })
        payload_current=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}/${prodsplit[1]}.json)
        payload_full=$(curl -skX GET https://endoflife.date/api/${prodsplit[0]}.json)
        eol=$(echo $payload_current | jq .eol | sed -e 's/^"//' -e 's/"$//')
        cversion=$(echo $payload_full | jq -r '.[0].cycle')
        crelease=$(echo $payload_full | jq -r '.[0].releaseDate')
        alert=""

        #check if eol is less than eolcheck variable days and ping @channel each product that is within the threshold
        if [[ $eol != "false" ]]; then 
            eoldate=`date -d "$eol" '+%s'`
            checkdate=`date '+%s'`
            #time difference between new SSL date and current date
            checkdiff="$(((${eoldate}-${checkdate})/60/60/24))"
            #set alert if the product is past eol
            if [ $checkdiff -lt 0 ]; then
                alert=" <!channel>"
            fi
        fi
        
        #Send notice only if the product is past eol
        if [[ $alert != '' ]]; then
        #create payload for the product and send to Slack
        #set eol to not listed if no value returned for eol
            if [[ $eol == "false" ]]; then
                eol="Not Listed"
            fi
            slack_payload="Release In Production - ${prodsplit[0]} - ${prodsplit[1]}
            End of Life: $eol
            Current Release: $cversion
            Release Date: $crelease
            More Info found here: https://endoflife.date/${prodsplit[0]}
            "
            curl -X POST -k -H 'Content-type: application/json' --data "{text:'$slack_payload$alert'}" $slack_channel_url
        fi
    done
fi

#notify devops-alerts channel that execution occurred
curl -X POST -k -H 'Content-type: application/json' --data "{text:'EndofLife Execution Successful'}" heartbeat_slack_channel


