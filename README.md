# ERE - Explicit Resolution Engine

Explicit Resolution Engine (ERE) is a comprehensive system designed to model and resolve complex real-life problems represented as graph data structures. It employs a dialectic approach, utilizing **Thesis** and **Antithesis** nodes to represent structures and processes, respectively.

*The source code is intentionally private because it has not yet been audited for public release.*

## Project Structure

-   **[Resolution Engine](./resolution-engine)**: A **.NET 9** based backend API for managing graph data and persistence.
-   **[Shiny Computing Machine (SCM)](./shiny-computing-machine)**: An **Angular 20** based frontend GUI (package name `purgatory-ui`) for visualizing, editing, and exploring the resolution graphs.

## Core Concepts

ERE uses a Hierarchical Task Network (HTN) inspired model:

*   **Thesis Nodes**: Represent structures, regularities, or static elements.
*   **Antithesis Nodes**: Represent processes, conditions, data flows, or dynamic elements.
*   **Dialectic Approach**: Problems are resolved by analyzing the tension and relationships between Thesis and Antithesis nodes.

## Architecture

-   **Backend**: ASP.NET Core Web API with Entity Framework Core.
-   **Frontend**: Angular application with a custom windowing system and graph visualization.
-   **Database**: Microsoft SQL Server.
-   **Infrastructure**: Fully containerized using Docker.

## Getting Started

### Prerequisites

-   [Docker](https://www.docker.com/products/docker-desktop/) and Docker Compose.
-   .NET 9.0 SDK (optional, for local backend development).
-   Node.js & Angular CLI (optional, for local frontend development).

### Quick Start with Docker

The easiest way to start the entire stack is using Docker Compose:

```bash
# Start backend and database
docker-compose up -d db backend

# Start development frontend (with hot-reload)
docker-compose --profile dev up frontend-dev

# Access the application at http://localhost:4250
```

For production-like frontend (served via Nginx):
```bash
docker-compose --profile prod up frontend-prod
```

## Development

### Backend (Resolution Engine)
1. Navigate to `resolution-engine/`.
2. Update `appsettings.json` with your SQL Server connection string.
3. Run `dotnet run`.

### Frontend (Shiny Computing Machine)
1. Navigate to `shiny-computing-machine/`.
2. Run `npm install`.
3. Run `npm start` (or `ng serve`) for a dev server. The dev server listens on `http://localhost:4250`.
4. Access via `http://localhost:4250`.

## Documentation

-   **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)**: the authoritative description of the
    system as it exists today (repo layout, backend API + node-content schema, frontend
    architecture, containers, known limits).
-   **[docs/](./docs)**: project state, roadmap, decisions, and the production checklist.
