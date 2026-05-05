#!/bin/bash

set -eo pipefail

echo '*' "Started at $(date)"

echo '*' "Current user: $(whoami)"
echo '*' "Current directory: $(pwd)"

PASS_COUNT=0
FAIL_COUNT=0

# Creates a mock environment and runs oke-tunnel.sh with a fake session ID.
# Arguments:
#   $1 - test name
#   $2 - SSH stderr output to simulate
#   $3 - SSH_RETRY_ON_TIMEOUT config value (true/false)
#   $4 - expected exit code
#   $5 - expected pattern in combined output (grep -qE)
run_retry_test() {
    local test_name="$1"
    local ssh_stderr_output="$2"
    local retry_on_timeout="$3"
    local expected_exit="$4"
    local expected_pattern="$5"

    echo '****************'
    echo "* Test: $test_name"

    TEST_HOME=$(mktemp -d)
    MOCK_BIN="$TEST_HOME/mock_bin"
    mkdir -p "$TEST_HOME/.oci" "$TEST_HOME/.ssh" "$MOCK_BIN"

    # Dummy SSH keys (quiet, ignore errors from set -e)
    ssh-keygen -q -b 2048 -t rsa -N '' -f "$TEST_HOME/.ssh/id_rsa_oci" 2>/dev/null || true
    chmod 600 "$TEST_HOME/.ssh/id_rsa_oci" || true
    chmod 600 "$TEST_HOME/.ssh/id_rsa_oci.pub" || true

    # custom-bastion-config
    cat > "$TEST_HOME/.oci/custom-bastion-config" <<CONF
BASTION_ID=ocid1.bastion.oc1..testbastion
TARGET_IP=0.0.0.0
PRIVATE_KEY=$TEST_HOME/.ssh/id_rsa_oci
PUBLIC_KEY=$TEST_HOME/.ssh/id_rsa_oci.pub
SSH_RETRY_ON_TIMEOUT=$retry_on_timeout
CONF

    # Mock oci: returns a session JSON with a known SSH template for any subcommand
    cat > "$MOCK_BIN/oci" <<'MOCK'
#!/bin/bash
echo '{"data": {"ssh-metadata": {"command": "ssh -i <privateKey> -o StrictHostKeyChecking=no -p 22 -N -L <localPort>:0.0.0.0:6443 testuser@host.bastion.test.oci.oraclecloud.com"}, "time-created": "2024-01-01T00:00:00+00:00", "lifecycle-state": "ACTIVE"}}'
MOCK
    chmod +x "$MOCK_BIN/oci"

    # Mock ssh: writes specified output to stderr and exits 255 (simulating failure)
    cat > "$MOCK_BIN/ssh" <<MOCK
#!/bin/bash
echo "$ssh_stderr_output" >&2
exit 255
MOCK
    chmod +x "$MOCK_BIN/ssh"

    # No-op mocks for commands that would block or are irrelevant in tests
    for cmd in clear pgrep kill sleep; do
        printf '#!/bin/bash\nexit 0\n' > "$MOCK_BIN/$cmd"
        chmod +x "$MOCK_BIN/$cmd"
    done

    actual_exit=0
    OUTPUT=$(HOME="$TEST_HOME" PATH="$MOCK_BIN:$PATH" oke-tunnel.sh "ocid1.bastionsession.oc1..testsession" 2>&1) \
        || actual_exit=$?

    rm -rf "$TEST_HOME"

    if [ "$actual_exit" -eq "$expected_exit" ] && echo "$OUTPUT" | grep -qE "$expected_pattern"; then
        echo "* PASS: $test_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "* FAIL: $test_name"
        echo "  Expected exit=$expected_exit, got=$actual_exit"
        echo "  Expected output matching: $expected_pattern"
        echo "  Actual output:"
        echo "$OUTPUT" | sed 's/^/    /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo '****************'
echo '* Testing SSH retry classification logic in oke-tunnel.sh:'

# Test 1: "No more authentication methods to try" always retries (exhausts all attempts)
run_retry_test \
    "auth_failure_no_more_methods_always_retries" \
    "debug1: No more authentication methods to try." \
    "true" \
    1 \
    "SSH tunnel failed after"

# Test 2: "Permission denied (publickey)" always retries (exhausts all attempts)
run_retry_test \
    "auth_failure_permission_denied_always_retries" \
    "testuser@host.bastion.test.oci.oraclecloud.com: Permission denied (publickey)." \
    "true" \
    1 \
    "SSH tunnel failed after"

# Test 3: Session timeout retries when SSH_RETRY_ON_TIMEOUT=true (exhausts all attempts)
run_retry_test \
    "timeout_retries_when_ssh_retry_on_timeout_is_true" \
    "debug1: channel 0: open failed: connect failed: Connection timed out" \
    "true" \
    1 \
    "SSH tunnel failed after"

# Test 4: Session timeout stops immediately when SSH_RETRY_ON_TIMEOUT=false
run_retry_test \
    "timeout_stops_when_ssh_retry_on_timeout_is_false" \
    "debug1: channel 0: open failed: connect failed: Connection timed out" \
    "false" \
    1 \
    "SSH_RETRY_ON_TIMEOUT=false"

# Test 5: Unrecognized error stops immediately without retrying
run_retry_test \
    "unrecognized_error_stops_immediately" \
    "debug1: some unexpected unrecognized ssh error occurred" \
    "true" \
    1 \
    "unretryable error"

echo '****************'
echo "* Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [ $FAIL_COUNT -gt 0 ]; then
    echo "* Some tests FAILED"
    exit 1
fi

echo '*' "Completed at $(date)"
