# Pelican Panel Installer (Bash Script) 

A simple Bash script to install the **Pelican Panel** and **Wings**, with support for SSL via Certbot, MySQL integration, and automatic Apache configuration.

## 🛠️ Features

- 🔧 **Flexible Installation**  
  Choose to install the **Panel**, **Wings**, or **both** independently.

- 😎 **Simple Installation Guide**  
  This Bash Scirpt uses whiptail for a better userfriendly experience.
  

- 🔐 **SSL Support via Certbot**  
  Automatically obtain and configure HTTPS certificates using Let's Encrypt.

- 🗃️ **MySQL Support**  
  Automatically installs and configures MySQL for the Panel backend.

- 🌐 **Apache Auto Configuration**  
  Automatically creates a working Apache VirtualHost for your domain.

- 👏 **Panel and Wings Deletion and Update Script**  
  An external script that lets you delete or update your Wings and Panel
---
### ⭐ Version 3.0: 

- 👏 **Panel and Wings Deletion and Update Script**  
   This Script now Supports http that means you dont need a domain to install your panel. Just ste your IP as Node and you're ready to go.
---

## 📦 Requirements


| Distribution       | Recommended Version(s) | Support Status | Notes                            |
|--------------------|------------------------|----------------|----------------------------------|
| **Ubuntu**         | 24.04/24.10        | ✅ Supported    | Fully tested                     |
| **Debian**         | 11, 12                  | 🟡 limited support    | There could be an issue with PHP       |
|||||

Issue will be fixed soon!




## Other Requirements
### This script requires root/superuser access
- Git should be installed
   ```bash
    apt install git
   ```
## 🚀 Installation

1. Download the installer:
   ```bash
    git clone https://github.com/Kabel6499/pelican
   ```
2. Go to the directory of the installer and run:
    ```bash
     chmod 777 install.sh
     bash install.sh
     ```
---

# 🏁 After Wings Installation
### 1. Go to your Panel and open the Nodes Tab in Admin view
### 2. Create New Node and Enter your Node IP as Domain Name
### 3. Click Next and Click Create Node
### 4. Then Scroll down and Create your Allocations
### 5. Submit
### 6. Go to Configuration File Click on Autodebloy Command
### 7. Click on Standalone and Copy the Command
### 8. Paste it into your Terminal
### 9. Click enter and run:
```bash
sudo wings --debug
```
### 10. Wait 10 seconds and click ctrl+c on your keyboard
### 11. Then Check on your node page if your node is online
### 12. After this run these commands:
```bash
sudo systemctl enable --now wings
```
## 🔃 Update your Panel or Wings
  Simply run these commands in the Direcory of this Repository to update your Panel or Wings:

  ```bash
     chmod 777 update.sh
     bash update.sh
```

## 🗑️ Update your Panel or Wings
  Simply run these commands in the Direcory of this Repository to remove your Panel or Wings:

  ```bash
     chmod 777 delete.sh
     bash delete.sh
```
## ❓Questions
### If you have any further questions create an Issue on this Repository!

# ❗Disclaimer:
## This script is an unofficial community project and is not affiliated with the Pelican team.
