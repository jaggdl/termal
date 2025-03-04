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

3. Generate secret key and VAPID keys for push notifications
```bash
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" > .env

# Generate VAPID keys (if you're running locally)
bundle exec rails web_push:generate_vapid_keys

# Add the VAPID keys to your .env file
echo "VAPID_PUBLIC_KEY=your_public_key_here" >> .env
echo "VAPID_PRIVATE_KEY=your_private_key_here" >> .env
echo "VAPID_CONTACT_EMAIL=your_email@example.com" >> .env
```

4. Run the container using the .env file
```bash
sudo docker run -d -p 3000:3000 \
  --env-file .env \
  --name calories-counter jaggdl/calories-counter
```

## Push Notifications

This application supports Web Push notifications. To enable them:

1. Generate VAPID keys using the rake task:
   ```bash
   bundle exec rails web_push:generate_vapid_keys
   ```

2. Store the keys in Rails credentials or as environment variables:
   ```bash
   # Using credentials
   rails credentials:edit
   
   # Add to the file:
   vapid:
     public_key: your_public_key
     private_key: your_private_key
     contact_email: your_email@example.com
     
   # OR using environment variables:
   export VAPID_PUBLIC_KEY=your_public_key
   export VAPID_PRIVATE_KEY=your_private_key
   export VAPID_CONTACT_EMAIL=your_email@example.com
   ```

3. Users can subscribe to push notifications from their profile page.

4. To send a notification to a user:
   ```ruby
   user.send_push_notification(
     title: "New meal reminder",
     message: "Don't forget to log your lunch!",
     path: "/user_meals/new"
   )
   ```
