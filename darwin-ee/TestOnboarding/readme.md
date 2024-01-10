# 1. Install Docker
Mac Docker app

# 2. Install image
```sh
git clone https://github.com/darwin-eu-dev/execution-engine-compose
cd execution-engine-compose
docker login -u anonymous-pull -p <password> executionengine.azurecr.io 
docker compose up -d
```
Full install documentation at: https://github.com/darwin-eu-dev/DARWIN-EU-infra-cc/tree/execution_engine/scripts/execution-engine

# 3. Make image for onboarding
Configuration in `Dockerfile`. Image is based on executionengine.azurecr.io/darwin-runtime:latest [/Dockerfile]()
```sh
docker build -t darwin-onboarding-2 .
```

# 4. Create study configuration
Short readme on creating study configuration: [docs/README.md]()

Other example: [/tests/TestDatabaseConnector/execution-config.yml]()

```sh
zip -r onboarding onboarding
```