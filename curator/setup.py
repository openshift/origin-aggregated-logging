from setuptools import setup, find_packages

setup(
    name='oal-curator-util',
    version='0.1',
    description='Converts OpenShift Logging curator config file to curator actions file',
    author='OpenShift Development',
    author_email='dev@lists.openshift.redhat.com',
    package_dir={'': 'lib'},
    packages=find_packages('lib'),
    setup_requires=['pytest-runner'],
    tests_require=['pytest', 'mock', 'ruamel.yaml'],
    test_suite="test"
)
