# Primitive Artifactory to Git replicator
Synchronizes a git mirror stored in Artifactory into a given Git repository.

## Build image
```bash
$ VERSION="1.0.0"
$ docker build -t artigit:${VERSION} -f image/Dockerfile .
```

## Publish image
```bash
$ REGISTRY="registry-1.docker.io/myuser"
$ docker tag artigit:${VERSION} ${REGISTRY}/artigit:${VERSION}
$ docker login ${REGISTRY}
$ docker push ${REGISTRY}/artigit:${VERSION}
```

## Deploy Helm chart <a name="deploy"></a>
Deploy Helm chart with custom parameters:
```bash
$ cat - > agvalues.yaml <<EOF
job:
  image: "registry-1.docker.io/myuser/artigit"
  imageTag: ${VERSION}
artifactory:
  url: "https://my-artifactory-instance.com"
  mirrorDir: "my-project/my-component/mirrors/"
  credentials:
    username: ${ARTIFACTORY_USER}
    password: ${ARTIFACTORY_PASSWORD}
git:
  url: "http://gogs-gogs"
  credentials:
    username: ${GIT_USER}
    password: ${GIT_PASSWORD}
gogsBootstrap: true
EOF

$ helm install -f agvalues.yaml artigit charts/artigit
```
