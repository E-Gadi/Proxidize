# Kubernetes Microservices with Observability (Prometheus & Jaeger)

This project contains two FastAPI-based Python microservices deployed to Kubernetes, complete with observability support via **Prometheus** and **Jaeger**.  

## 🔧 Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- Bash shell environment

---

## ⚙️ Startup Order & Troubleshooting

To ensure proper integration with Prometheus and Jaeger, follow this startup order:
	1.	Start Prometheus and Jaeger first
	2.	Deploy the Hash and Length services

	Note: If the services do not appear in Jaeger or Prometheus after deployment, try redeploying them. This helps ensure that tracing and metrics endpoints are registered correctly.
  
---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone git@github.com:E-Gadi/Proxidize.git
cd Proxidize 
```

Make sure you are in the root of the cloned directory before proceeding.

---

## 🧩 Microservices Deployment

Each service comes with its own deployment script under `./microservices/<service-name>/_deploy.sh`.

---

### 🟦 Hash Service

#### Run the Deployment Script

```bash
./microservices/hash-service/_deploy.sh
```

From the interactive DevOps menu, select option `7) Run All Steps`.  
This performs image build, Minikube load, deployment apply, rollout wait, and port-forward.

If the service doesn't become available at `http://localhost:8080`, manually select option `6) Port-forward & Test /health`.

#### Verify Access

- OpenAPI Docs: [http://localhost:8080/docs](http://localhost:8080/docs)  
- Health Endpoint: `http://localhost:8080/health`
- Prometheus Metrics: [http://localhost:8080/metrics](http://localhost:8080/metrics)

---

### 🟩 Length Service

#### Run the Deployment Script

```bash
./microservices/length-service/_deploy.sh
```

Just like the hash service, select option `7) Run All Steps`.

If needed, select option `6) Port-forward & Test /health`.

#### Verify Access

- OpenAPI Docs: [http://localhost:8081/docs](http://localhost:8081/docs)  
- Health Endpoint: `http://localhost:8081/health`
- Prometheus Metrics: [http://localhost:8081/metrics](http://localhost:8081/metrics)

---

## 📈 Observability Setup

### 1. Install Jaeger

```bash
./scripts/install_jaeger.sh
```

Choose:

- `build` – to install and run Jaeger
- `clean` – to re-run

#### Access Jaeger UI

- [http://localhost:8088](http://localhost:8088)

---

### 2. Install Prometheus

```bash
./scripts/install_prometheus.sh
```

#### Access Prometheus UI

- [http://localhost:9090](http://localhost:9090)

---

## ✅ Summary of Endpoints

| Component        | URL                              |
|------------------|----------------------------------|
| Hash Service API | [http://localhost:8080/docs](http://localhost:8080/docs) |
| Length Service API | [http://localhost:8081/docs](http://localhost:8081/docs) |
| Hash Metrics     | [http://localhost:8080/metrics](http://localhost:8080/metrics) |
| Length Metrics   | [http://localhost:8081/metrics](http://localhost:8081/metrics) |
| Jaeger UI        | [http://localhost:8088](http://localhost:8088) |
| Prometheus UI    | [http://localhost:9090](http://localhost:9090) |

---

### 📊 Prometheus Metrics to Monitor

Once services are up and Prometheus is running, you can query the following metrics via [http://localhost:9090](http://localhost:9090):

- `http_requests_total` – Total number of incoming HTTP requests
- `http_request_duration_seconds` – Histogram of request durations
- `http_errors_total` – Count of failed (error) requests

These metrics are exposed by both microservices at:

- [http://localhost:8080/metrics](http://localhost:8080/metrics)
- [http://localhost:8081/metrics](http://localhost:8081/metrics)

---

## 🖼️ Screenshots

You can find supporting screenshots in the `./screenshots` directory.

---

## 🧹 Cleanup

Use the interactive script options to delete resources:

- Hash Service: `Option 8` in `_deploy.sh`
- Length Service: `Option 8` in `_deploy.sh`
- Jaeger: `./scripts/install_jaeger.sh` → `clean`
- Prometheus: Manually delete or reset your Helm chart deployment if used


---

### 🧪 Example cURL Requests

You can test the microservices manually with the following commands:

#### Hash Service

```bash
curl -X POST http://localhost:8080/hash/ \
  -H "Content-Type: application/json" \
  -d '{"input_string": "Apple"}'
```

#### Length Service

```bash
curl -X POST http://localhost:8081/length/ \
  -H "Content-Type: application/json" \
  -d '{"input_string": "Apple"}'
```

---