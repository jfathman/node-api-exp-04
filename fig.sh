#! /bin/bash

# fig.sh

set -e
set -o pipefail

APP_NAME=$(cat package.json | jq -r '.name')

APP_VERSION=$(cat package.json | jq -r '.version')

FIG_NAME=$(echo $APP_NAME | sed 's/-//g')_app

main()
{
  if [ "$#" -eq 0 ]; then
    usage 1
  fi

  for arg
  do
    case ${arg} in
      build)
        sudo fig build
        sudo docker tag ${FIG_NAME}:latest ${FIG_NAME}:${APP_VERSION}
        ;;
      purge)
        UNTAGGED=$(sudo docker images --filter "dangling=true" -q)
        if [ ! -z "$UNTAGGED" ]; then
          sudo docker rmi ${UNTAGGED};
        else
          echo "none"
        fi
        ;;
      retrieve)
        sudo fig run --rm --no-deps app bash -c 'cp artifacts/* /mnt/.'
        ;;
      test)
        sudo fig run --rm app grunt test
        sudo fig stop
        sudo fig rm --force
        ;;
      up)
        sudo fig up
        ;;
      stop)
        sudo fig stop
        sudo fig rm --force
        ;;
      bash)
        sudo fig run --rm app bash
        ;;
      mongo)
        sudo fig run --rm mongodb mongo --host mongodb
        ;;
      redis)
        sudo fig run --rm redis redis-cli -h redis
        ;;
      push)
        USERNAME=$(cat package.json | jq -r '.dockerHub.username')
        sudo docker tag ${FIG_NAME}:${APP_VERSION} ${USERNAME}/${FIG_NAME}:${APP_VERSION}
        sudo docker push ${USERNAME}/${FIG_NAME}:${APP_VERSION}
        sudo docker rmi ${USERNAME}/${FIG_NAME}:${APP_VERSION}
        ;;
      help | -help | --help)
        usage 0
        ;;
      *)
        usage 1
        ;;
    esac
  done
  exit
}

usage()
{
  echo "$0 build     Build Fig services"
  echo "$0 purge     Remove untagged images after new build reuses repo:tag"
  echo "$0 retrieve  Retrieve build artifacts from app container"
  echo "$0 test      Run mock tests including load test in app container"
  echo "$0 up        Run Node app.js in production mode in app container"
  echo "$0 stop      Stop Fig services"
  echo "$0 bash      Run bash in app container"
  echo "$0 mongo     Run mongo client shell in mongodb container"
  echo "$0 redis     Run redis client shell in redis container"
  echo "$0 push      Push Docker image to DockerHub registry"
  echo "$0 help      Display help information"
  exit "$1"
}

main "$@"
