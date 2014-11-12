#! /bin/bash

# docker.sh

set -e
set -o pipefail

PORT=8085

APP_NAME=$(cat package.json | jq -r '.name')

APP_VERSION=$(cat package.json | jq -r '.version')

main()
{
  if [ "$#" -eq 0 ]; then
    usage 1
  fi

  for arg
  do
    case ${arg} in
      build)
        sudo docker build -t ${APP_NAME}:${APP_VERSION} .
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
        sudo docker run --rm -v ${PWD}:/mnt ${APP_NAME}:${APP_VERSION} /bin/bash -c 'cp artifacts/* /mnt/.'
        ;;
      bash)
        sudo docker run --name app-$$ --rm -i -t -p ${PORT}:${PORT} ${APP_NAME}:${APP_VERSION} /bin/bash
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
  echo "$0 build     Build Docker image"
  echo "$0 purge     Remove untagged images after Docker reuses repo:tag for new build"
  echo "$0 retrieve  Retrieve build artifacts from Docker container"
  echo "$0 bash      Run bash in Docker container"
  echo "$0 help      Display help information"
  exit "$1"
}

main "$@"
