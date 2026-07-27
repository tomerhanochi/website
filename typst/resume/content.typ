#import "style.typ": *

#show: resume.with(
  author: "Tomer Hanochi",
  email: "contact@tomerhanochi.com",
  github: "github.com/tomerhanochi",
  phone: "(+972) 54-549-4587",
  linkedin: "linkedin.com/in/tomer-hanochi",
  accent-color: "#26428b",
  font: "New Computer Modern",
  paper: "us-letter",
  author-position: center,
  personal-info-position: center,
)

== Profile
Software Engineer with 5+ years of experience developing scalable backend systems, cloud-native infrastructure, and high-performance AI/LLM applications.

== Work Experience
#work(
  title: "Backend Engineer",
  location: "Tel Aviv, Israel",
  company: "Visual Layer (Acquired by Camtek)",
  dates: dates-helper(start-date: "Dec 2025", end-date: "Present"),
)
- Partnered with the research team to extend the production retrieval system from single-vector to multi-vector search, enabling combined text-and-image queries with positive and negative exemplars.
- Designed and built an air-gapped agentic workflow system based on langgraph, with local models served via llama.cpp.

#work(
  title: "DevOps & Platform Engineer",
  location: "Rishon Lezion, Israel",
  company: "IDF - Matzov",
  dates: dates-helper(start-date: "Aug 2023", end-date: "Nov 2025"),
)
- Developed custom Python Ansible modules and plugins to enable fully end-to-end automated infrastructure provisioning.
- Deployed and maintained 20+ OpenShift & K8S clusters, using GitOps principles with ArgoCD.
- Architected Splunk-as-a-Service platform delivering isolated multi-site and highly available clusters to numerous external clients.

#work(
  title: "Junior Software Engineer",
  location: "Tel Aviv, Israel",
  company: "Seemplicity Security",
  dates: dates-helper(start-date: "Jun 2021", end-date: "Feb 2023"),
)
- Developed Python-based backend services and APIs on cloud platforms, implementing distributed system components for high-scale production environments.
- Created internal developer tooling enabling selective microservice execution for local debugging, later integrated into CI/CD pipeline for automated end to end tests.

== Achievements
#certificates(
  name: "Certificate of Excellence",
  issuer: "IDF - Matzov",
  date: "May 2025"
)
- Due to outstanding technical contributions and platform engineering achievements.

== Personal Projects
#project(
  name: "libsubid",
  url: "github.com/tomerhanochi/libsubid"
)

Built Rust-based dynamic library to automatically assign subuid/subgid ranges to non-root users, solving manual subuid/subgid assignment for rootless containerized environments.

== Skills
- Programming - Python, Go, Rust, Bash
- AI & LLMs - Large Language Models (LLMs), LangGraph, llama.cpp, Multi-Vector Search
- Backend - REST, gRPC, GraphQL, Microservices
- Infrastructure - AWS (EC2, EKS, Lambda), Docker, Kubernetes, Linux, Git, CI/CD
- Databases - PostgreSQL (pgvector), MySQL, Redis
- Observability - Prometheus, Grafana, OpenTelemetry, Elasticsearch
- Authn/Authz - OAuth 2.0, OIDC, Keycloak, OpenFGA
- Networking - TCP/UDP, HTTP/HTTPS, DNS
