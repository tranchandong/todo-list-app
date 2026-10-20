# Todo App

A todo app built with React, Node.js, Express, and MongoDB.

## Run locally

Install Git and Docker. Make sure Docker is running.

```bash
git clone https://github.com/tranchandong/todo-list-app.git
cd todo-list-app
```

Create the environment file using PowerShell:

```powershell
Copy-Item backend/.env.example backend/.env
```

Open `backend/.env` and set your own `JWT_SECRET`. Leave the Gmail fields empty if you don't need password reset emails.

```bash
docker volume create todo-mongo-data
docker compose up -d --build
```

Open http://localhost:8080.

## Notes

- Nginx serves the frontend and forwards `/api` requests to the backend.
- MongoDB stores data in the `todo-mongo-data` volume.
- Do not commit `.env` to GitHub.

Check status and logs:

```bash
docker compose ps
docker compose logs --tail 50 todo-backend
```

Stop the app:

```bash
docker compose down
```
