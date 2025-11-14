# Fix Storage RLS Error 403

## Problema
Errore 403 "new row violates row-level security policy" durante la creazione di momenti.

## Soluzione
Le policy Storage devono essere configurate tramite l'interfaccia web di Supabase.

### Passo 1: Vai alla sezione Storage
1. Apri: https://supabase.com/dashboard/project/gbttlyrczgabuzggctzy/storage/buckets
2. Cerca il bucket "moments" (se non esiste, crealo come "public")

### Passo 2: Configura le Policy RLS
1. Clicca sul bucket "moments"
2. Vai alla tab "Policies" 
3. Clicca "New Policy"
4. Aggiungi le seguenti 4 policy:

#### Policy 1: Upload (INSERT)
- **Name**: Users can upload to own folder
- **Operation**: INSERT
- **Policy Definition**: 
```sql
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### Policy 2: Update (UPDATE)
- **Name**: Users can update own files
- **Operation**: UPDATE  
- **Policy Definition**:
```sql
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### Policy 3: Delete (DELETE)
- **Name**: Users can delete own files
- **Operation**: DELETE
- **Policy Definition**:
```sql
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### Policy 4: Read (SELECT)
- **Name**: Public read access
- **Operation**: SELECT
- **Policy Definition**:
```sql
bucket_id = 'moments'
```

### Passo 3: Testa nell'app
Dopo aver aggiunto tutte e 4 le policy, riprova a creare un momento nell'app.

## Cosa fanno queste policy
- Gli utenti possono caricare file solo nella propria cartella (path = `{auth.uid()}/{filename}`)
- Gli utenti possono modificare/eliminare solo i propri file
- Tutti possono leggere i file pubblici nel bucket moments

## Novità 15 Nov 2025
- La migrazione `20251115_storage_media_policy.sql` crea automaticamente una funzione `public.moments_media_is_allowed(metadata, name)` e nuove policy che applicano i limiti peso (foto 6MB, video 80MB, audio 20MB). Assicurati di applicarla tramite CLI/Supabase migrations.
- La migrazione `20251115_advanced_media_metadata.sql` aggiunge colonne `media_size_bytes`, `media_duration_ms`, `media_processing_status` e i relativi constraint: applicala prima di lanciare la nuova app.
