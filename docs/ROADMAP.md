# MealOps Roadmap

## Purpose

MealOps is a learning and portfolio project that will build a weekly meal-planning
application while developing practical skills in software development, AI, Azure,
infrastructure as code, GitOps, and observability.

This roadmap is a living document. Details may change as the requirements and
architecture become clearer, but each phase should produce a working and
demonstrable result.

## Guiding Principles

- Build the smallest useful product first.
- Introduce a technology only when it supports the current phase.
- Keep every phase usable, testable, and documented.
- Prefer automation and reproducibility over manual configuration.
- Record important decisions, trade-offs, failures, and lessons learned.
- Control cloud costs and remove resources that are no longer needed.

## Phase 1: Working Local Application

### Goal

Build the smallest end-to-end version of MealOps that runs locally.

### Planned Deliverables

- A user profile containing food restrictions and preferences
- Generation of a seven-day meal plan
- Validation of the generated plan against the user profile
- Generation of a consolidated shopping list
- Local data storage
- Automated tests for the main business rules
- Instructions for running the application locally

### Learning Focus

- Python application development
- API and data-model design
- AI model integration and structured output
- Input validation and error handling
- Automated testing
- Git and GitHub workflow

### Completion Criteria

- A user can provide a profile and request a weekly meal plan.
- The application returns a validated plan and shopping list.
- The main workflow runs locally from documented instructions.
- Core business rules have automated tests.
- Secrets are not committed to Git.

## Phase 2: Production-Quality Application

### Goal

Improve the local application so it is reliable, maintainable, secure, and ready
to deploy.

### Planned Deliverables

- Persistent database and database migrations
- Container image and local container-based environment
- Health and readiness endpoints
- Structured application logs
- Timeouts, retries, and clear failure handling
- Continuous integration for tests, linting, and image builds
- Dependency and container security scanning
- Initial operational documentation

### Learning Focus

- Docker and container image design
- Database operations and migrations
- CI pipelines
- Application security
- Configuration and secret management
- Reliability patterns

### Completion Criteria

- The application runs locally in containers.
- CI validates every proposed change.
- Configuration is separated from application code.
- Expected failures are handled and tested.
- The application has documented health checks and operating instructions.

## Phase 3: Azure Deployment with Terraform

### Goal

Deploy MealOps to Azure using repeatable infrastructure as code.

### Planned Deliverables

- Azure development environment
- Terraform modules or configurations for required resources
- Container registry and application hosting
- Managed database or an explicitly selected alternative
- Secure secret storage and managed identity where appropriate
- Automated deployment workflow
- Budget alerts and cost documentation
- Repeatable creation and removal of the environment

### Learning Focus

- Azure fundamentals
- Terraform workflow and state
- Identity and access management
- Cloud networking
- Cloud security
- Cost management

### Completion Criteria

- Terraform can create the documented development environment.
- MealOps is accessible in Azure and completes its main workflow.
- Secrets are stored outside source control and application images.
- The deployment can be reproduced from the repository.
- Cloud costs and cleanup steps are documented.

## Phase 4: Kubernetes and GitOps

### Goal

Run MealOps on Kubernetes and manage deployments through a GitOps workflow.

### Planned Deliverables

- Azure Kubernetes Service development cluster
- Kubernetes manifests or a Helm chart
- Resource requests and limits
- Liveness and readiness probes
- Argo CD installation and application configuration
- Git-based environment configuration
- Documented promotion and rollback process
- Basic Kubernetes security controls

### Learning Focus

- Azure Kubernetes Service
- Helm
- Argo CD
- GitOps practices
- Kubernetes security and operations
- Deployment and rollback strategies

### Completion Criteria

- Argo CD deploys MealOps from version-controlled configuration.
- Configuration drift is detected and corrected through the GitOps workflow.
- Application health is visible in Kubernetes and Argo CD.
- A deployment and rollback can be demonstrated.
- Cluster and workload costs are documented.

## Phase 5: Observability and Reliability

### Goal

Make the complete system observable and demonstrate how it behaves during
failures.

### Planned Deliverables

- Application metrics, logs, and distributed traces
- Grafana Alloy or an appropriate telemetry collector
- Loki for logs
- Grafana for dashboards and investigation
- Tempo for traces
- Mimir or Prometheus for metrics
- Service and AI-operation dashboards
- Actionable alerts
- Runbook and example incident review
- Reliability and recovery demonstration

### Learning Focus

- OpenTelemetry
- LGTM observability stack
- Service-level indicators and objectives
- Alert design
- Incident response
- Performance and reliability testing

### Completion Criteria

- A request can be followed through relevant logs, metrics, and traces.
- Dashboards show application health and important product behavior.
- Alerts detect selected failure conditions.
- A controlled failure is investigated using the observability stack.
- The investigation and corrective actions are documented.

## Phase Dependencies

1. Phase 1 establishes a useful product and its business rules.
2. Phase 2 makes that product safe and reliable enough to deploy.
3. Phase 3 introduces cloud infrastructure and reproducible provisioning.
4. Phase 4 moves deployment management to Kubernetes and GitOps.
5. Phase 5 builds on the deployed system to demonstrate observability and
   operational reliability.

Later phases may influence earlier designs, but work should not move to the next
phase until the current phase's completion criteria are satisfied or consciously
revised.

## Progress

| Phase | Status |
| --- | --- |
| 1. Working Local Application | Not started |
| 2. Production-Quality Application | Not started |
| 3. Azure Deployment with Terraform | Not started |
| 4. Kubernetes and GitOps | Not started |
| 5. Observability and Reliability | Not started |

## Review Points

Review this roadmap:

- after the product vision, requirements, and MVP are agreed;
- at the end of every phase;
- when a major architectural decision changes the planned sequence; and
- when cost, complexity, or learning value no longer justifies a planned tool.
