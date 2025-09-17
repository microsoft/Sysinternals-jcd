# Install jcd

## Mac
jcd is available on [Sysinternals Homebrew tap](https://github.com/microsoft/homebrew-sysinternalstap). 
```sh
# Add Sysinternals tap
brew tap microsoft/sysinternalstap

# Install jcd
brew install jcd
```
## Azure Linux 3
```sh
sudo dnf install jcd
```
## Ubuntu
#### 1. Register Microsoft key and feed
```sh
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
```

#### 2. Install jcd
```sh
sudo apt-get update
sudo apt-get install jcd
```

## Debian
#### 1. Register Microsoft key and feed
```sh
wget -q https://packages.microsoft.com/config/debian/$(. /etc/os-release && echo ${VERSION_ID%%.*})/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
```

#### 2. Install jcd
```sh
sudo apt-get update
sudo apt-get install jcd
```
## Fedora
#### 1. Register Microsoft key and feed
```sh
sudo rpm -Uvh https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/packages-microsoft-prod.rpm
```

#### 2. Install jcd
```sh
sudo apt-get update
sudo apt-get install jcd
```

## RHEL
#### 1. Register Microsoft key and feed
```sh
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/$(. /etc/os-release && echo ${VERSION_ID%%.*})/packages-microsoft-prod.rpm
```

#### 2. Install jcd
```sh
sudo yum install jcd
```

## openSUSE 15
#### 1. Register Microsoft key and feed
```sh
sudo zypper install libicu
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
wget -q https://packages.microsoft.com/config/opensuse/15/prod.repo
sudo mv prod.repo /etc/zypp/repos.d/microsoft-prod.repo
sudo chown root:root /etc/zypp/repos.d/microsoft-prod.repo
```

#### 2. Install jcd
```sh
sudo zypper install jcd
```

## SLES 12
#### 1. Register Microsoft key and feed
```sh
sudo rpm -Uvh https://packages.microsoft.com/config/sles/12/packages-microsoft-prod.rpm
```

#### 2. Install jcd
```sh
sudo zypper install jcd
```

## SLES 15
#### 1. Register Microsoft key and feed
```sh
sudo rpm -Uvh https://packages.microsoft.com/config/sles/15/packages-microsoft-prod.rpm
```

#### 2. Install jcd
```sh
sudo zypper install jcd
```
