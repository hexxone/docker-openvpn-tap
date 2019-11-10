# OpenVPN using TAP-MODE for Docker

Modified Version of kylemanna/docker-openvpn to run in TAP Mode with compose.

* Docker Registry @ [kylemanna/openvpn](https://hub.docker.com/r/kylemanna/openvpn/)
* GitHub @ [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn)

The base image was changed from Alpine to ArchLinux for easy network interface configuration and sysctl access.

At this point a Linux-Docker-Host is mandatory.

## TODO

* if in-container bridge setup is not possible, maybe hand the /dev/docker0 bridge directly into the container?



## Quick Start

* git clone this project

* IMPORTANT: Modify your hostname/udp port in the `.env` file 
  and perhaps the network/ip-configuration `actual_openvpn.conf` to fit your needs

* `chmod +x install.sh create_client.sh revoke_client.sh`

* run `install.sh` to setup the docker-compose image, and start it.
  this will also setup and prompt for the CA password several times.

* run `./create_client <cname>` to create the certificate for a user.
  This will prompt for the CA password in order to sign a new key for the user.
  the certificate will also be exported to the local `./clients` folder.

* run `docker-compose run docker_openvpn_tap bash` to enter the container with interactive shell.
  From there use `ifconfig -a` and `cat /etc/network/interfaces` to compare the ip config.
  At the moment the `br0` NOT receiving an IP address and NOT able to connect outside.


## How Does It Work?

Scroll down to "differences" for more details on how this container is put together.

Initialize the docker-compose stack using the `install.sh` script to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `-v` argument, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `kylemanna/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, this stack comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.


## OpenVPN Details

The original images uses `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device is rooted.

However if you want to have advanced features like LAN-Play you need to use `tap`
in order to have broadcast discovery packets sent to all devies.

## Security Discussion

Sadly this container enables the possibility of ARP poisoning, thats why you should
only let trusted devices be a part of this network.

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image and the script [`ovpn_copy_server_files`](/docs/paranoid.md) to accomplish this).
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to be signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Benefits of Running Inside a Docker Container

### The Entire Daemon and Dependencies are in the Docker Image

This means that it will function correctly (after Docker itself is setup) on
all distributions Linux distributions such as: Ubuntu, Arch, Debian, Fedora,
etc.  Furthermore, an old stable server can run a bleeding edge OpenVPN server
without having to install/muck with library dependencies (i.e. run latest
OpenVPN with latest OpenSSL on Ubuntu 12.04 LTS).

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two folders:
* `clients/` for all the created certificates

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.


## Differences from kylemanna/docker-openvpn

* OTP/PAM NOT suported anymore (I dont know how it worked in the first place tbh)

* custom `ovpn_genconfig_tap` and `ovp_run_tap` scripts which do some special setup on container start.

* Container will automatically create the `openvpn.conf` on startup if the `ovpn_env.sh`
  doesn't exist in `/etc/openvpn`. This will NOT automatically create the certificates.

* No longer uses docker volume but local file dir & mount.
  I prefer it this way, so if my server dies for some reason I can still recover the data without docker.

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

## Tested On

* Docker hosts:
  * Ubuntu16 rootserver (32gb ram, 8core)
* Clients
  * Windows OpenVPN Connect V3 Beta

