# SFTP

![OpenSSH logo](https://raw.githubusercontent.com/thar/sftpminiogateway/master/openssh.png "Powered by OpenSSH")

# Securely share your files

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH) to ([MinIO](https://min.io)) gateway.

# Usage

- Define users in (1) command arguments, (2) `SFTP_USERS` environment variable
  or (3) in file mounted as `/etc/sftp/users.conf` (syntax:
  `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]] ...`, see below for examples)
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Directory names at the end will be created under user's home directory with
    write permission, if they aren't already present.
- Mount volumes
  - The users are chrooted to their home directory, so you can mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**) or just mount the whole **/home** directory.
    Just remember that the users can't create new files directly under their
    own home directory, so make sure there are at least one subdirectory if you
    want them to upload files.
  - For consistent server fingerprint, mount your own host keys (i.e. `/etc/ssh/ssh_host_*`)
- Define MinIO server in `MINIO_URL`, `MINIO_ACCESS_KEY` and `MINIO_SECRET_KEY` environment variables

# Examples

## Simplest docker run example

```
docker run -p 2222:22 -d --env MINIO_URL=http://localhost:9000 --env MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE --env MINIO_SECRET_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY thar/sftpminiogateway foo:pass:::foobucket
```

User "foo" with password "pass" can login with sftp and upload files to a folder called "foobucket". The files will be backed up automatically to a bucket with name "foobucket" in the MinIO server.

### Using Docker Compose:

```
sftp:
    image: thar/sftpminiogateway
    environment:
        - MINIO_URl=http://localhost:9000
        - MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
        - MINIO_SECRET_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY
    ports:
        - "2222:22"
    command: foo:pass:::foobucket
```

### Logging in

The OpenSSH server runs by default on port 22, and in this example, we are forwarding the container's port 22 to the host's port 2222. To log in with the OpenSSH client, run: `sftp -P 2222 foo@<host-ip>`

## Store users in config

```
docker run \
    -v /host/users.conf:/etc/sftp/users.conf:ro \
    -p 2222:22 -d thar/sftpminiogateway
```

/host/users.conf:

```
foo:123:1001:100:foobucket
bar:abc:1002:100:barbucket
baz:xyz:1003:100:bazbucket
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    --env MINIO_URL=http://localhost:9000 \
    --env MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE \
    --env MINIO_SECRET_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY \
    -p 2222:22 -d thar/sftpminiogateway \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e::foobucket'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Logging in with SSH keys

Mount public keys in the user's `.ssh/keys/` directory. All keys are automatically appended to `.ssh/authorized_keys` (you can't mount this file directly, because OpenSSH requires limited file permissions). In this example, we do not provide any password, so the user `foo` can only login with his SSH key.

```
docker run \
    -v /host/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v /host/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    --env MINIO_URL=http://localhost:9000 \
    --env MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE \
    --env MINIO_SECRET_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY \
    -p 2222:22 -d thar/sftpminiogateway \
    foo::::foobucket
```

## Providing your own SSH host key (recommended)

This container will generate new SSH host keys at first run. To avoid that your users get a MITM warning when you recreate your container (and the host keys changes), you can mount your own host keys.

```
docker run \
    -v /host/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
    -v /host/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
    --env MINIO_URL=http://localhost:9000 \
    --env MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE \
    --env MINIO_SECRET_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY \
    -p 2222:22 -d thar/sftpminiogateway \
    foo::::foobucket
```

Tip: you can generate your keys with these commands:

```
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
```

