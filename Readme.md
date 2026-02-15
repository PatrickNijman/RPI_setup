## RPI Setup Installer – Technical Description

### Overview

RPI Setup is a modular, phase-driven provisioning framework for Raspberry Pi systems. It automates the installation, configuration, and lifecycle management of a self-hosted infrastructure stack using Docker-based services and reproducible system configuration.

The project is designed for deterministic deployments, safe re-execution, and long-term maintainability.

---

### Architecture

The installer follows a **sequential phase model**, where each phase encapsulates a specific responsibility:

* **Base system initialization**

  * System updates
  * Package installation
  * System configuration hardening

* **Backup configuration**

  * Structured directory layout
  * Incremental backup strategy (e.g., rsync-based)
  * Separation of system data and service volumes

* **Docker runtime setup**

  * Docker Engine installation
  * Docker Compose support
  * Service network configuration

* **Service provisioning**

  * Pi-hole (DNS sinkhole)
  * Immich (self-hosted media platform)
  * Samba (network file sharing)

Each phase is independently executable, enabling partial deployments and targeted repairs.

---

### Design Principles

**Idempotency**

* Re-running phases does not overwrite existing state.
* Services and volumes are only created if absent.
* Configuration is validated before modification.

**State Separation**

* Persistent data is stored in Docker volumes or structured host directories.
* Application configuration is externalized (e.g., env files).

**Isolation**

* Services are containerized.
* Network and filesystem boundaries are clearly defined.

**Recoverability**

* Backup phase ensures restorable data state.
* Phase-based execution allows deterministic rebuilds.

**Observability**

* Clear console logging per phase.
* Explicit error handling and exit conditions.

---

### Execution Model

The installer can be executed:

* Per phase (`./install.sh pihole`)
* Sequentially (`./install.sh all`)

Phases are structured as shell modules with controlled side effects and predictable outputs.

---

### Intended Use Case

* Home lab infrastructure
* Reproducible Raspberry Pi server builds
* Self-hosted service stacks
* Infrastructure-as-code learning environment


