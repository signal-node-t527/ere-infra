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
-   **Framework**: .NET 8.0 / ASP.NET Core
-   **ORM**: Entity Framework Core
-   **Database**: SQL Server
-   **Serialization**: System.Text.Json (with custom polymorphic converters)

### Core Models

#### HTN Nodes (`HtnNodeModel`)
Nodes are the primary entities in the system. They belong to a specific graph (e.g., "thesis" or "antithesis") and contain polymorphic JSON content.
-   **Thesis Nodes**: Represent structures, regularities, or static elements.
-   **Antithesis Nodes**: Represent processes, conditions, data flows, or dynamic elements.

#### Node Content
-   **Common Fields**: `Label`, `LogicalConnector` (AND/OR), `Triggers`, `Effects`, `RefId`, `Referencers`.
-   **Thesis-Specific**: `Flow` (priority-based), `Antitheses` (cross-references), `Type` (root, structure, regularity, etc.).
-   **Antithesis-Specific**: `Flow` (completed status, priority, cycles), `Theses` (cross-references), `State` (W/B/A/S), `ExecutionOrder`, `Type` (initial, final, condition, process, etc.).

#### HTN Edges (`HtnEdgeModel`)
Define the relationships between nodes within a specific graph.

### API Endpoints

-   `GET /api/Htn/thesis-nodes`: Retrieve all nodes in the "thesis" graph.
-   `GET /api/Htn/antithesis-nodes`: Retrieve all nodes in the "antithesis" graph.
-   `GET /api/Htn/edges?graph={name}`: Retrieve all edges for a specific graph.
-   `GET /api/Htn/nodes/{id}?graph={name}`: Retrieve a specific node.
-   `POST /api/Htn/nodes`: Create a new node.
-   `POST /api/Htn/nodes/{id}/content`: Update the JSON content of a node.
-   `DELETE /api/Htn/nodes/{id}`: Delete a node (cascades to edges).
-   `POST /api/Htn/edges`: Create a new edge.
-   `DELETE /api/Htn/edges`: Remove an edge.

---

## Frontend: Shiny Computing Machine (SCM)

### Technologies
-   **Framework**: Angular 18+
-   **Styling**: SCSS / Vanilla CSS
-   **State Management**: RxJS / Angular Signals
-   **Visuals**: Custom graph rendering logic.

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
-   **Topological Analysis**: Automatically calculates layers (longest/shortest path) and detects cycles.
-   **Bidirectional Cross-References**: Automatically populates references between Thesis and Antithesis nodes based on their content.

---

## Setup and Development

### Prerequisites
-   Docker and Docker Compose
-   .NET 8.0 SDK (for local backend development)
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
    -   Run `ng serve`.
    -   Access via `http://localhost:4200`.

---

## Deployment

The project is containerized using Docker.
-   **Backend**: Runs on Alpine-based .NET runtime.
-   **Frontend**: Built with Angular and served via Nginx.
-   **Database**: Uses the official SQL Server 2022 container.

Nginx configuration (`nginx.conf`) handles routing and serves the Angular PWA.
