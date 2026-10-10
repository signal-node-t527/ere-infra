# Project Documentation: ERE

## Overview

 Explicit Resolution Engine is a comprehensive system designed to model and resolve complex real-life problems represented as graph data structures. It employs a dialectic approach, utilizing **Thesis** and **Antithesis** nodes to represent structures and processes, respectively.

The project consists of two main components:
1.  **Resolution Engine**: A .NET-based backend API for managing the graph data and persistence.
2.  **Shiny Computing Machine (SCM)**: An Angular-based frontend GUI for visualizing, editing, and exploring the resolution graphs.

---

## Architecture

The system follows a classic client-server architecture:

-   **Frontend**: Angular application providing a rich, interactive window-based UI.
-   **Backend**: ASP.NET Core Web API managing data logic and database interactions.
-   **Database**: Microsoft SQL Server for persistent storage of nodes, edges, and metadata.

---

## Backend: Resolution Engine

### Technologies
-   **Framework**: .NET 9.0 / ASP.NET Core
-   **ORM**: Entity Framework Core (SQL Server provider)
-   **Database**: SQL Server
-   **Serialization**: System.Text.Json — node content is stored as **untyped JSON** (no custom
    polymorphic converters). See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) §3.3.

### Core Models

#### HTN Nodes (`HtnNodeModel`)
Nodes are the primary entities in the system. They belong to a specific graph (`"thesis"` or
`"counterthesis"`) and contain **untyped JSON content** (stored in a `ContentJson` string column;
`"antithesis"` is kept as an API-level compatibility alias for `"counterthesis"`).
-   **Thesis Nodes**: Represent structures, regularities, or static elements.
-   **Counterthesis Nodes**: Represent processes, conditions, data flows, or dynamic elements.

#### Node Content
-   **Common Fields**: `label`, `logicalConnector` (AND/OR), `triggers`, `effects`, `refId`, `referencers`.
-   **Thesis-Specific**: `flow` (priority-based), `countertheses` (cross-references), `type`.
-   **Counterthesis-Specific**: `flow` (priority, completed status), `theses` (cross-references), `state` (W/B/A/S), `executionOrder` (unit/set), `type`.

#### HTN Edges (`HtnEdgeModel`)
Define the relationships between nodes within a specific graph.

### API Endpoints

-   `GET /api/htn/thesis-nodes`: Retrieve all nodes in the "thesis" graph.
-   `GET /api/htn/counterthesis-nodes`: Retrieve all nodes in the "counterthesis" graph (also matches legacy `"antithesis"` rows).
-   `GET /api/htn/edges?graph={name}`: Retrieve all edges for a specific graph.
-   `GET /api/htn/nodes/{id}?graph={name}`: Retrieve a specific node.
-   `POST /api/htn/nodes`: Create a new node.
-   `POST /api/htn/nodes/{id}/content`: Update the JSON content of a node.
-   `DELETE /api/htn/nodes/{id}?graph={name}`: Delete a node (cascades to edges).
-   `POST /api/htn/nodes/batch-delete?graph={name}`: Delete several nodes (cascades to edges).
-   `POST /api/htn/edges`: Create a new edge.
-   `DELETE /api/htn/edges?from={id}&to={id}&graph={name}`: Remove an edge.
-   `GET /api/htn-categories`: Retrieve the single category document (`Id == "main"`).
-   `POST /api/htn-categories`: Upsert the category document.

The endpoints are unauthenticated. The full, authoritative surface (including `ping`,
`debug-connection`, and `migrate-graph`) is tabulated in
[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) §3.2.

---

## Frontend: Shiny Computing Machine (SCM)

### Technologies
-   **Framework**: Angular 20 (package name `purgatory-ui`)
-   **Styling**: SCSS / Vanilla CSS
-   **State Management**: RxJS / Angular Signals
-   **Visuals**: Custom graph rendering logic (`@swimlane/ngx-graph`).

### Key Features

#### 1. Window System
A custom implementation of a desktop-like windowing environment within the browser, allowing multiple tools (Editor, Explorer, Console) to be open simultaneously.

#### 2. HTN Explorer
A hierarchical tree view for navigating the graph structure. It allows users to drill down into triggers and effects, providing a clear visualization of dependencies.

#### 3. HTN Editor
A sophisticated form-based editor for modifying node properties, content, and dialectic relationships. Supports polymorphic fields based on the node type.

#### 4. Console
An integrated command-line interface for executing system commands, searching nodes, and performing batch operations.

#### 5. Graph Logic
This logic is implemented **in the frontend** (`src/app/core/domain/graph.utils.ts`), not on the
server — the backend only stores nodes/edges and a persisted `layer` value.
-   **Topological Analysis**: Calculates layers (longest/shortest path) over the graph.
-   **Bidirectional Cross-References**: Automatically populates references between Thesis and
    Counterthesis nodes based on their content.

---

## Setup and Development

### Prerequisites
-   Docker and Docker Compose
-   .NET 9.0 SDK (for local backend development)
-   Node.js & Angular CLI (for local frontend development)

### Running with Docker

The easiest way to start the entire stack:

```bash
# Start backend and database
docker-compose up -d db backend

# Start development frontend (with hot-reload)
docker-compose --profile dev up frontend-dev

# OR Start production frontend
docker-compose --profile prod up frontend-prod
```

### Local Development

1.  **Backend**:
    -   Navigate to `resolution-engine/`.
    -   Update `appsettings.json` with your SQL Server connection string.
    -   Run `dotnet run`.

2.  **Frontend**:
    -   Navigate to `shiny-computing-machine/`.
    -   Run `npm install`.
    -   Run `npm start` (or `ng serve`).
    -   Access via `http://localhost:4250`.

---

## Further Documentation

The authoritative, evidence-backed description of the system lives in
[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md). Project state, roadmap, decisions, and the
production checklist are under [docs/](./docs).

---

## Deployment

The project is containerized using Docker.
-   **Backend**: Runs on Alpine-based .NET runtime.
-   **Frontend**: Built with Angular and served via Nginx.
-   **Database**: Uses the official SQL Server 2022 container.

Nginx configuration (`nginx.conf`) handles routing and serves the Angular PWA.
