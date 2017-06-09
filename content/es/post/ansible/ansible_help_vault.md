---
date: 2017-06-09T20:06:24-03:00
title: Ansible Vault ES
type: index
menu:
  main:
    parent: ansible
    identifier: ansible_vault_es
    weight: 0
---
h1. Vault passwords

Por seguridad utilizamos ansible-vault para guardar algunas contraseñas.

Referencias:

http://www.linuxsysadmin.tk/2016/09/lanzando-playbooks-de-ansible-desde-jenkins.html 
http://docs.ansible.com/ansible/intro_windows.html

h1. Estructura para uso de VAULT_FILE

Utilizaremos archivos llamados SECRETS_XX, ej:

```
.
├── ansible.cfg
├── group_vars
│   ├── all
│   │   ├── credentials_sql
│   │   ├── SECRETS_SQL
```

Los archivos @SECRETS_ALGO@ tienen las variables con las claves.

h2. Variables definidas dentro de archivo @SECRETS_XX@

Las variables tendrán la nomenclatura:

    VAULT_NOMBRE_VAR

De esta forma podemos utilizar la variable dentro de nuestras definiciones, en archivos no cifrados con vault para más facil acceso.

Ejemplo, el archivo credentials_sql contiene:

```yaml
---
#---ommited-lines---
# Default user and pass:
ansible_sql_user: "usuario_sql"
ansible_sql_pass: "{{ VAULT_SQL_PASS }}"  # VAULT_SQL_PASS está dentro de archivo cifrado SECRETS_SQL
#---ommited-lines---
```

Donde se puede notar claramente que el "{{ VAULT_SQL_PASS }}" es una variable definida dentro de uno de los archivos @SECRETS_XX@.

h2. Creando el vault-passfile

Este archivo tiene la contraseña del vault y se usa automáticamente (configurado en @ansible.cfg@), ejemplo:

    echo "somepass" > /home/v744989/.vault-passfile

También para los servidores que ejecutan ansible, ej jenkins:

    echo "somepass" > /var/lib/jenkins_home/.vault-passfile

Antes de ejecutarlo conviene cambiar a usuario jenkins, usando ej: @sudo su jenkins@
Donde jenkins_home es el usuario, ejemplo jenkins

h2. Cifrando archivos

    ansible-vault encrypt group_vars/all/SECRETS_SQL
Encryption successful

Si ya tenemos el @vault-passfile@ creado no nos preguntará este.

h2. Editar cifrado:

    ansible-vault edit group_vars/all/SECRETS_SQL

Si ya tenemos el @vault-passfile@ creado no nos preguntará este.
