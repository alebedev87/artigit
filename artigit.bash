#! /bin/bash

set -e
set -o pipefail

: "${ARTIFACTORY_URL:?No Artifactory URL provided}"
: "${ARTIFACTORY_USER:?No Artifactory user provided}"
: "${ARTIFACTORY_PASSWORD:?No Artifactory password provided}"
: "${ARTIFACTORY_MIRROR_DIR:?No Artifactory mirror directory provided}"
: "${GIT_URL:?No Git URL provided}"
: "${GIT_USER:?No Git user provided}"
: "${GIT_PASSWORD:?No Git password provided}"
: "${GIT_REPOSITORY:?No Git repository provided}"
: "${GOGS_BOOTSTRAP:=false}"
WORK_DIR="mirror"

if [ "${GOGS_BOOTSTRAP}" == "true" ]; then
    echo "=> Configuring Git server"
    # impossible to bootstrap admin user using Gogs REST API
    GIT_SIGNUP_DATA="{\"username\":\"${GIT_USER}\",\"email\":\"${GIT_USER}@example.com\",\"password\":\"${GIT_PASSWORD}\", \"retype\":\"${GIT_PASSWORD}\"}"
    echo -n "=> Creating admin user: "
    curl -s -w "%{http_code}" -o /dev/null -L -H "Content-Type:application/json" -X POST ${GIT_URL}/user/sign_up -d "${GIT_SIGNUP_DATA}" && echo
    GIT_REPO_DATA="{\"name\":\"${GIT_REPOSITORY}\",\"description\":\"Mirror of my repository\"}"
    echo -n "=> Creating repository: "
    curl -s -w "%{http_code}" -o /dev/null -L -H "Content-Type:application/json" -X POST -u ${GIT_USER}:${GIT_PASSWORD} ${GIT_URL}/api/v1/admin/users/${GIT_USER}/repos -d "${GIT_REPO_DATA}" && echo
fi

if [ -d "${WORK_DIR}" ]; then
    PREV_MIRROR_PATH="$(find ${WORK_DIR} -maxdepth 1 | tail -1)"
    echo "=> Previous mirror checksum: $(sha1sum ${PREV_MIRROR_PATH} | cut -d ' ' -f1)"
    echo "=> Cleaning previous mirror directory"
    rm -rf "${WORK_DIR}"
else
    mkdir -p "${WORK_DIR}"
fi

# Jfrog client doc: https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory
echo "=> Configuring Jfrog client"
jfrog rt c rtserver --interactive=false --url="${ARTIFACTORY_URL}" --user="${ARTIFACTORY_USER}" --password="${ARTIFACTORY_PASSWORD}"

echo "=> Downloading the mirror from Artifactory"
jfrog rt dl --sort-by=created --sort-order=desc --limit=1 --fail-no-op --flat=true "${ARTIFACTORY_MIRROR_DIR}" ${WORK_DIR}/

echo "=> Unpacking the mirror"
MIRROR_PATH="$(find ${WORK_DIR} -maxdepth 1 | tail -1)"
echo "=> Mirror checksum: $(sha1sum ${MIRROR_PATH} | cut -d ' ' -f1)"
tar -xzf "${MIRROR_PATH}" -C "${WORK_DIR}"

echo "=> Stepping into unpacked directory"
UNPACK_MIRROR_PATH="$(tar -tf ${MIRROR_PATH} | head -1 || true)"
cd "${WORK_DIR}/${UNPACK_MIRROR_PATH}"

echo "=> Pushing the mirror to Git repository"
GIT_URL=$(sed -r "s|^(https?)://(.*)|\1://${GIT_USER}:${GIT_PASSWORD}@\2|" <<<"${GIT_URL}")
git push --mirror ${GIT_URL}/${GIT_USER}/${GIT_REPOSITORY}.git
