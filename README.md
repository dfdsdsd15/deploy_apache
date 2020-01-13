# My Test
```
Вместо предисловия  
данный плейбук написан по мотивам Ansible docs и Stackoverflow с обильным применением костыльных методов   
для получения необходимого результата по методу Маслова.  
идемпотентность не гарантируется
```
## Этот репо содержит тестовое задание с подробным пошаговым How To

**Данный playbook для Ansible 2.9.2+ выполняет:**
- Создание инстанса в AWS EC2.
- Установка последней версии Apache.
- Конфигурация Apache.
- Смена корневой директории для сайтов Apache.

### Используемый инструментарий:
```
ansible 2.9.2
  config file = /root/deploy_apache/ansible/ansible.cfg
  configured module search path = [u'/root/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/lib/python2.7/dist-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 2.7.16 (default, Oct 10 2019, 22:02:15) [GCC 8.3.0]
```

## Подготовка Ansible

### Clone Repo
```
git clone https://github.com/dfdsdsd15/deploy_apache.git
cd ./deploy_apache/ansible
```

### VPC
Необходимо выбрать подсеть в AWS

**_[AWS](https://aws.amazon.com/)->Networking & Content Delivery->VPC->Subnets_**

Выбрать желаемую подсеть или создать  
Применяем полученное имя в varaible playbook'а  
Заменить **<your_aws_vpc_subnet_id>** на выбранный subnet_ID полученный в AWS VPC Subnets выполнив команду:  
`sed -i 's/SUBNET_ID/_<your_aws_vpc_subnet_id>_/' ./roles/create_apache_instance_ec2/defaults/main.yml`

### IAM
Для того, чтобы выполнить запуск инстанса в AWS, необходимо создать пользователя в **AWS IAM**  
с `PolicyName AmazonEC2FullAccess` и получить ID виртуальной сети (VPC/subnet).

**_[AWS](https://aws.amazon.com/)->Security, Identity, & Compliance->IAM->Users->Add User_**
- Заполняем имя.  
- В Access type выбрать Programmatic access.  
- Выбрать Attach existing policies directly.  
- Add tags заполняем опционально.  

#### Запись полученных учётных данных в переменные playbook:
ключ и пароль можно не сохранять в открытом виде, а использовать **_ansible-vault_** ecrypt_string.

Заменить **<your_aws_access_key>** на ключ, полученный в AWS IAM.  
`sed -i 's/AWS_EC2_ACCESS_KEY/_<your_aws_access_key>_/' ./roles/create_apache_instance_ec2/defaults/main.yml`

Заменить **<your_aws_secret_key>** на пароль, полученный в AWS IAM.  
`sed -i 's/AWS_EC2_SECRET_KEY/_<your_aws_secret_key>_/' ./roles/create_apache_instance_ec2/defaults/main.yml`

___
### Ansible
На хосте с Ansible выполнить генерацию SSH-RSA ключей с помощью команды (можно использовать существующий ключ):
```
ssh-keygen
# ограничиваем права на файлы
chmod 0600 <имя_ключа>{,.pub}
```

Скопировать `public` ключ в **AWS Services->Network & Security->Key Pairs**
Выполнить _Import Key Pair_  
Загрузить ключ можно двумя способами:  
 - указать файл ключа  
 - вставить содержимое ключа  

Заменить **<your_aws_keypair_name>** на имя, указанное в Key Pairs  
`sed -i 's/KEYPAIR_NAME/_<your_aws_keypair_name>_/' ./roles/create_apache_instance_ec2/defaults/main.yml`
___
```
В **ansible.cfg** добавить праметры, если отсутсвуют:
[defaults]
host_key_checking= false
inventory= ./deploy_apache/ansible/hosts
```
___

## Подготовка Jenkins
### Используемый инструментарий:

```
Jenkins 2.204.1 с установленными плагинами:
  Git plugin 4.0.0
  GitHub plugin 0.2.6
  Publish Over SSH 1.20.1
  Credentials Plugin 2.3.0
```

### Создать и добавить ssh-rsa ключ Jenkins в GitHub
На хосте с **Jenkins** выполнить генерацию SSH-RSA также, как и для [Ansible](https://github.com/dfdsdsd15/deploy_apache/blob/master/README.md#ansible) с помощью команды  
(можно использовать существующий ключ):
```
ssh-keygen
# ограничиваем права на файлы
chmod 0600 <имя_ключа>{,.pub}
```
Зайти в [GitHub profile setting->SSH and GPG keys->New SSH key](https://github.com/settings/ssh/new)
Заполнить `Title`
В поле `Key` вписать содержимое `public` ключа

### Добавить данные для авторизации Jenkins в GitHub
**Jenkins->Credentials->System**
Выбрать домен и добавить данные:
- Kind: SSH Username with private key
- Scope: Global
- ID: Jenkins-GitHub-key
- Description: Jenkins-GitHub-key
- Username: _<указать LOGIN в GitHub>_
- Private Key: _<Поставить флаг и нажать **Add**, вписать `private` ключ>_
- Passphrase: _<Указать при наличии>_

**Jenkins->Manage Jenkins->Configure System**
Найти настройки плагина _Publish Over SSH_
- В раздел `key` вписать `private` ключ, добавленный в [AWS Key Pair](https://github.com/dfdsdsd15/deploy_apache/blob/master/README.md#ansible)
- SSH Servers добавить сервер:  
   Name: _<имя сервера, которое будет использоваться в Job'ах>_  
   Hostname: XXX.XXX.XXX.XXX  
   Username: ec2-user  
   Remote Directory: /home/ec2-user  

### Создание Job'а:

**Jenkins->New Item**
В поле Enter an item name вписать имя Job'а.  
Выбрать Freestyle Project.  

- Description: указываем произвольный  
- Discard old builds  
   Strategy: Log Ratation  
   Max # of builds to keep: 5  
- Source Code Management  
   Git  
     * Repository URL: `git@github.com:dfdsdsd15/MyWebSite.git`
	 * Credentials: Указываем имя ключа, созданного в [Credentials](https://github.com/dfdsdsd15/deploy_apache/blob/master/README.md#%D0%B4%D0%BE%D0%B1%D0%B0%D0%B2%D0%B8%D1%82%D1%8C-%D0%B4%D0%B0%D0%BD%D0%BD%D1%8B%D0%B5-%D0%B4%D0%BB%D1%8F-%D0%B0%D0%B2%D1%82%D0%BE%D1%80%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D0%B8-jenkins-%D0%B2-github)  
	 * Branch Specifier (blank for 'any'): `*/master`  
- Build Triggers: POLL SCM
   Schedule: `H/2 * * * *`
- Build
   Executing shell:
   ```
   echo "-----------------------Build Started------------------------"  
   pwd
   ls -la
   cat index.html
   echo "Build by Jenkins build# $BUILD_ID" >> index.html
   cat index.html
   echo "-----------------------Build Finished-----------------------"  
   ```  
   Executing shell:
   ```
   echo "-----------------------Test Started-------------------------"  

   result=`grep "ANSIBLE" index.html | wc -l`
   echo $result
   if [ "$result" = "1" ]
   then
     echo "Test Passed"
     exit 0
   else 
     echo "Test Failed"
     exit 1
   fi

   echo "-----------------------Test Finished-----------------------"  
   ```
- Post-build Actions  
   Send build artifacts over SSH  
     * SSH Server  
       Name: _<имя сервера, которое будет использоваться в Job'ах>_  
       Transfers  
         * Source files: `index.html`  
         * Exec command:
		    ```
			sudo chown root:root ~/index.html  
            sudo chmod 555 ~/index.html  
            sudo mv -u ~/index.html /web/html/index.html  
            sudo /usr/sbin/semanage fcontext -a -t httpd_sys_content_t "/web/html(/.*)?"  
            sudo /usr/sbin/restorecon -vR /web/html/*  
            sudo systemctl reload httpd.service  
			```

## Run playbok
```
cd ./deploy_apache/ansible  
# Создание инстанса  
ansible-playbook playbook_create_instace.yml  
```
Если использовать **_ansible-vailt_**, то запуск плейбука будет выглядеть так:  
`ansible-playbook playbook_create_instance.yml --ask-vault-pass`  
Далее, вводится пароль  

- В результате выполнения `playbook` будет выдано сообщение:

**"ec2.instances[0].public_ip": "_<ip адрес созданного инстанса>_"**

- Вставить полученный IP адрес в следующую команду:

`sed -i 's/XXX.XXX.XXX.XXX/_<ip адрес созданного инстанса>_/' ./hosts`

Запустить `ansible-playbook -l PROD playbook_apache.yml`
- Будет установлен Apache (httpd),  
- Изменён _(tcp)_ порт с 80-го на 81-й.  
- Изменена корневая директория Apache (httpd) на /web  

Результатом выполнения будет сгенерированная по шаблону Ansible веб страница по адресу **http://"_<ip адрес созданного инстанса>_":81**  

Чтобы выполнить Deploy веб страницы, необходимо внести в Jenkins адрес созданного инстанса  
~~sed -i 's/XXX.XXX.XXX.XXX/___ASSIGNED_PUBLIC_IP_ADDRESS___/' /var/lib/jenkins/jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml~~  

Открыть настройки Jenkins  
**Jenkins->Manage Jenkins->Configure System**  
Найти настройки плагина _Publish Over SSH_ и вписать **"_<ip адрес созданного инстанса>_"** вместо XXX.XXX.XXX.XXX  

Сделать коммит в репозитории [MyWebSite](https://github.com/dfdsdsd15/MyWebSite)  

Через 4 минуты обновить страницу **http://"_<ip адрес созданного инстанса>_":81**
Результатом выполненного Jenkins'ом Job'а будет добавленная последняя строка с номером билда `Jenkins Build# `  

### З.Ы.

Т.к. Jenkins находится на моей локальной машине (по причине [Recommended Hardware Requirements](https://jenkins.io/doc/book/installing/)  
мой аккаунт в AWS с Free Tier не укладывается), а проброс портов с использованием DynDNS является проблематичным  
(из-за использования имеющегося гипервизора на моём рабочей станции), то было принято решение не использовать webhook для Deploy по commit'у в GitHub,  
а проверять репозиторий каждые 2 минуты и при наличии commit'а в master branch, выполнять Job.

===
### З.Ы. З.Ы.

Для удобства использования скрипта настройки (playbook_apache.yml) можно использовать Dynamic Inventory.
Пример запуска:
Изменим invventory файл по-умолчанию:

```
cd ./deploy_apache/ansible
sed -i 's@./hosts@ec2.py@' ./hosts
```

Добавить в ENV ключ и пароль из [AWS IAM](https://github.com/dfdsdsd15/deploy_apache/blob/master/README.md#iam)  
`export AWS_ACCESS_KEY_ID=<your_aws_access_key>`  
`export AWS_SECRET_ACCESS_KEY=<your_aws_secret_access_key>`  

Запуск скрипта для получения tag_Name инстанса  
`chmod +x ec2.py && ./ec2.py`  

После кэширования всех инстансов, запуск плейбуков на нужном иснтансе выполняется так:  

`ansible-playbook -i ec2.py  playbook_create_instance.yml --tags tag_Type_Apache-EC2-for-DBI -u ec2-user`  

## Конец