#/bin/bash

if [ -z "$1" ]; then
  TEST_IMAGE='jimsihk/codespace-oke-k8s:test'
else
  TEST_IMAGE="$1"
fi

echo "Testing ${TEST_IMAGE}..."

docker run --rm -v $(pwd)/test/test_container.sh:/mnt/test.sh "${TEST_IMAGE}" "cp /mnt/test.sh test.sh && chmod +x test.sh && ./test.sh; echo \$?" > /tmp/test_result.txt 2>&1
echo "---"
cat /tmp/test_result.txt
echo "---"
STATUS="$(cat /tmp/test_result.txt | tail -1)"
exit "${STATUS}"
