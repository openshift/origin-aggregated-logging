curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"

unset NPM_CONFIG_PREFIX

cd vendored_tar_src/security-kibana-plugin-0.10.0.4/
./build.sh 6.8.1 0.10.0.4 install

export NPM_CONFIG_PREFIX=/opt/app-root/src/.npm-global
#mv $HOME/plugins/security-kibana-plugin-0.10.0.4/build/kibana/opendistro_security_kibana_plugin-0.10.0.4/ $HOME/plugins/opendistro_security_kibana_plugin-0.10.0.4/
#rm -rf $HOME/plugins/security-kibana-plugin-0.10.0.4

# => Appending nvm source string to /home/ewolinetz/.bashrc
# => Appending bash_completion source string to /home/ewolinetz/.bashrc