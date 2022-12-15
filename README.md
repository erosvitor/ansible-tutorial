# About
This project is a tutorial about Ansible.

## Folder structure
```
/ansible-lab
  /app
    provision.sh
    Vagrantfile
  /control-node
    /playbooks
      /roles
      /templates
      /vars
      app.yml
      db.yml
    note.json
    provision.sh
    Vagrantfile  
  /db
    provision.sh
    Vagrantfile
```

## Worker folder
Create 'ansible-lab' folder in your preference folder.

## Control Node
- Create 'control-node' folder in the 'ansible-lab' folder

- Access 'control-node' folder

- Create initial Vagrantfile
```
$ vagrant init
```

- Edit 'Vagrantfile' file and change
```
the line 
  config.vm.box = "base"
  
to
  config.vm.box = "centos/7"
```

- Uncomment the line
```
# config.vm.network "private_network", ip: "192.168.33.10"
```

- Change it for
```  
config.vm.network "private_network", ip: "192.168.1.2"
```
- Uncomment the line
```  
# config.vm.synced_folder "../data", "/vagrant_data"
```

- Change it for
```  
config.vm.synced_folder ".", "/vagrant", type: "nfs"
```

- Add the commands below line '# SHELL'
```
config.vm.provision "shell", path: "provision.sh"
config.vm.hostname = "control-node"
```

- Save and close 'Vagrantfile' file

- Create 'provision.sh' file
```
#!/bin/sh

yum -y install epel-release
yum -y install ansible

cat <<EOT >> /etc/hosts
192.168.1.2 control-node
192.168.1.3 app
192.168.1.4 db
EOT

cat <<EOT >> /etc/ansible/hosts
app
db
EOT
```

- Create VM
```
$ ansible up
```  

## App
- Create 'app' folder in the 'ansible-lab' folder

- Create initial Vagrantfile
```
$ vagrant init
```

- Edit 'Vagrantfile' file

- Change...
```
the line 
  config.vm.box = "base"
  
to
  config.vm.box = "centos/7"
```

- Uncomment the line
```
# config.vm.network "forwarded_port", guest: 80, host: 8080
```

- Change it for
```
config.vm.network "forwarded_port", guest: 8080, host: 8080
```

- Uncomment the line
```
# config.vm.network "private_network", ip: "192.168.33.10"
```

- Change it for
```
config.vm.network "private_network", ip: "192.168.1.3"
```

- Add the command below line '# SHELL'
```
config.vm.hostname = "app"
```

- Save and close 'Vagrantfile' file

- Create VM
```
$ vagrant up
```

- Access VM
```
$ vagrant ssh
```

- Run the command ping to control-node VM
```
[vagrant@app ~]$ ping 192.168.56.2
```

- Exit from VM
```
[vagrant@app ~]$ exit
```

## DB
- Create 'db' folder in the 'ansible-lab' folder

- Create initial Vagrantfile
```
$ vagrant init
```

- Edit 'Vagrantfile' file

- Change...
```
  the line 
    config.vm.box = "base"
  
  to
    config.vm.box = "centos/7"
```

- Uncomment the line
```
# config.vm.network "forwarded_port", guest: 80, host: 8080
```

- Change it for
```
config.vm.network "forwarded_port", guest: 3306, host: 3306
```

- Uncomment the line
```
  # config.vm.network "private_network", ip: "192.168.33.10"
```

- Change it for
```  
config.vm.network "private_network", ip: "192.168.1.4"
```

- Add the command below line '# SHELL'
```
config.vm.hostname = "db"
```

- Save and close 'Vagrantfile' file

- Create VM
```
$ vagrant up
```

- Access VM
```
$ vagrant ssh
```

- Run the command ping to control-node VM
```
[vagrant@db ~]$ ping 192.168.56.2
```

- Exit from VM
```
[vagrant@db ~]$ exit
```

## SSH Key
- Access 'control-node' VM

- Create SSH key
```
$ ssh-keygen
  
Tip:
- Accept default local
- No need to set passphrase
```

- List and copy content of pub key
```
cat ~/.ssh/id_rsa.pub
```

## SSH Pub Key and APP
- Enter 'app' folder

- Create 'provision.sh' file
```
#!/bin/sh

cat << EOT >> /home/vagrant/.ssh/authorized_keys
<put-here-the-content-of-pub-key>
EOT
```

- Add following line in the 'Vagrantfile' file
```
config.vm.provision "shell", path: "provision.sh"
```

- Update 'app' VM
```
$ vagrant reload --provision 
```

- Enter 'control-node' folder

- Access 'control-node' VM and access 'app' VM running
```
$ ssh vagrant@app
```

## Playbooks
- Create following folders in 'control-node' folder
```
playbooks
  - roles
  - templates
  - vars
```

## DB Playbook 
- Create 'db.yml' file in 'playbooks' folder
```
- name: Database settings
  hosts: db
  user: vagrant
  become: yes
  vars_files:
    - vars/main.yml
  vars:
    - dbname: "notes"
    - dbusername: "root"
    - dbpassword: "root"
  tasks:
    - name: Hosts settings
      lineinfile:
        dest: /etc/hosts
        state: present
        line: "{{item}}"
      with_items:
        - 192.168.56.2 control-node
        - 192.168.56.3 app
        - 192.168.56.4 db  
  roles:
    - default-so-settings
    - role: geerlingguy.mysql
```

- Create 'default-so-settings' folder in 'roles' folder

- Create 'main.yml' file in 'default-so-settings' folder
```
- name: Operation system update
  yum:
    name: '*'
    state: latest
- name: Git client installation
  yum:
    name: git
    state: latest
```

- Create 'main.yml' in 'vars' folder
```
mysql_root_password: root
mysql_databases:
  - name: notes
    encoding: latin1
    collation: latin1_general_ci
mysql_users:
  - name: notesuser
    host: "%"
    password: notesuser
    priv: "notes.*:ALL"
```

- Checking playbook
```
$ ansible-playbook db.yml --check
```

- Applying playbook
```
$ ansible-playbook db.yml
```

## APP Playbook
- Create 'app.yml' file in 'playbooks' folder
```
- name: Application settings
  hosts: app
  user: vagrant
  become: yes
  vars:
    - dbhost: "db"
    - dbname: "notes"
    - dbusername: "notesuser"
    - dbpassword: "notesuser"
  tasks:
    - name: Hosts settings
      lineinfile:
        dest: /etc/hosts
        state: present
        line: "{{item}}"
      with_items:
        - 192.168.56.2 control-node
        - 192.168.56.3 app
        - 192.168.56.4 db  
    - name: Add application user
      user:
        name: app
        comment: Application user
        uid: 500
    - name: Java settings
      yum:
        name: java-1.8.0-openjdk-devel
        state: latest
    - name: Download Apache Maven
      get_url:
        url: https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.1.0/apache-maven-3.1.0-bin.tar.gz 
        dest: /opt/apache-maven-3.1.0-bin.tar.gz
    - name: Unzip Apache Maven
      ansible.builtin.unarchive:
        src: /opt/apache-maven-3.1.0-bin.tar.gz
        dest: /opt
        remote_src: yes
    - name: Folder application settings
      file:
        path: /opt/notes
        state: directory
        owner: app
        group: app
    - name: Git client settings
      yum:
        name: git
        state: latest
    - name: Clone of application repository
      git:
        repo: 'https://github.com/callicoder/spring-boot-mysql-rest-api-tutorial.git'
        dest: /opt/notes
        clone: yes
        force: yes
    - name: POM file settings
      template:
        src: pom.xml
        dest: /opt/notes/pom.xml
    - name: Database properties file settings
      template:
        src: application.properties
        dest: /opt/notes/src/main/resources/application.properties
    - name: Build application
      command: /opt/apache-maven-3.1.0/bin/mvn -f /opt/notes/pom.xml package
      become_user: app
    - name: Download Apache Maven dependencies
      shell:
        cmd: /opt/apache-maven-3.1.0/bin/mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '\['
    - name: Get package version
      shell:
        cmd: /opt/apache-maven-3.1.0/bin/mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '\['
        chdir: /opt/notes/
      register: app_version
    - name: Systemd service settings
      template:
        src: etc/systemd/system/notes.service
        dest: /etc/systemd/system/notes.service
      notify: reload daemon
    - name: Start systemd service
      service:
        name: notes
        state: restarted
  roles:
      - default-so-settings
  handlers:
    - name: reload app
      systemd:
        state: restarted
        daemon_reload: yes 
        name: 'notes'
    - name: reload daemon
      systemd:
        daemon_reexec: yes
```

- Create 'application.properties' in 'playbooks/templates'
```
spring.datasource.url = jdbc:mysql://{{dbhost}}:3306/{{dbname}}?useSSL=false&serverTimezone=UTC&useLegacyDatetimeCode=false
spring.datasource.username = {{dbusername}}
spring.datasource.password = {{dbpassword}}

# The SQL dialect makes Hibernate generate better SQL for the chosen database
spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.MySQL5InnoDBDialect

# Hibernate ddl auto (create, create-drop, validate, update)
spring.jpa.hibernate.ddl-auto = update
```

- Create 'etc/systemd/system' folder in 'templates' folder

- Create 'notes.service' file in 'etc/systemd/system' folder
```
[Unit]
Description=notes
After=network.target

[Service]
User=app
WorkingDirectory=/opt/notes
ExecStart=/usr/bin/java -jar -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom /opt/notes/target/easy-notes-{{app_version.stdout}}.jar
SyslogIdentifier=notes-%i

[Install]
WantedBy=multi-user.target
```

- Create 'pom.xml' in 'playbooks/templates'
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>easy-notes</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>easy-notes</name>
  <description>Rest API for a Simple Note Taking Application</description>
  
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.5.5</version>
    <relativePath/> <!-- lookup parent from repository -->
  </parent>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <java.version>8</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
      <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-devtools</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>mysql</groupId>
      <artifactId>mysql-connector-java</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
 
  <pluginRepositories>
    <pluginRepository>
      <id>central</id>
      <name>Central Repository</name>
      <url>https://repo.maven.apache.org/maven2</url>
      <layout>default</layout>
      <snapshots>
        <enabled>false</enabled>
      </snapshots>
      <releases>
        <updatePolicy>never</updatePolicy>
      </releases>
    </pluginRepository>
  </pluginRepositories>

  <repositories>
    <repository>
      <id>central</id>
      <name>Central Repository</name>
      <url>https://repo.maven.apache.org/maven2</url>
      <layout>default</layout>
      <snapshots>
        <enabled>false</enabled>
      </snapshots>
    </repository>
  </repositories>

</project>
```

- Applying playbook
```
$ ansible-playbook app.yml
```

## Test of application
- Create 'note.json' file in the 'control-node' folder
```
{
  "title": "Curso DevOps",
  "content": "Estudar Ansible"
}
```

- Insert a note
```
$ curl -H "Content-Type: application/json" --data @note.json http://app:8080/api/notes
```

- List notes
```
$ curl http://app:8080/api/notes
```

## License
This project is under license from MIT. For more details, see the LICENSE file.
