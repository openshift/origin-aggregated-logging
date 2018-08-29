FROM ansibleplaybookbundle/apb-base

LABEL "com.redhat.apb.spec"=\
""

COPY playbooks /opt/apb/actions
COPY roles /opt/ansible/roles
USER apb
