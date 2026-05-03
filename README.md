# GitHub Codespace for Oracle Container Engine for Kubernetes

This repository provides a GitHub Codespaces / devcontainer image for working with Oracle Cloud Infrastructure (OCI) and Oracle Container Engine for Kubernetes (OKE), especially private clusters that require a bastion tunnel.

## Included tools

The published image includes:
- [OCI CLI](https://docs.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm)
- `kubectl`
- `helm`
- [k9s](https://k9scli.io)
- [kdash](https://github.com/kdash-rs/kdash)
- `git`, `curl`, `bash`, and SSH client tooling
- OKE helper scripts under `/opt/okeutil`, added to `PATH`

The current image is built from Alpine, uses a multi-stage Docker build, pins tool and package versions in `.devcontainer/Dockerfile`, and uses Renovate to keep those pinned versions up to date.

## Prerequisites

Before using the image against OKE, prepare:
1. An Oracle Cloud account
2. An OKE cluster
3. A bastion
4. A dedicated IAM user (recommended)
5. IAM groups and policies for that user, for example:

```text
Allow group 'Default'/'OKE Accounts' to manage cluster in tenancy where target.cluster.id = '<your_cluster_ocid>'

Allow group 'Default'/'Bastion Accounts' to manage bastion-session in tenancy
Allow group 'Default'/'Bastion Accounts' to use bastion in tenancy
Allow group 'Default'/'Bastion Accounts' to read instances in tenancy
Allow group 'Default'/'Bastion Accounts' to read subnets in tenancy
Allow group 'Default'/'Bastion Accounts' to read vcns in tenancy
```

If your OKE cluster uses a private endpoint, the bastion is required for access.

## Use in GitHub Codespaces

### 1. Create a Codespace that uses the published image

Create `.devcontainer/devcontainer.json` in your own repository:

```json
{
  "image": "ghcr.io/jimsihk/codespace-oke-k8s:latest"
}
```

Then create a GitHub Codespace on the branch you want to use.

### 2. Initialize OCI locally in the Codespace

Run:

```bash
init-local-oci.sh
```

On the first run, the script delegates to `oci setup config`, creates your local OCI configuration, and generates an API key pair. After that:
- copy the generated public key
- add it as an API key for your OCI user in the OCI Console
- rerun `init-local-oci.sh`

On a follow-up run, the script can:
- update the OCI region in `~/.oci/config`
- optionally create `~/.kube/config` for an OKE cluster when you answer `Y`
- rewrite the kubeconfig server endpoint to `https://127.0.0.1:6443`
- create `~/.oci/custom-bastion-config`
- generate the SSH key used for the bastion tunnel

### 3. Verify cluster connectivity

Run:

```bash
check-oke-connection.sh
```

If the tunnel is not ready, the script starts it in the background and retries until `kubectl get nodes` succeeds.

Tunnel logs are written to:
- `/workspaces/<repo_name>/nohup.out` in GitHub Codespaces
- `$HOME/nohup.out` outside GitHub Codespaces

If SSH prompts you to trust the bastion host key, answer `yes`.

### 4. Verify the installed tools

Examples:

```bash
oci --version
git --version
helm version
kubectl version
```

`kubectl version` may wait if the OKE tunnel is not established yet.

### 5. Optional aliases

If you want the tunnel-aware wrappers to replace the default binaries in your shell:

```bash
alias kubectl=/opt/okeutil/okectl
alias helm=/opt/okeutil/ohelm
```

## Helper commands

The image ships helper commands in `/opt/okeutil`, and the container adds that directory to `PATH`.

| Command | Purpose |
| --- | --- |
| `init-local-oci.sh` | Initializes OCI config, optional kubeconfig, bastion settings, and SSH keys |
| `oke-tunnel.sh` | Starts the SSH tunnel to the Kubernetes API endpoint |
| `check-oke-connection.sh` | Verifies cluster access and starts the tunnel when needed |
| `okectl` | Runs `kubectl` after ensuring the OKE tunnel is ready |
| `ohelm` | Runs `helm` after ensuring the OKE tunnel is ready |
| `oapply` | Runs `kubectl apply -f` for each supplied file or URL after ensuring connectivity |
| `odelete` | Runs `kubectl delete -f` for each supplied file or URL after ensuring connectivity |
| `ssh2pod` | Opens a shell in the latest running pod that matches a name keyword |
| `getpodlog` | Shows logs from the latest running pod that matches a name keyword |

### Pod helpers

Examples:

```bash
ssh2pod api default
getpodlog api default
getpodlog api default app-container
```

Notes:
- `ssh2pod` defaults the namespace to `default` if you omit it
- `getpodlog` requires both pod keyword and namespace
- both commands select the latest matching running pod

## Customization and local build

Source files for the image live under `.devcontainer/`.

To build the image locally from this repository:

```bash
docker build -t codespace-oke-k8s:test .devcontainer
```

To validate the built image with the repository test flow:

```bash
cd test
./run_tests.sh codespace-oke-k8s:test
```

## Known issue

Sometimes bastion authentication can fail while the tunnel is starting and the connection will keep retrying. If that happens, stop the command and rerun it.

## Credits

Based on the [Oracle oci-cli Docker image](https://github.com/oracle/docker-images/tree/main/OracleCloudInfrastructure/oci-cli) for the original v1 images.
