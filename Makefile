VAULT_PASSWORD_FILE ?= .vault_password

.PHONY: install prepare setup deploy monitoring check vault-edit vault-view

install:
	ansible-galaxy install -r requirements.yml

prepare: install
	@test -f "$(VAULT_PASSWORD_FILE)" || (echo "$(VAULT_PASSWORD_FILE) is required" && exit 1)
	ansible-playbook -i inventory.ini playbook.yml --tags prepare --vault-password-file "$(VAULT_PASSWORD_FILE)"

setup: prepare

deploy:
	@test -f "$(VAULT_PASSWORD_FILE)" || (echo "$(VAULT_PASSWORD_FILE) is required" && exit 1)
	ansible-playbook -i inventory.ini playbook.yml --tags deploy --vault-password-file "$(VAULT_PASSWORD_FILE)"

monitoring: install
	@test -f "$(VAULT_PASSWORD_FILE)" || (echo "$(VAULT_PASSWORD_FILE) is required" && exit 1)
	ansible-playbook -i inventory.ini playbook.yml --tags monitoring --vault-password-file "$(VAULT_PASSWORD_FILE)"

check:
	ansible-playbook -i inventory.ini playbook.yml --syntax-check --vault-password-file "$(VAULT_PASSWORD_FILE)"

vault-edit:
	@test -f "$(VAULT_PASSWORD_FILE)" || (echo "$(VAULT_PASSWORD_FILE) is required" && exit 1)
	ansible-vault edit group_vars/webservers/vault.yml --vault-password-file "$(VAULT_PASSWORD_FILE)"

vault-view:
	@test -f "$(VAULT_PASSWORD_FILE)" || (echo "$(VAULT_PASSWORD_FILE) is required" && exit 1)
	ansible-vault view group_vars/webservers/vault.yml --vault-password-file "$(VAULT_PASSWORD_FILE)"
