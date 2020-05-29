# Updating the vendors file

* Create virtual environment
```
virtualenv venv
source venv/bin/activate
```

* Install elasticsearch-curator
```
pip install elasticsearch-curator.tar.gz
```

* Download each dependency to the vendor directory
```
 pip download -r requirements.txt -d vendor
```

* Update manifest
```
pip freeze > rh-manifest.txt
```
