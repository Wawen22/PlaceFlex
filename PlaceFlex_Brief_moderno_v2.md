# PlaceFlex: Brief Operativo per Agente AI 🚀
## Visione: Trasformare i luoghi in ricordi condivisi.

## 🎯 Executive Summary
PlaceFlex è un social mobile basato su memorie geolocalizzate: gli utenti creano e scoprono contenuti (foto, video brevi, audio, testi) ancorati a coordinate reali. I contenuti sono visibili soprattutto a chi è nei dintorni, incentivando esplorazione fisica, creatività locale e relazioni di community. Obiettivo: lanciare un MVP che validi discovery locale, creazione momenti e moderazione automatica; poi iterare con gamification, AI avanzata e monetizzazione per creator/business.

---

## 🧭 Vision & Concept

### 🌟 Vision
Riportare le persone nel mondo reale trasformando i luoghi in “bacheche” di ricordi condivisi.

### 🧨 Problema
I social attuali favoriscono contenuti globali e engagement distante, allontanando dal contesto fisico e dalle comunità locali.

### 🧩 Soluzione
Una piattaforma che lega contenuti ai luoghi, visibili “quando sei lì”, con AI per suggerimenti e moderazione e meccaniche di gioco per la retention.

### 👥 Target
* Gen Z & Millennials (18–35) esploratori urbani e creator
* Community locali e turisti
* Attività locali (ristoranti, musei, eventi)

---

## 🗺️ MVP — Features principali (Scope dell'Agente)

### 🗺️ Mappa interattiva con momenti vicini all’utente
* **Descrizione:** Vista mappa centrata sulla posizione dell’utente con cluster/marker dei momenti.
* **Interazioni chiave:**
    * Pinch/zoom, tap su cluster per espandere, tap su marker per aprire il dettaglio momento.
    * Filtro per raggio (50–500 m) e per tipo contenuto (foto/video/audio/testo).
    * Indicatore di precisione GPS e stato permessi.
* **Edge case:**
    * Permessi negati: fallback su città/ultima posizione nota + prompt educativo.
    * Nessun contenuto: stato “vuoto” con CTA a creare un momento o allargare il raggio.
* **Metriche:**
    * Tap-through rate su marker, tempo medio su mappa, densità contenuti per area.
* **Acceptance (MVP):**
    * Marker accurati entro tolleranza GPS; clustering funziona ≥ zoom 12–18; filtri persistono nella sessione.

### 📸 Creazione momenti (foto, short video, audio, testo + metadata)
* **Descrizione:** Flusso rapido in 3 step: media → dettagli → pubblica.
* **Interazioni chiave:**
    * Acquisizione da camera o libreria; durata video ≤ 30s; audio ≤ 60s.
    * Metadata: titolo (obbl.), descrizione, tag, visibilità (pubblica/privata), posizione (auto o pin manuale).
    * Anteprima prima della pubblicazione; salvataggio bozza offline.
* **Edge case:**
    * Upload interrotto: retry con backoff; notifica al completamento.
    * Media pesanti: compressione client-side con soglia (es. video < 25MB).
* **Moderazione (base):**
    * Pre-pubblico: analisi AI sincrona rapida per contenuti espliciti; se “review”, pubblicazione ritardata.
* **Metriche:**
    * Tasso di completamento creazione, tempo medio da start a publish, % drop per step.
* **Acceptance (MVP):**
    * Upload + CDN entro 3s per immagini e 8s per video su rete 4G; bozza recuperabile dopo kill app.

### 📍 Feed locale (posizione + raggio)
* **Descrizione:** Lista scorrevole dei momenti ordinati per vicinanza/recency.
* **Interazioni chiave:**
    * Infinite scroll, pulsante “aggiorna” quando cambia la posizione > soglia (es. 80 m).
    * Filtri rapidi (tipo media, “solo nuovi”, “solo seguiti” — se presente following).
* **Edge case:**
    * Cambio cella rete/oscillazioni GPS: debounce degli update per evitare jank.
    * Aree dense: sampling by score (vicinanza x engagement) per non saturare.
* **Metriche:**
    * CTR per card, dwell time per sessione, % refresh da movimento.
* **Acceptance (MVP):**
    * Lista aggiorna entro 1s da nuovo raggio/posizione; fallback a cached feed se offline.

### 👤 Profilo con timeline e momenti creati/scoperti
* **Descrizione:** Profilo personale con bio corta, avatar, contatori (post, scoperte).
* **Interazioni chiave:**
    * Tab “Creati”, “Scoperti” (salvati/visitati), “Bozze”.
    * Edit profilo (avatar, nome, bio), privacy base (profilo pubblico/privato).
* **Edge case:**
    * Cambio username: verifica univocità e rate limit.
    * Profilo privato: mostra placeholder/CTA follow (se introdotto in seguito).
* **Metriche:**
    * Visite profilo, % click su “Creati” vs “Scoperti”, modifica bio/avatar.
* **Acceptance (MVP):**
    * Timeline carica ≤ 1s per i primi 10 elementi; cache avatar/bio persistente.

### 🛡️ Moderazione automatica (AI) + flagging
* **Descrizione:** Pipeline di moderazione per contenuti UGC.
* **Interazioni chiave:**
    * Auto-flag AI (nudità esplicita, violenza, hate) → stato: “approved”, “limited”, “review”.
    * Segnalazione utente: motivo + commento; invio asincrono.
* **Edge case:**
    * Falsi positivi: canale “contesta decisione” (post‑MVP) o log per admin.
* **Metriche:**
    * % contenuti flaggati, tempo medio di risoluzione, tasso contestazioni.
* **Acceptance (MVP):**
    * ≥ 95% richieste moderazione processate < 2s; segnalazioni utente registrate con ID.

### ☁️ Upload media + CDN
* **Descrizione:** Gestione robusta di upload, transcoding leggero e distribuzione via CDN.
* **Interazioni chiave:**
    * Barra progresso, retry automatico, cancellazione upload.
    * Varianti immagine (thumbnail, medium) e poster per video.
* **Edge case:**
    * Reti instabili: resume upload su chunk; timeouts gestiti.
* **Metriche:**
    * Success rate upload, latenza fetch prime 3 risorse.
* **Acceptance (MVP):**
    * Time-to-first-byte immagini < 300ms (CDN EU), video start < 1.2s.

### 🔐 Autenticazione (email + social OAuth)
* **Descrizione:** Onboarding rapido con email magic link e almeno un provider social.
* **Interazioni chiave:**
    * Recupero account, logout, consenso geolocalizzazione durante onboarding.
* **Edge case:**
    * Provider down: fallback email; gestione account duplicati per stesso email/ID.
* **Metriche:**
    * Conversione onboarding, drop al consenso geolocalizzazione.
* **Acceptance (MVP):**
    * Login ≤ 10s end‑to‑end; magic link valido e one‑time.

### 📶 Offline minimo: bozze + sync
* **Descrizione:** Creazione e salvataggio di bozze locali con sync successivo.
* **Interazioni chiave:**
    * Indicatore stato (bozza, in coda, pubblicato), retry manuale.
* **Edge case:**
    * Media cancellati dal dispositivo: prompt di recupero/fallire con messaggio chiaro.
* **Metriche:**
    * Tasso di successo sync, tempo medio da online a pubblicato.
* **Acceptance (MVP):**
    * Nessuna perdita di bozza su crash; sync automatico entro 30s dal ritorno online.

---

## ✨ Funzionalità avanzate (Post‑MVP)

### ⏳ Momenti temporanei (ephemerals)
* **Meccanica:** Scadenza per tempo (es. 24h) o massimo visualizzazioni (es. 100 view).
* **Controlli:** Timer visibile, badge “temporaneo”, prevenzione screenshot (best effort).
* **Metriche:** % view prima della scadenza, tasso condivisione.
* **Acceptance:** Scadenza server‑side affidabile; rimozione da feed e mappa immediata.

### 🧠 Itinerari e riassunti area generati da AI
* **Funzioni:** “Esplora qui” (riassunto temi area), itinerari a piedi 30/60/90 min con tappe.
* **Input:** Preferenze utente (tag, tempo), orario, densità contenuti.
* **Metriche:** Completion rate itinerari, rating riassunti.
* **Acceptance:** Generazione < 5s; ogni tappa ha descrizione breve e distanza.

### 🏆 Gamification: badge, livelli, classifiche, challenge
* **Meccaniche:** XP per creazione/scoperta; streak giornalieri; badge tematici; challenge locali.
* **Anti‑abuso:** Rate limit XP per area/tempo; verifica posizione (base).
* **Metriche:** Giorni consecutivi attivi, partecipazione challenge.
* **Acceptance:** Progressi persistenti, leaderboard aggiornata near‑real‑time.

### 📱 AR overlay (camera view)
* **Funzioni:** Sovrapposizione di momenti vicini come “bolle” con distanza/angolo; modalità “scan”.
* **Requisiti:** Calibrazione bussola/giroscopio, 30fps minimo.
* **Metriche:** Tempo in AR per sessione, tap su bolle.
* **Acceptance:** Accuratezza angolare entro ±15°, degradazione elegante a radar.

### 💼 Monetizzazione: creator & business tools
* **Creator:** Insights, suggerimenti AI (orario/location), propensione viralità.
* **Business:** Momenti “sponsorizzati”, targeting per raggio/orario, pagine location.
* **Metriche:** CTR sponsorizzati, ARPU.
* **Acceptance:** Flussi pagamento affidabili, labeling ADV obbligatorio.

### 🔔 Notifiche smart
* **Trigger:** Nuovi momenti in zona, challenge imminenti, streak a rischio, "amico ha postato vicino".
* **Intelligenza:** Quiet hours, batching, ML semplice per evitare spam.
* **Metriche:** Opt‑in rate, open rate, conversion.
* **Acceptance:** Rispetto preferenze notifica; < 2 notifiche/giorno di default.

---

## 🛠️ Stack Tecnologico e Preferenze (Direttive per l'Agente)
L'agente deve selezionare lo stack ottimale in base ai requisiti. Le seguenti sono linee guida e opzioni decisionali:

* 📱 **Frontend (Cross-platform):**
    * **Opzione A:** **Flutter**.
    * **Opzione B:** **Expo (React Native)**.
    * **Decisione:** L'agente deve valutare e motivare la scelta finale in base a performance, ecosistema di librerie (mappe, media), e velocità di sviluppo dell'MVP.

* 🗄️ **Backend/BaaS:** **Supabase** (Postgres, Storage, Realtime, Edge)
    * **Decisione:** *Vincolante.* L'architettura deve basarsi sui servizi Supabase.

* 📐 **Geospatial:** PostGIS (integrato in Supabase) / Servizi geolocali.

* 🗺️ **Map Provider:**
    * **Opzioni:** **Mapbox**, **Google Maps**, **MapTiler**, o altri (es. OpenStreetMap con layer custom).
    * **Decisione:** L'agente deve valutare e motivare la scelta in base a: 1) Costi di scaling, 2) Qualità SDK (per Flutter/Expo), 3) Flessibilità di personalizzazione (styling), 4) Performance su mobile.

* 🤖 **AI (Moderazione, Riassunti):** OpenAI, Google Gemini, Claude (o equivalenti via API).
* 🎞️ **Media & CDN:** Supabase Storage (con CDN) / Cloudflare.
* 📣 **Push Notifications:** OneSignal (o provider BaaS integrato, se sufficiente).
* 💳 **Pagamenti (Post-MVP):** Stripe + RevenueCat.
* 🧭 **Monitoring/Analytics:** Sentry + PostHog (o equivalenti).
* 🔑 **Auth:** **Supabase Auth** (Email + OAuth)
    * **Decisione:** *Vincolante.*

*Nota: Le scelte non marcate come "Vincolanti" possono essere modificate dall'agente, a condizione di fornire una giustificazione tecnica solida nel deliverable dell'architettura.*

---

## 🔒 Requisiti Non Funzionali (NFR)
* **Scalabilità:** Ottimizzato per query geolocalizzate e storage media.
* **Latenza:** Bassa latenza mappe/media; caching client + CDN.
* **Privacy:** Geolocalizzazione opt-in, data minimization (Privacy-first).
* **Sicurezza:** Protezione token; access control per contenuti privati.
* **Testabilità:** Moduli separati per unit/integration testing.

---

## ⚖️ Privacy & Compliance
* Geolocalizzazione opt-in con spiegazione chiara.
* Privacy Policy e ToS conformi al GDPR.
* Meccanismi di segnalazione/rimozione contenuti.
* Retention policy per media e dati personali.
* Trasparenza su uso AI e gestione trascrizioni.

---

## 💰 Monetizzazione (Linee guida Post-MVP)
* **Free:** Funzioni base e ads non invasive.
* **Premium:** Accesso globale, filtri AI, no-ads.
* **Pro & Business:** Promozione, analytics, monetizzazione.
* **Tips:** Micro-pagamenti per i creator.

---

## 📊 Success Metrics (KPI)
* DAU/MAU, retention 7/30 giorni
* Momenti creati per utente
* Engagement: like, commenti, challenge participation
* Conversione a premium
* Tempo medio alla scoperta di un momento in zona

---

## ✅ Acceptance Criteria (MVP)
* Login/registrazione (email + ≥1 OAuth) funzionante.
* Creazione momento con posizione + media, serviti via CDN.
* Momento visibile su mappa e feed locale entro raggio (50–500 m).
* Feed che si aggiorna al cambiare della posizione.
* Moderazione automatica + segnalazioni utente operative.
* Bozze offline e sync al ritorno online.
* Monitoring minimo (errori/uptime).

---

## 🛣️ Roadmap & Milestones (Stime)
* **Sprint 0 — Preparazione (2 settimane):** Requisiti finali, wireframe, accessi provider, ambiente dev.
* **MVP — Core (8–10 settimane):** Auth, creazione momenti, mappa + feed locale, upload media, moderazione base.
* **Phase 2 — Social & Gamification (6–8 settimane):** Badge, challenge, profili avanzati, notifiche.
* **Phase 3 — AI & Monetizzazione (6–8 settimane):** Itinerari/riassunti AI, creator tools, subscription flow.
* **Phase 4 — Polish & Launch (4 settimane):** QA, performance, store readiness, release.

*Totale stimato MVP: ~10–12 settimane.*

---

## 📦 Deliverables per Milestone
* Specifica funzionale aggiornata (user stories + acceptance criteria)
* Architettura high-level + mapping servizi esterni
* Backlog puntato (epics, milestones, tasks)
* Ambiente dev/staging + istruzioni deploy
* Build mobile installabile (APK Android / iOS TestFlight)
* Test plan + report (unit, integrazione, E2E)
* Documentazione minima (setup, run, env vars, accessi)
* Piano di rollout + release checklist

---

## 🧰 Asset & Accessi (Da fornire all'Agente)
* Credenziali dev (Supabase, Map provider, AI, OneSignal, ecc.) in ambiente sicuro
* Repository o hosting codice
* Design: Figma/mockup, palette, logo, font
* Dataset di test (immagini, audio brevi, testi)
* Policy privacy/retention/monetizzazione
* Priorità features e vincoli budget/time-to-market

---

## 🧭 Linee Guida Operative (per l'Agente)
* **Libertà:** Piena libertà su pattern/librerie, nel rispetto dei vincoli (es. Supabase) e delle opzioni (Flutter/Expo) indicate.
* **Priorità:** UX mobile e discovery locale; performance mappa/media critiche.
* **Cambi:** Cambi ai provider non vincolanti ammessi se motivati da costi/latency/privacy e documentati.

---

## 🧪 QA & Testing (Sintesi)
* **Coverage:** Unit > 80% per business logic; smoke test su flussi critici.
* **Manuale:** Testare login, creazione momento, discovery, moderazione, offline sync.
* **E2E:** Login → creazione → mappa → moderazione → notifica.

---

## 🚢 Release Checklist
* Test passati + build su device reali
* Privacy Policy e ToS pubblicati
* Asset store (screenshot, descrizioni) pronti
* Monitoring errori attivo (Sentry o equivalente)
* Piano di rollout graduale definito

---

## 📝 Appendix — Priorità Consigliate (Ordine Operativo MVP)
1.  🔐 Autenticazione & profili base
2.  ✍️ Creazione momenti (media + metadata) + CDN
3.  🗺️ Mappa interattiva + feed locale
4.  🛡️ Moderazione automatica + segnalazioni
5.  📴 Offline sync minimo
6.  🔔 Notifiche basiche
7.  🏆 Gamification & monetizzazione (Post-MVP)