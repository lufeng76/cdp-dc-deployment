echo "create user etl_user"
groupadd etl
useradd -g etl etl_user
echo BadPass#1 > passwd.txt
echo BadPass#1 >> passwd.txt
passwd etl_user < passwd.txt
rm -f passwd.txt