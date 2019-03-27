# This file is part of the liblognorm project, released under ASL 2.0

echo running test $0
../src/lognormalizer
if [ $? -eq 0 ]; then
    echo "FAIL: loganalyzer did not detect missing rulebase"
    exit 1
fi
../src/lognormalizer -r test -R test
if [ $? -eq 0 ]; then
    echo "FAIL: loganalyzer did not detect both -r and -R given"
    exit 1
fi
