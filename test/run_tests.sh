#/bin/bash

if [ -z "$1" ]; then
  TEST_IMAGE='jimsihk/codespace-oke-k8s:test'
else
  TEST_IMAGE="$1"
fi

echo "Testing ${TEST_IMAGE}"

echo "=====Image Size====="
echo "Uncompressed:"
docker images "${TEST_IMAGE}"
echo "Compressed:"
docker save "${TEST_IMAGE}" | gzip -c | wc -c | numfmt --to=iec-i --suffix=B --format="%9.2f"
echo "....."

echo "=====Test installed packages====="
docker run --rm -v $(pwd)/test_container.sh:/mnt/test.sh "${TEST_IMAGE}" "cp /mnt/test.sh test.sh && chmod +x test.sh && ./test.sh; echo \$?" > /tmp/test_result.txt 2>&1
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
