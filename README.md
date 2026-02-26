# easyBacklog

easyBacklog is an intuitive time saving backlog management tool for Agile practitioners working in or with agencies. It is designed to be not just another all purpose project management, Agile or collaboration tool for teams. It was a free service available to practitioners at easybacklog.com.

## Home page for posterity

![easyBacklog.com home page as at Aug 2022](public/home-screenshot.png)
# End of life: Q3 2022

The free easyBacklog.com service shut down on 30 September 2022. When [Matthew O'Riordan](https://mattheworiordan.com) started easyBacklog, his goals were modest and straightforward, he wanted to give people an intuitive time saving backlog management tool for Agile practitioners working in or with agencies. Before it shut, nearly 400k backlogs were created by more than 55k people.

easyBacklog was shut down because the project was neglected for many years. [Matthew O'Riordan](https://mattheworiordan.com) is running [Ably](https://ably.com), a business of 150 people that he founded to provide [serverless websockets](https://ably.com/topic/websockets) and [realtime collaborative APIs](https://ably.com/features) to developers. Ably as of 2022 powers realtime experiences for more than 300 million people each month.

# License (now open source)

This project has now been open sourced under the [MIT license](./LICENSE). Anyone is free to use this software and modify it as they see fit.

## 🚀 Getting Started (Docker)

Want to run easyBacklog? The quickest way is with Docker:

```bash
mkdir easybacklog && cd easybacklog
curl -o docker-compose.yml https://raw.githubusercontent.com/mattanmr/easybacklog/main/docker-compose.example.yml
curl -o .env https://raw.githubusercontent.com/mattanmr/easybacklog/main/.env.example
docker-compose up
# → Open http://localhost:3000
```

**Full guide:** See [QUICKSTART.md](QUICKSTART.md) for detailed setup, configuration, troubleshooting, and more.

**For developers:** See [LOCAL_DEVELOPMENT_GUIDE.md](doc/LOCAL_DEVELOPMENT_GUIDE.md) to set up for local development without Docker, or [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) to build and publish your own image.

# Running this project

easyBacklog is built on [Ruby on Rails](https://rubyonrails.org/) and not been materially updated since 2015. As such, if you want to run this service it is strongly recommended you follow the upgrade path to a more modern verison of Rails.

Components:
* Ruby on Rails 3.2
* Postgres database
* JQuery and Backbone.js
* Devise for encryoption
* HAML and EJS for HAML/JST templates
* Sidekiq for background jobs
* [Ably for realtime collaboration](https://ably.com)