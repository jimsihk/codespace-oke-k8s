# GitHub Codespace for Oracle Cloud Container Engine for Kubernete

This repo bootstraps a GitHub Codespace with necessary softwares for interacting with Oracle Cloud Container Engine for Kubernetes (OKE):
- oci cli
- git
- kubectl
- helm

This could also be used for interacting with other resources on Oracle Cloud.

## How to use in GitHub Codespace

### Pre-requisite
1. Create an Oracle Cloud account
2. Create an OKE cluster
3. Create a bastion
4. Create a dedicated IAM user (recommended)
5. Create required groups and IAM policies for this user, e.g.
```
Allow group 'Default'/'OKE Accounts' to manage cluster in tenancy where target.cluster.id = '<your_cluster_ocid>'

Allow group 'Default'/'Bastion Accounts' to manage bastion-session in tenancy
Allow group 'Default'/'Bastion Accounts' to use bastion in tenancy
Allow group 'Default'/'Bastion Accounts' to read instances in tenancy
Allow group 'Default'/'Bastion Accounts' to read subnets in tenancy
Allow group 'Default'/'Bastion Accounts' to read vcns in tenancy
```
Note: here assumes a private cluster is created so bastion is required

### Setup
1. Create a file `.devcontainer/devcontainer.json` in your repo and create a GitHub codespace on the branch:
```
{
  "image": "ghcr.io/jimsihk/codespace-oke-k8s:latest"
}
```
2. In the codespace, execute `/opt/okeutil/init-oci-local.sh` to
- Setup oci configuration and create API key
- Setup kubeconfig
- Setup bastion session configuration with SSH key generation
3. In the codespace, execute `/opt/okeutil/oke-tunnel.sh` for verification and adding the fingerprint for the first time, you should see something like this:
```
...
...
Authenticated to host.bastion.eu-zurich-1.oci.oraclecloud.com ([X.X.X.X]:22) using "publickey".
debug1: Local connections to LOCALHOST:6443 forwarded to remote address Y.Y.Y.Y:6443
debug1: Local forwarding listening on ::1 port 6443.
debug1: channel 0: new [port listener]
debug1: Local forwarding listening on 127.0.0.1 port 6443.
debug1: channel 1: new [port listener]
debug1: Entering interactive session.
debug1: pledge: filesystem
```
4. In the codespace, execute `/opt/okeutil/check-oke-connection.sh && echo $?` and it should return 0 if successful
5. The codespace is ready for interacting with OKE!

### Usage
`/opt/okeutil/init-oci-local.sh` - initialize the oci command, kubectl command and tunnel connection

`/opt/okeutil/oke-tunnel.sh` - establish the SSH tunnel to the K8S API endpoint

`/opt/okeutil/check-oke-connection.sh` - check if the SSH tunnel has been established

`/opt/okeutil/apply` - same as `kubectl apply` but will detect if the tunnel has been established and establish if not

`/opt/okeutil/delete` - same as `kubectl delete` but will detect if the tunnel has been established and establish if not

## Customization

### Source
Source files are under `.devdevcontainer/`

### Build from Source
To build your own image (for customization) when creating the codespace:
1. Copy the files in `.devcontainer/` from this repo to a new repo
2. Create a new codespace and it should automatically build from the Dockerfile

## Credits
Based on [Oracle oci-cli Docker Image](https://github.com/oracle/docker-images/tree/main/OracleCloudInfrastructure/oci-cli)
