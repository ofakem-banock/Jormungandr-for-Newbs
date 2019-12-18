export ARCHFLAGS="-arch x86_64"
test -f ~/.bashrc && source ~/.bashrc

function start() {
    GREEN=$(printf "\033[0;32m")
    nohup jormungandr --config ~/files/node-config.yaml --genesis-block-hash $GENESIS_BLOCK_HASH >> ~/logs/node.out 2>&1 &
    echo ${GREEN}$(ps | grep jormungandr)
}

function stop() {
    echo "$(jcli rest v0 shutdown get -h http://127.0.0.1:${REST_PORT}/api)"
}

function stats() {
    echo "$(jcli rest v0 node stats get -h http://127.0.0.1:${REST_PORT}/api)"
}

function bal() {
    echo "$(jcli rest v0 account get $(cat ~/files/receiver_account.txt) -h  http://127.0.0.1:${REST_PORT}/api)"
}

function faucet() {
    echo "$(curl -X POST https://faucet.${CHAIN_NAME}.jormungandr-testnet.iohkdev.io/send-money/$(cat ~/files/receiver_account.txt))"
}

function get_ip() {
    echo "${PUBLIC_IP_ADDR}"
}

function get_pid() {
    ps auxf | grep jor
}

function memory() {
    top -o %MEM
}

function nodes() {
    nodes="$(netstat -tupan | grep jor | grep EST | cut -c 1-80)"
    total="$(netstat -tupan | grep jor | grep EST | cut -c 1-80 | wc -l)"
    printf "%s\n" "${nodes}" "----------" "Total:" "${total}"
}

function num_open_files() {
    echo "Calculating number of open files..."
    echo "$(lsof -u $(whoami) | wc -l)"
}

function is_pool_visible() {
    echo ${GREEN}$(jcli rest v0 stake-pools get --host "http://127.0.0.1:${REST_PORT}/api" | grep $(cat ~/files/stake_pool.id))
}

function delegate() {
    echo "$(~/files/delegate-account.sh $(cat ~/files/stake_pool.id) ${REST_PORT} $(cat ~/files/receiver_secret.key))"
}

function start_leader() {
    GREEN=$(printf "\033[0;32m")
    nohup jormungandr --config ~/files/node-config.yaml --secret ~/files/node_secret.yaml --genesis-block-hash ${GENESIS_BLOCK_HASH} >> ~/logs/node.out 2>&1 &
    echo "${GREEN}$(ps | grep jormungandr)"
}

function logs() {
    tail ~/logs/node.out
}

function empty_logs() {
    > ~/logs/node.out
}

function leader_logs() {
    echo "Has this node been scheduled to be leader?"
    echo "$(jcli rest v0 leaders logs get -h http://127.0.0.1:${REST_PORT}/api)"
}

function pool_stats() {
    echo "$(jcli rest v0 stake-pool get $(cat ~/files/stake_pool.id) -h http://127.0.0.1:${REST_PORT}/api)"
}

function problems() {
    grep -E -i 'cannot|stuck|exit|unavailable' ~/logs/node.out
}

#Use to check if the leader node is updated and restart it if necessary
#Use until the testnet is more stable
function unstuck_leader(){
    #!/bin/bash
#
# Created by Uruncle @ https://adage.app Cardano Stake Pool
#
# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
### CONFIGURATION
LAST_BLOCK=""
RESTART_GT=180

START_TIME=$SECONDS

while true
do
    TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo ""
    echo "${TIME} - Press [CTRL+C] to stop..."
    LATEST_BLOCK=$(stats | grep lastBlockHeight | awk '{print $2}')

    if [ "$LATEST_BLOCK" > 0 ]; then
        if [ "$LATEST_BLOCK" != "$LAST_BLOCK" ]; then
            START_TIME=$(($SECONDS))
            echo "New block height: ${LATEST_BLOCK}"
            LAST_BLOCK="$LATEST_BLOCK"
        else
            ELAPSED_TIME=$(($SECONDS - $START_TIME))
            echo "Current block height: ${LATEST_BLOCK} - No new block for ${ELAPSED_TIME} sec."
            if [ "$ELAPSED_TIME" -gt "$RESTART_GT" ]; then
                echo "Shutting down jormungandr"
                #stop
                echo "Sleeping for 5 sec."
                sleep 5
                echo "Restarting jormungandr"
                #start_leader
                LAST_BLOCK="$LATEST_BLOCK"
                echo "Sleeping for 60 sec."
                sleep 60
            fi
        fi
    else
        echo "No block height"
    fi
    sleep 10
done

exit 0
}
unset -f unstuck_leader
