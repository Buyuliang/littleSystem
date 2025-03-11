# littleSystem

## Build the build environment with docker
```bash
docker build -t ubuntu-22.04-build-env docker
```

```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

docker run --privileged -it \
    -v $PWD:/workspace \
    --mount type=bind,source=/dev,target=/dev \
    --mount type=bind,source=/etc/passwd,target=/etc/passwd \
    --mount type=bind,source=/etc/group,target=/etc/group \
    --mount type=bind,source=/etc/shadow,target=/etc/shadow \
    --mount type=bind,source=/etc/sudoers,target=/etc/sudoers \
    --user $UID:$GID \
    ubuntu-22.04-build-env
```
## into docker build
### uboot
```bash
./build.sh uboot az04
```

### kernel
```bash
./build.sh kernel az04
```

### alpine
```bash
./build.sh alpine az04
```

### image
```bash
./build.sh image az04
```

### all
```bash
all: uboot kernel alpine image
./build.sh all
```
