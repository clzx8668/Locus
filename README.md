# 🌌 Locus - Personal Multimodal Local Hub

> *"Your data. Your rules. Your local intelligence."*

Locus is a multimodal personal assistant and lightweight digital gateway built on the **Local-First** philosophy. More than just a note-taking app, it is a purely private digital foundation featuring dual-modal interaction (streaming input + RAG chat), end-to-end encryption, and a highly extensible plugin architecture.

---

## 🎯 Core Vision

In an era where cloud giants monopolize personal data, Locus aims to reclaim data sovereignty.

The system acts as the first touchpoint to capture your ideas, bills, meeting notes, and images. After local preprocessing and intent recognition, data is securely routed to a local encrypted sandbox or asynchronously synced to your private cloud server.

---

## ✨ Key Features

### 📱 Dual-Mode UI

- **Timeline (Flash Capture)** : Millisecond-level, frictionless text and multimedia input — as effortless as sending a text message.
- **AI Chat** : Swipe right to instantly wake your personal AI, with deep conversations powered by your local memory bank.

### 🔒 Military-Grade Encryption

- Built on Drift + SQLCipher, the local database file is fully encrypted at rest with AES-256.
- Fully offline capable — no network required.

### 🔌 Plugin-Based Architecture

- Powered by Dependency Injection (DI), business modules (e.g., finance dashboard, Twenty CRM push) are fully decoupled.
- One-click enable or uninstall — keeping the core lean and lightweight.

### 🧠 Progressive AI Routing

- **Current** : Lightweight local regex intent capture + remote LLM APIs (DeepSeek / Claude).
- **Future** : Seamless swap to local C/C++ FFI (e.g., llama.cpp), running fine-tuned small models natively on mobile and low-spec PCs.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend Framework** | Flutter (pure Dart compilation, seamless cross-platform: Windows / Android / iOS / macOS) |
| **Local Storage** | Drift (strongly-typed reactive SQL) + sqlcipher_flutter_libs |
| **Dependency Injection** | GetIt (module decoupling & hot-swappable plugins) |
| **Cloud Sync** | PocketBase (open-source, single-file real-time backend, deployable on private NAS / VPS) |

---

## 🗺️ Roadmap

### Phase 1: Core Foundation

- [ ] Initialize plugin-based directory structure and GetIt DI engine
- [ ] Deploy Drift encrypted database, define the `HubPayloads` core payload table

### Phase 2: Streaming Input & Local Gateway

- [ ] Develop a minimal floating input bar with lightweight image / audio compression
- [ ] Build a local rule dispatcher for silent auto-tagging and instant ingestion
- [ ] Establish PocketBase bidirectional real-time sync (WebSocket)

### Phase 3: Dual AI Engine & Intelligent Dispatch

- [ ] Build Chat UI and Markdown rendering components
- [ ] Implement basic API calls and local intent routing

### Phase 4: Memory Awakening (Local RAG)

- [ ] Implement a pure Dart local cosine similarity function
- [ ] Timeline text chunking, vectorized storage, and contextual recall

### Phase 5: Enterprise-Grade Gateway Extensions

- [ ] Develop a finance ledger aggregation plugin
- [ ] Develop a Twenty CRM async push plugin

---

## 🚀 Getting Started

> Relevant `flutter run` commands and dependency requirements will be added once the development environment is fully configured.
