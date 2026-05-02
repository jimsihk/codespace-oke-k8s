#/bin/bash

if [ -z "$1" ]; then
  TEST_IMAGE='jimsihk/codespace-oke-k8s:test'
else
  TEST_IMAGE="$1"
fi

TEST_SECTION="${2:-all}"

echo "Testing ${TEST_IMAGE} (section: ${TEST_SECTION})"

run_size_test() {
  echo "=====Image Size====="
  echo "Uncompressed image size: $(docker images "${TEST_IMAGE}" --format "{{.Size}}")" > /tmp/image_size.txt 2>&1
  echo "Compressed image size: $(docker save "${TEST_IMAGE}" | gzip -c | wc -c | numfmt --to=iec-i --suffix=B --format="%9.2f")" >> /tmp/image_size.txt 2>&1
  cat /tmp/image_size.txt
  echo "....."
}

run_packages_test() {
  echo "=====Test installed packages====="
  docker run --rm \
    -v $(pwd)/test_packages.sh:/mnt/test.sh \
    "${TEST_IMAGE}" \
    "cp /mnt/test.sh test.sh && chmod +x test.sh && ./test.sh; echo \$?" > /tmp/test_result.txt 2>&1
  cat /tmp/test_result.txt
  STATUS="$(cat /tmp/test_result.txt | tail -1)"
  if [ "${STATUS}" -eq 0 ]; then
    echo "Passed"
  else
    echo "Failed"
    exit "${STATUS}"
  fi
  unset STATUS
  echo "....."
}

run_scripts_test() {
  echo "=====Test custom scripts====="
  docker network create data-network
  echo "Start oci-emulator..."
  OCI_CONTAINER_ID=$(docker run --rm -d -p 12000:12000 --name oci-emulator --net=data-network cameritelabs/oci-emulator:latest)
  docker run --rm \
    --net=data-network \
    -v $(pwd)/test_container.sh:/mnt/test.sh \
    --env OCI_CLI_ENDPOINT="http://oci-emulator:12000" \
    "${TEST_IMAGE}" \
    "cp /mnt/test.sh test.sh && chmod +x test.sh && ./test.sh; exit \$?"
  STATUS="$?"
  if [ "${STATUS}" -eq 0 ]; then
    echo "Passed"
  else
    echo "Failed"
    docker kill "${OCI_CONTAINER_ID}"
    exit "${STATUS}"
  fi
  unset STATUS
  echo "Clean oci-emulator"
  docker kill "${OCI_CONTAINER_ID}"
  echo "....."
}

run_entrypoint_test() {
  echo "=====Test entrypoint====="
  CONTAINER_ID=$(docker run --rm -d "${TEST_IMAGE}")
  docker ps
  docker logs --details "${CONTAINER_ID}"
  echo "Wait for 10s..." && sleep 10
  docker ps
  docker logs --details "${CONTAINER_ID}"
  echo "Wait for 30s..." && sleep 30
  docker ps
  docker logs --details "${CONTAINER_ID}"
  echo "Kill the container..."
  docker kill "${CONTAINER_ID}"
  echo "....."
}

case "${TEST_SECTION}" in
  size)
    run_size_test
    ;;
  packages)
    run_packages_test
    ;;
  scripts)
    run_scripts_test
    ;;
  entrypoint)
    run_entrypoint_test
    ;;
  all)
    run_size_test
    run_packages_test
    run_scripts_test
    run_entrypoint_test
    ;;
  *)
    echo "Unknown test section: ${TEST_SECTION}"
    echo "Usage: $0 IMAGE [all|size|packages|scripts|entrypoint]"
    exit 1
    ;;
esac
