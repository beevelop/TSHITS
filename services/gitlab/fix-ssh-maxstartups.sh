echo "Appending SSH MaxStartups and MaxSessions configs..."
docker exec -it -u root gitlab-server bash -c 'echo -e "MaxStartups 50:30:100\nMaxSessions 100" >> /etc/ssh/sshd_config'
echo "SSH config has been successfully written. Restarting container now..."
docker restart gitlab-server

echo "SSH fixed... Done!"
