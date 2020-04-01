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

* List installed dependecies
```
pip list
```

* Download each dependency to the vendor directory

* Update manifest
```
pip freeze > rh-manifest.txt
```
