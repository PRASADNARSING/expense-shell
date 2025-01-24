#!/bin/bash

#cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
# Script to set up Nginx server and deploy the Expense frontend

USERID=$(id -u)
R="\e[31m"  # Red for errors
G="\e[32m"  # Green for success
Y="\e[33m"  # Yellow for warnings
N="\e[0m"   # Reset color

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

# Create logs folder if it doesn't exist
if [ ! -d "$LOGS_FOLDER" ]; then
    mkdir -p "$LOGS_FOLDER"
    echo "Directory $LOGS_FOLDER created."
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

# Check if the script is being run as root
CHECK_ROOT

# Install and enable Nginx
dnf install nginx -y  &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nginx Server"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nginx server"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting Nginx Server"

# Remove existing files from the default web directory
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing existing version of code"

# Download the latest frontend code
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Latest code"

# Navigate to the web directory
cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML directory"

# Unzip the frontend code
unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping the frontend code"

# Copy the Nginx configuration file
cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

# Restart Nginx to apply the changes
systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"

echo "Script execution completed at: $TIMESTAMP" &>>$LOG_FILE_NAME