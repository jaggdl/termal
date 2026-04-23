# Termal

A self-hosted macronutrient tracker that uses LLM vision models to estimate the nutritional content of your meals from photos. No more manually logging every ingredient — just snap a picture and get approximate calorie, protein, carbohydrate, and fat estimates.

## Features

- **Photo-based meal logging** — Take a photo of your meal and let an LLM with vision capabilities analyze it
- **Approximate macronutrient tracking** — Get estimated calories, protein, carbs, and fat content
- **Smart meal search** — Vector-powered search with time-decay scoring to surface meals you're most likely to eat again
- **Self-hosted** — Your data stays on your own server
- **Push notifications** — Get reminders via web push
- **Personalized macro targets** — Calculates your daily calorie, protein, carb, and fat goals based on your profile (weight, height, age, sex, activity level, and fitness goals) using BMR and TDEE formulas
- **Multi-user support** — Invite others to use your instance

## Supported LLM Providers

Termal uses [ruby_llm](https://github.com/crmne/ruby_llm) to interact with vision-capable models. You can configure one or more of the following providers through the app's global settings:

- **OpenAI** — `o4-mini`
- **Google Gemini** — `gemini-2.5-pro`, `gemini-3.1-pro-preview`

## Tech Stack

- **Ruby on Rails 8** with Solid Cache, Solid Queue, and Solid Cable
- **SQLite** with [sqlite-vec](https://github.com/asg017/sqlite-vec) for vector search
- **Tailwind CSS** + Hotwire (Turbo & Stimulus)
- **Docker** for easy self-hosting

## Quick Start with Docker Compose

The easiest way to run Termal is with Docker Compose.

Create a `docker-compose.yml` file:

```yaml
services:
  termal:
    image: jaggdl/production-termal:latest
    restart: unless-stopped
    ports:
      - "8765:3000"
    environment:
      - SECRET_KEY_BASE=abcdefabcdef
      - BASE_URL=https://termal.example.com
    volumes:
      - termal:/rails/storage

volumes:
  termal:
```

Then run:

```bash
docker compose up -d
```

The app will be available on port `8765` (or whichever port you map).

### Required Environment Variables

| Variable | Description |
|----------|-------------|
| `SECRET_KEY_BASE` | A secret key for Rails sessions and encryption. Generate one with `openssl rand -hex 64` |
| `BASE_URL` | The public URL where your instance is hosted (used for links and push notifications) |

### Updating

```bash
docker compose pull
docker compose up -d
```

## First-Time Setup

1. Start the container and visit your `BASE_URL`
2. Create the first user account — the first registered user becomes the admin
3. Fill out your **User Profile** with your weight, height, age, sex, activity level, and fitness goals to get personalized daily macro targets
4. Go to **Global Settings** and add your LLM API key(s):
   - OpenAI API key (for `o4-mini`)
   - Google Gemini API key (for `gemini-2.5-pro` or `gemini-3.1-pro-preview`)
5. Select your preferred meal analysis model in the settings
6. Start logging meals!

## Development

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Run dev server
bin/dev
```

## License

[O'Saasy](LICENSE.md)
