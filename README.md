# README

## Run in Ubuntu server

1. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

2. Check if Docker is installed

```bash
sudo docker --version
```

3. Generate secret key
```bash
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" > .env
```

4. Run the container using the .env file
```bash
sudo docker run -d -p 3000:3000 \
  --env-file .env \
  --name calories-counter jaggdl/calories-counter
```
