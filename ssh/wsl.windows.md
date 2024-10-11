- Install `openssh-server`

```shell
sudo apt install openssh-server -y
```

- Enable & Start `ssh` service

```shell
sudo systemctl start ssh
sudo systemctl enable ssh
```

- Port forward from Windows into WSL SSH server

```shell
netsh interface portproxy add v4tov4 listenport=50022 listenaddress=0.0.0.0 connectport=22 connectaddress=<WSL_IP>
```

- Allow Inbound Firewall Rule into port 50022 in Windows

```shell
netsh advfirewall firewall add rule name="WSL OpenSSH" dir=in action=allow localport=50022 protocol=TCP
```

- Connect

```shell
ssh user@window_host_ip -p 50022
ssh user@wsl_ip
```