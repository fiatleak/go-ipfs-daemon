#!/bin/sh
set -e

repo="$IPFS_PATH"

if [ -e "$repo/config" ]; then
  echo "Found IPFS fs-repo at $repo"
else
  if [ ! -z "$IPFS_PRIVATE_KEY" ]; then
    echo "Copying private key and peer id into config from environment..."
    /config_scripts/ipfs-config-identity.sh $repo/config $IPFS_PEER_ID $IPFS_PRIVATE_KEY || exit 1
  fi

  if [ $IPFS_ENABLE_S3 == true ] ; then
    echo "Configuring S3 datastore plugin..."

    echo "Updating Datastore.Spec.mounts..."
    ipfs config --json Datastore.Spec.mounts "$(/config_scripts/Datastore.Spec.mounts.s3.sh)"

    echo "Updating datastore_spec..."
    echo "$(/config_scripts/datastore_spec.s3.sh)" > $IPFS_PATH/datastore_spec
  fi
fi

# Explicitly run the migration before any configuration because, for some reason, trying to run the migration after the
# configuration commands doesn't work.
ipfs repo migrate

ipfs config Addresses.API "/ip4/0.0.0.0/tcp/$IPFS_API_PORT"
# Explicitly disable the gateway
ipfs config --json Addresses.Gateway '[]'
ipfs config --json Addresses.Swarm "[\"/ip4/0.0.0.0/tcp/$IPFS_SWARM_TCP_PORT\", \"/ip4/0.0.0.0/tcp/$IPFS_SWARM_WS_PORT/ws\"]"
ipfs config --json Pubsub.Enabled true
ipfs config Pubsub.SeenMessagesTTL 10m
ipfs config --json Swarm.RelayClient.Enabled false

BOOTSTRAP_PEERS='[
  {"ID": "QmXALVsXZwPWTUbsT8G6VVzzgTJaAWRUD7FWL5f7d5ubAL",       "Addrs": ["/dns4/go-ipfs-ceramic-private-mainnet-external.3boxlabs.com/tcp/4011/ws/p2p/QmXALVsXZwPWTUbsT8G6VVzzgTJaAWRUD7FWL5f7d5ubAL"]},
  {"ID": "QmUvEKXuorR7YksrVgA7yKGbfjWHuCRisw2cH9iqRVM9P8",       "Addrs": ["/dns4/go-ipfs-ceramic-private-cas-mainnet-external.3boxlabs.com/tcp/4011/ws/p2p/QmUvEKXuorR7YksrVgA7yKGbfjWHuCRisw2cH9iqRVM9P8"]},
  {"ID": "QmUiF8Au7wjhAF9BYYMNQRW5KhY7o8fq4RUozzkWvHXQrZ",       "Addrs": ["/dns4/go-ipfs-ceramic-elp-1-1-external.3boxlabs.com/tcp/4011/ws/p2p/QmUiF8Au7wjhAF9BYYMNQRW5KhY7o8fq4RUozzkWvHXQrZ"]},
  {"ID": "QmRNw9ZimjSwujzS3euqSYxDW9EHDU5LB3NbLQ5vJ13hwJ",       "Addrs": ["/dns4/go-ipfs-ceramic-elp-1-2-external.3boxlabs.com/tcp/4011/ws/p2p/QmRNw9ZimjSwujzS3euqSYxDW9EHDU5LB3NbLQ5vJ13hwJ"]},
  {"ID": "QmbeBTzSccH8xYottaYeyVX8QsKyox1ExfRx7T1iBqRyCd",       "Addrs": ["/dns4/go-ipfs-ceramic-private-cas-clay-external.3boxlabs.com/tcp/4011/ws/p2p/QmbeBTzSccH8xYottaYeyVX8QsKyox1ExfRx7T1iBqRyCd"]},
  {"ID": "12D3KooWDYD5hgsnvqtuTQsTsqwt37gFY6YdQ9qeJNTzLMKph1rF", "Addrs": ["/ip4/155.138.235.201/tcp/4001/p2p/12D3KooWDYD5hgsnvqtuTQsTsqwt37gFY6YdQ9qeJNTzLMKph1rF"]}
]'
ipfs config --json Peering.Peers "${BOOTSTRAP_PEERS}"
