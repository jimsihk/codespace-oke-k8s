#/bin/bash

if [ -z "$1" ]; then
  TEST_IMAGE='jimsihk/codespace-oke-k8s:test'
else
  TEST_IMAGE="$1"
fi

echo "Testing ${TEST_IMAGE}"

echo "Test installed packages..."
docker run --rm -v $(pwd)/test_container.sh:/mnt/test.sh "${TEST_IMAGE}" "cp /mnt/test.sh test.sh && chmod +x test.sh && ./test.sh; echo \$?" > /tmp/test_result.txt 2>&1
echo "---"
cat /tmp/test_result.txt
echo "---"
STATUS="$(cat /tmp/test_result.txt | tail -1)"
if [ "${STATUS}" -eq 0 ]; then
  echo "Passed"
else
  echo "Failed"
  exit "${STATUS}"
fi
unset STATUS

echo "Test entrypoint..."
docker run --rm --name t_entrypt -d "${TEST_IMAGE}"
sleep 60
docker logs --details t_entrypt
docker kill t_entrypt
