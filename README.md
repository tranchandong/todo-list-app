# Todo App

A todo app built with React, Node.js, Express, and MongoDB.

Live demo: https://todo.dongtran.dev

## Run locally

Install Git and Docker. Make sure Docker is running.

```bash
git clone https://github.com/tranchandong/todo-list-app.git
cd todo-list-app
```

Create the environment file in PowerShell:

```powershell
Copy-Item backend/.env.example backend/.env
```

Set your own `JWT_SECRET` in `backend/.env`.
Gmail settings are only needed for password reset emails.

```bash
docker volume create todo-mongo-data
docker compose up -d --build
```

Open http://localhost:8080.

## AWS setup

Terraform creates the EC2 instance and security group.
Ansible installs Docker, Nginx, Jenkins, and monitoring services.

Terraform files are in `terraform/create-ec2`.
The AWS CLI profile used by this project is `todo`.

Create `terraform.tfvars` in that directory:

```hcl
ssh_cidr = "YOUR_PUBLIC_IP/32"
```

```bash
cd terraform/create-ec2
terraform init
terraform plan
terraform apply
```

The AMI and instance settings are configured for Singapore.
Review them before creating a new server.

Update `ansible/inventory.ini` with your server IP and SSH key path.
Create `ansible/files/backend.env` with the backend environment settings.

Run Ansible from Linux or WSL, at the project root:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook-install-docker.yml
ansible-playbook -i ansible/inventory.ini ansible/playbook-deploy.yml
```

Point the domain's DNS record to the server before setting up HTTPS:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook-install-nginx.yml
```

The Nginx configuration uses `todo.dongtran.dev`.
Change the domain in the configuration files if using another domain.

## CI/CD

### GitHub Actions

Pushes to `main` build and push both Docker images, then deploy to EC2.

Required GitHub Actions secrets:

- `DOCKER_USER`
- `DOCKER_PASS`
- `SSH_PRIVATE_KEY`
- `SSH_KNOWN_HOSTS`

Required repository variable:

- `AWS_ROLE_ARN`

AWS OIDC is configured separately. The role allows the workflow to
temporarily add and remove its SSH rule in the app's security group.

Update the server IP and security group ID in the workflow when needed.

### Jenkins

Jenkins polls the `jenkins` branch every five minutes.
It builds, pushes, and deploys images when a new commit is detected.

Setup playbooks:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook-swap.yml
ansible-playbook -i ansible/inventory.ini ansible/playbook-install-jenkins.yml
ansible-playbook -i ansible/inventory.ini ansible/playbook-jenkins-agent.yml
```

Before running the agent playbook, create the `todo-agent` node in Jenkins:

- Label: `todo-docker`
- Executors: `1`
- Remote directory: `/home/jenkins-agent`
- Launch method: inbound agent with WebSocket

Save its secret in `ansible/files/jenkins-agent.secret`.
Set the built-in node's executors to `0`.

Required Jenkins credentials:

- `dockerhub-credentials`: Docker Hub username and access token
- `todo-server-ssh`: SSH private key for the `ubuntu` user

Create a Pipeline job using this repository, branch `*/jenkins`,
and script path `Jenkinsfile`. Enable Poll SCM with `H/5 * * * *`.

Both pipelines use `scripts/deploy.sh` and a shared deployment lock.
The last successful deployment determines the version running on the website.

The initial Ansible deployment builds images on EC2.
Later pipeline deployments use Docker Hub images and `docker-compose.prod.yml`.

## Monitoring

The monitoring stack includes:

- Prometheus: collects metrics every 30 seconds
- Grafana: displays dashboards
- Node Exporter: provides EC2 metrics
- MongoDB Exporter: provides database metrics

Deploy from Linux or WSL:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook-monitoring.yml
```

The app must already be running.
MongoDB Exporter connects through the `todo-app_default` Docker network.

The dashboard shows CPU, RAM, disk usage, MongoDB status,
connections, database size, and operations per second.

Prometheus retention is set to 7 days or a 1 GB size threshold,
whichever is reached first. Total disk usage can exceed that threshold
because of active data and the write-ahead log.

Dashboard JSON and provisioning files are stored in `monitoring/grafana`.
After editing a dashboard in Grafana, export the updated JSON back to the repo.

## Access Jenkins and Grafana

Both services listen on the server's localhost interface.

Run this in PowerShell, using your own SSH key path and server IP:

```powershell
ssh -i "C:\path\to\todo-devops.pem" -N -L 18081:127.0.0.1:8081 -L 13000:127.0.0.1:3000 ubuntu@YOUR_SERVER_IP
```

Keep the terminal open, then visit:

- Jenkins: http://localhost:18081
- Grafana: http://localhost:13000

## Notes

- Nginx serves the frontend and forwards `/api` requests to the backend.
- MongoDB data is stored in the `todo-mongo-data` volume.
- Production files are deployed to `/opt/todo-app`.
- Monitoring files are deployed to `/opt/todo-monitoring`.
- Do not commit environment files, private keys, agent secrets, or Terraform state.

Check the local app:

```bash
docker compose ps
docker compose logs --tail 50 todo-backend
```

Stop the local app:

```bash
docker compose down
```
