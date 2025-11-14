# 🧭 Guida Completa — Setup Flutter + Android Studio (Windows)

## 🪟 1️⃣ Preparazione dell’ambiente
### Requisiti
- Windows 10/11 con diritti amministrativi  
- Connessione internet stabile  
- Almeno 10 GB di spazio libero  
- WSL opzionale (ma lo sviluppo si fa su Windows)

---

## 🧰 2️⃣ Installazione Flutter SDK (Windows)
1. Scarica Flutter SDK:  
   👉 [https://flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
2. Estrai in:
   ```
   C:\src\flutter
   ```
3. Aggiungi al PATH:
   - Apri **Variabili d’ambiente → Path → Nuovo**
   - Aggiungi:
     ```
     C:\src\flutter\bin
     ```
4. Verifica:
   ```powershell
   flutter --version
   ```
   > Deve mostrare la versione di Flutter (es. `Flutter 3.35.7 • channel stable`).

---

## 🧱 3️⃣ Installazione Android Studio
1. Scarica Android Studio:  
   👉 [https://developer.android.com/studio](https://developer.android.com/studio)
2. Durante l’installazione, includi:
   - **Android SDK**
   - **SDK Platform Tools**
   - **Android Emulator**
3. Avvia Android Studio → **More Actions → SDK Manager**
   - Copia il percorso SDK (es. `C:\Users\<user>\AppData\Local\Android\Sdk`)
4. Scheda **SDK Tools → Show Package Details**
   - Spunta **Android SDK Command-line Tools (latest)**  
   - Clicca **Apply** e attendi l’installazione.

---

## 📱 4️⃣ Creazione Emulatore Android
1. In Android Studio → **Device Manager**
2. Clicca **Create Device**
3. Imposta:
   - Device: *Pixel 9* (o Pixel 5)
   - API Level ≥ 31 (es. Android 16, API 36)
   - Abilita *Use detected ADB location*
4. Avvia l’emulatore.

---

## ⚙️ 5️⃣ Configurazione Flutter con Android Studio
Verifica la toolchain:
```powershell
flutter doctor
```

Se segnala licenze mancanti:
```powershell
flutter doctor --android-licenses
```
Premi `y` a ogni richiesta.

Tutti i check “✓” devono risultare verdi (tranne Visual Studio, non necessario per Android).

---

## 🗂️ 6️⃣ Importare il progetto Flutter
1. Copia il progetto in Windows:
   ```
   C:\Progetti\<nome_progetto>
   ```
2. Aprilo in **VS Code** o **Android Studio**.
3. In PowerShell:
   ```powershell
   cd C:\Progetti\<nome_progetto>
   flutter pub get
   ```
4. Se ricevi l’errore:
   ```
   Building with plugins requires symlink support.
   ```
   → Abilita **Modalità sviluppatore** in  
   `Impostazioni → Privacy e sicurezza → Per sviluppatori → Modalità sviluppatore ON`.

---

## 🔑 7️⃣ Configurare Supabase (se usato)
1. Copia `.env.example` in `.env`:
   ```powershell
   copy .env.example .env
   ```
2. Apri `.env` e inserisci:
   ```
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   ```
3. In Supabase:
   - **Auth → Providers** → aggiungi redirect `io.placeflex.app://auth-callback`
   - **Storage → Buckets** → assicurati che `moments` sia pubblico.

---

## 🧪 8️⃣ Test e build dell’app
1. Esegui i test:
   ```powershell
   flutter test
   ```
   > Deve restituire `All tests passed!`
2. Lancia l’app:
   ```powershell
   flutter run -d emulator-5554
   ```
   (Sostituisci `emulator-5554` con il tuo ID da `flutter devices`).

---

## 🧭 9️⃣ Test funzionale (PlaceFlex)
1. Accedi (Magic Link o Google)
2. Vai alla tab **Scopri**
3. Tocca **FAB “Nuovo momento”**
4. Compila:
   - Titolo
   - Descrizione
   - Tag (facoltativo)
5. Scegli **Foto** o **Testo**
6. Premi **Usa posizione attuale** o inserisci manualmente lat/lon
7. Premi **Pubblica momento**
8. Verifica:
   - Snackbar *“Momento pubblicato!”*
   - Record e file su Supabase (Storage → `moments`)

---

## 🧩 10️⃣ Troubleshooting
| Problema | Soluzione |
|-----------|------------|
| `adb` non trovato | Aggiungi `platform-tools` di Android SDK al PATH |
| `Lost connection to device` | Rilancia con `flutter run` o `flutter run --release` |
| Permessi posizione/media negati | Concedili manualmente nelle impostazioni Android |
| Geolocator su Windows | Usa un emulatore o dispositivo Android reale |

---

## ✅ Checklist rapida per nuovi progetti
```
1️⃣ Installa Flutter in C:\src\flutter e aggiungi al PATH
2️⃣ Installa Android Studio + SDK + Command Line Tools
3️⃣ Crea emulatore (API ≥ 31)
4️⃣ flutter doctor  → accetta licenze
5️⃣ Copia progetto → flutter pub get
6️⃣ Abilita Developer Mode (symlink)
7️⃣ flutter test
8️⃣ flutter run -d emulator-5554
```

---

# 🤖 Prompt da dare all’AI Agent per proseguire lo sviluppo

```
Ambiente di sviluppo completato e testato con successo su Windows.
Flutter 3.35.7 installato in C:\src\flutter, Android Studio 2025.2.1 configurato con SDK 36 e emulatore Pixel 9 (API 36).
Il progetto PlaceFlex è stato eseguito correttamente tramite `flutter run -d emulator-5554`.

Prosegui con lo sviluppo secondo la roadmap:
- Verifica integrità della feature "creazione momenti" (foto, testo, geolocalizzazione)
- Prepara i test manuali e automatici per Supabase Storage e tabella public.moments
- Pianifica la successiva integrazione Mapbox per la priorità mappa
- Fornisci eventuali migrazioni o aggiornamenti schema SQL
```
