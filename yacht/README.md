# Yacht
Periodic pre-emptive index pre-creation for Elasticsearch

### Installation
This is very first version.
Either build locally
```
docker build -t yacht -f Dockerfile.centos7 .
```
Or pull from docker hub
```
docker pull jkarasek/yacht
```

Use this *deployment* for deploying on OpenShift
```
oc create -f https://gist.githubusercontent.com/josefkarasek/682114ccef0c5709bc1e590109adcf6a/raw/409015b86a0b80bcfd10cd37709d926c7a812451/yacht-pod.yaml
```