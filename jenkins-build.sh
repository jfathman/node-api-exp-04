#! /bin/bash

# jenkins-build.sh

set -e

# Requires Fig >= 1.0.1 to capture Fig output in Jenkins build log.

main()
{
  set +x
  annotate "Report test environment versions for build log."

  lsb_release -d

  docker --version

  fig --version

  jq --version

  set +x
  annotate "Get application information from package.json."

  APP_NAME=$(cat package.json | jq -r '.name')

  APP_VERSION=$(cat package.json | jq -r '.version')

  FIG_NAME=$(echo $APP_NAME | sed 's/-//g')_app

  USERNAME=$(cat package.json | jq -r '.dockerHub.username')

  set +x
  annotate "Build Docker image."

  fig build
  docker tag ${FIG_NAME}:latest ${FIG_NAME}:${APP_VERSION}

  set +x
  annotate "Remove untagged images after Docker reuses repo:tag for new build."

  UNTAGGED=$(docker images --filter "dangling=true" -q)

  if [ ! -z "$UNTAGGED" ]; then
    docker rmi ${UNTAGGED};
  fi

  set +x
  annotate "Run mock tests including load test in Docker container."

  fig run -T --rm app grunt --no-color test
  fig stop
  fig rm --force

  set +x
  annotate "Retrieve build artifacts from Docker container."

  mkdir -p ./artifacts

  docker run --rm -v ${PWD}/artifacts:/mnt ${FIG_NAME}:${APP_VERSION} /bin/bash -c 'cp artifacts/* /mnt/.'

  ls -l ./artifacts

  set +x
  annotate "Tag Docker image for DockerHub."

  docker tag ${FIG_NAME}:${APP_VERSION} ${USERNAME}/${FIG_NAME}:${APP_VERSION}

  set +x
  annotate "Push Docker image to DockerHub."

  docker push ${USERNAME}/${FIG_NAME}:${APP_VERSION}

  set +x
  annotate "Remove tag added for DockerHub."

  docker rmi ${USERNAME}/${FIG_NAME}:${APP_VERSION}

  set +x
  annotate "Build complete."
}

annotate()
{
  desc=$1
  date=$(date)
  desc_len=${#desc}
  date_len=${#date}
  max_len=$(($desc_len > $date_len ? $desc_len : $date_len))
  dashes=$(eval printf -- '-%.s' {1..$max_len}; echo)
  echo
  echo "$dashes"
  echo "$desc"
  echo "$date"
  echo "$dashes"
  echo
  set -x
}

main "$@"

