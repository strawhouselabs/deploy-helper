# docker-ci-submodule

### Steps for codeship Kubernetes setup

1. Create a new 'pro' (docker) project on codeship
2. Go to the repo for the project on github -> settings -> deploy keys, delete the codeship deploy key from here
3. Go to the codeship settings for the project you just made, find the "ssh key" for that codeship project
4. Log in to the strawhousedev github account, and add that key as a key for the strawhousedev user.
5. Copy `codeship-services.yml` and `codeship-steps.yml` from another repo (dashboard2 has a good one) and paste them into the top level of your project

Or manually add the services or steps below:
```
# codeship-services.yml

gcr_dockercfg:
  image: codeship/gcr-dockercfg-generator
  add_docker: true
  encrypted_env_file: docker/gcp.env.encrypted
  cached: false
googleclouddeployment:
  build:
    image: deploy
    dockerfile_path: docker/deploy-helper/Dockerfile.deploy
    build: .
  encrypted_env_file: docker/gcp.env.encrypted
  # Add Docker if you want to interact with the Google Container Engine and Google Container Registry
  add_docker: true
  volumes:
  - ./docker/kubernetes:/deploy/kubernetes
```
```
# codeship-steps.yml

- name: push-image
  service: app
  type: push
  image_name: "gcr.io/strawhouse-internals/infrabot-ecomm"
  image_tag: "{{.Branch}}.{{.CommitDescription}}"
  registry: https://gcr.io
  dockercfg_service: gcr_dockercfg
  tag: ^(production|staging)
- name: deploy
  service: googleclouddeployment
  command: /deploy/deploy_to_kubernetes_cron.sh
```

6. Create a `dockerfile.app` in the docker folder and set it up appropriately for your app to run (see dashboard2/herschel for an example)
7. Create a docker-compose.local if you need one in the docker folder (you probably do)
8. Create a test.sh at the root of your project that includes the database polling code seen in dashboard2/herschel
9. Copy the key.aes from codeships project settings into your docker file 
10. Copy the gcp.env from dashboard2 into your projects docker folder
11. `cd docker && jet encrypt gcp.env gcp.env.encrypted --key-path=key.aes`
12. delete the gcp.env
13. create a folder called `kubernetes` in the docker folder
14. into your new kubernetes folder create the following:
  - configmap.production.yaml
  - configmap.staging.yaml
  - nodeport-service.yaml
  - deployment.template.yaml

  checkout [kubernetes-shared-config](https://github.com/strawhouselabs/kubernetes-shared-config) for examples.

15. deploy
