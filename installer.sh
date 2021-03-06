#!/usr/bin/env bash
# TODO:
#  - Java install
#  - Gradle is handled by wrapper
#  - SDK Installer manual download
#  - Possibly install build tools, Gradle only warns about it
#  - Support for Ubuntu (duh) and Fedora (because me)
#  - OSX and Windows... I don't even know... Not in this file at least
#
# Format:
#  - Guided install - stretch goal
#  - Start with options and install all

# 0 on success
# 1 on no java
# 2 on bad java version
# 3 on no javac
# 4 on bad javac version
function checkJava() {
  # Check command not found
  java -version &> /dev/null
  if [[ ${?} == 127 ]]; then
    return 1
  fi

  # Java must be 1.8
  local JAVA_VERSION=$(java -version 2>&1)
  if [[ $JAVA_VERSION != *"1.8."* ]]; then
    return 2
  fi

  javac -version &> /dev/null
  if [[ ${?} == 127 ]]; then
    return 3
  fi

  local JAVAC_VERSION=$(javac -version 2>&1)
  if [[ $JAVAC_VERSION != *"1.8."* ]]; then
    return 4
  fi

  return 0
}

function installJavaFedora() {
  sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel
}

function installJavaUbuntu() {
  sudo apt-get install openjdk-8-jre openjdk-8-jdk
}

function installJava() {
  local HOST_INFO=$(hostnamectl 2>&1)
  if [[ $HOST_INFO == *"Ubuntu"* ]]; then
    installJavaUbuntu
  elif [[ $HOST_INFO == *"Fedora"* ]]; then
    installJavaFedora
  fi
}

SDK_HOME=${HOME}/Android

# 1: binary not found in the .android folder
function checkAndroidSDK() {
  $(${SDK_HOME}/tools/bin/sdkmanager --version &> /dev/null)
  if [[ ${?} == 127 ]]; then
    return 1
  fi

  return 0
}

function downloadAndroidSDK() {
  local SDK_ZIP="sdk-tools-linux-4333796.zip"
  # Download the zip file
  wget "https://dl.google.com/android/repository/"${SDK_ZIP}

  # Check for ~/.android
  ls ${SDK_HOME} &> /dev/null
  if [[ ${?} -gt 0 ]]; then
    mkdir ${SDK_HOME}
  fi

  unzip ${SDK_ZIP} -d ${SDK_HOME}
  
  # Check for repositories.cfg
  ls ${SDK_HOME}/repositories.cfg &> /dev/null
  if [[ ${?} -ne 0 ]]; then
    touch ${SDK_HOME}/repositories.cfg
  fi
}

function downloadAndroidPackages() {
  local SDK_MANAGER=${SDK_HOME}/tools/bin/sdkmanager
  local PACKAGE_LIST="platform-tools platforms;android-28 build-tools;28.0.3 sources;android-28"

  ${SDK_MANAGER} ${PACKAGE_LIST}
}

function setLocalProperties() {
  ls local.properties &> /dev/null
  if [[ ${?} -ne 0 ]]; then
    touch local.properties
  else
    return 0
  fi

  echo "sdk.dir=${SDK_HOME}" >> local.properties
}

if [[ ${EUID} == 0 ]]; then
  echo "WARNING: Installer is not designed to run as root, continue at your own risk, ctrl-C to exit (recommended)"
  read
fi

echo "Checking Java version..."
checkJava
if [[ ${?} -ne 0 ]]; then
  echo "JDK 1.8 not installed, proceeding with OpenJDK installation"
  installJava
else
  echo "Java installed"
fi

echo "Checking for the Android SDK in the ~/.android folder..."
checkAndroidSDK
if [[ ${?} -ne 0 ]]; then
  echo "Downloading the Android SDK and placing it in ${SDK_HOME}"
  echo "Note: By continuing you agree to the Google terms and conditions (Enter - continue, ctrl-C - cancel)"
  read
  downloadAndroidSDK
else
  echo "Android SDK found"
fi

echo "Now checking/downloading necessary Android packages for ftc_app..."
downloadAndroidPackages

echo "Setting up local.properties..."
setLocalProperties
