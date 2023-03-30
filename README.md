# GitHub Codespace for Oracle Cloud Container Engine for Kubernete

This repo bootstraps a GitHub Codespace with necessary softwares for interacting with Oracle Cloud Container Engine for Kubernetes (OKE):
- oci [(Oracle Cloud Infrastructure Command Line Interface)](https://docs.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm)
- git
- kubectl
- helm

This could also be used for interacting with other resources on Oracle Cloud Infrastructure (OCI).

The container image will be built daily to keep packages up-to-date.

[![Build](https://github.com/jimsihk/codespace-oke-k8s/actions/workflows/build.yml/badge.svg)](https://github.com/jimsihk/codespace-oke-k8s/actions/workflows/build.yml)

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
#### Create codespace
1. Create a file `.devcontainer/devcontainer.json` in your repo and create a GitHub codespace on the branch:
    ```
    {
      "image": "ghcr.io/jimsihk/codespace-oke-k8s:latest"
    }
    ```
#### Setup local environment for OKE
2. In the codespace, execute `/opt/okeutil/init-oci-local.sh` to setup OCI configuration and create API key
3. Copy the generated public key value and add as a key under the OCI user on OCI portal
4. In the codespace, execute `/opt/okeutil/init-oci-local.sh` again to further setup
    - Setup kubeconfig
    - Setup bastion session configuration with SSH key generation
5. In the codespace, execute `/opt/okeutil/check-oke-connection.sh && echo $?` for verification
    - when you see the prompt like below to add RSA key fingerprint, type `yes`:
      ```
      ...
      ...
      * Retrying in 5s...
      The authenticity of host 'host.bastion.eu-zurich-1.oci.oraclecloud.com (X.X.X.X)' can't be established.
      RSA key fingerprint is SHA256:abcd1234abcd1234abcd1234.
      Are you sure you want to continue connecting (yes/no/[fingerprint])?
      ```
    - if successfully connected to the tunnel, you should see below message
      ```
      ...
      ...
      * Connection is ready at Thu Mar 30 18:10:10 UTC 2023
      ```
    - and in the `nohup.out` in your repo workspace should show messages similar to below:
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
6. Verify the installed packages by executing below:
   - `oci -v`, sample output:
      ```
      [oracle@codespaces-a12345 ~]$ oci -v
      3.25.0
      ```
   - `git --version`, sample output:
      ```
      [oracle@codespaces-a12345 ~]$ git --version
      git version 2.31.1
      ```
   - `helm version`, sample output:
      ```
      oracle@codespaces-a12345 ~]$ helm version
      version.BuildInfo{Version:"v3.11.2", GitCommit:"912ebc1cd10d38d340f048efaf0abda047c3468e", GitTreeState:"clean", GoVersion:"go1.18.10"}
      ```
   - `kubectl version`, sample output:
     - _Note: will hang for a while if connection to OKE is not established_
      ```
      [oracle@codespaces-a12345 ~]$ kubectl version
      Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.3", GitCommit:"9e644106593f3f4aa98f8a84b23db5fa378900bd", GitTreeState:"clean", BuildDate:"2023-03-15T13:40:17Z", GoVersion:"go1.19.7", Compiler:"gc", Platform:"linux/amd64"}
      Kustomize Version: v4.5.7
      ...
      ...
      ```
7. The codespace is ready for interacting with OKE!

#### Optional Settings
8. Create Linux alias to replace `kubectl` with a customized version for OKE by executing `alias kubectl=/opt/okeutil/okectl`

## Add-on Commands 
`/opt/okeutil/init-oci-local.sh`
- initialize for the oci command, kubectl command and tunnel connection to OKE

`/opt/okeutil/oke-tunnel.sh`
- establish the SSH tunnel to the K8S API endpoint, run with `nohup /opt/okeutil/oke-tunnel.sh &` to establish the tunnel in the background

`/opt/okeutil/check-oke-connection.sh`
- check if the SSH tunnel has been established and establish if not
- tunnel connection log will be at _/workplaces/<repo_name>/nohup.out_ (or _$HOME/nohup.out_ if not on Github codespace)

`okectl` or `/opt/okeutil/okectl`
- same as `kubectl` and will detect if the tunnel has been established and establish if not

`oapply` or `/opt/okeutil/oapply`
- perform `kubectl apply -f` for all supplied yaml files
- detect if the tunnel has been established and establish if not
- e.g. `oapply pod1.yaml pod2.yaml` will apply both resource of pod1 and pod2

`odelete` or `/opt/okeutil/odelete`
- perform `kubectl delete -f` for all supplied yaml files
- detect if the tunnel has been established and establish if not
- e.g. `odelete pod1.yaml pod2.yaml` will delete both resource of pod1 and pod2

## Customization

### Source
Source files are under `.devdevcontainer/`

### Build from Source
To build your own image (for customization) when creating the codespace:
1. Copy the files in `.devcontainer/` from this repo to a new repo
2. Create a new codespace and it should automatically build from the Dockerfile

## Known Issues
1. Occasionally, the OKE tunnel will just cannot be established and hang:
    ```
    [oracle@codespaces-a12345 ~]$ /opt/okeutl/check-oke-connection.sh 
    Initiating connection to OKE cluster at Sat Mar 25 00:00:00 UTC 2023...
    nohup: appending output to 'nohup.out'
    * Retrying in 5s...
    * Retrying in 5s...
    * Retrying in 5s...
    * Retrying in 5s...
    * Retrying in 5s...
    ...
    ...
    ```
- at nohup.out:
    ```
    ...
    ...
    debug1: Host 'host.bastion.eu-zurich-1.oci.oraclecloud.com' is known and matches the RSA host key.
    debug1: Found key in /oracle/.ssh/known_hosts:1
    debug1: rekey out after 4294967296 blocks
    debug1: SSH2_MSG_NEWKEYS sent
    debug1: expecting SSH2_MSG_NEWKEYS
    debug1: SSH2_MSG_NEWKEYS received
    debug1: rekey in after 4294967296 blocks
    debug1: Will attempt key: /oracle/.ssh/id_rsa RSA SHA256:a12345678 explicit
    debug1: SSH2_MSG_SERVICE_ACCEPT received
    debug1: Authentications that can continue: publickey
    debug1: Next authentication method: publickey
    debug1: Offering public key: /oracle/.ssh/id_rsa RSA SHA256:a12345678 explicit
    debug1: Authentications that can continue: publickey
    debug1: No more authentication methods to try.
    ocid1.bastionsession.oc1.eu-zurich-1.a12345678@host.bastion.eu-zurich-1.oci.oraclecloud.com: Permission denied (publickey).
    ```
- Don't panic, just cancel the command (`Ctrl c`) and rerun, it would then work

## Credits
Based on [Oracle oci-cli Docker Image](https://github.com/oracle/docker-images/tree/main/OracleCloudInfrastructure/oci-cli)
