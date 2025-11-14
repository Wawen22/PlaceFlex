-- Fix Storage RLS policies for moments bucket
-- These policies must be added via Supabase Dashboard > Storage > Buckets > moments > Policies
-- NOT via SQL Editor (requires superuser permissions)

-- INSTRUCTIONS:
-- 1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/storage/buckets
-- 2. Click on "moments" bucket (or create it as public if it doesn't exist)
-- 3. Go to "Policies" tab
-- 4. Click "New Policy" and add each of the following 4 policies:

-- ============================================
-- Policy 1: INSERT (Upload to own folder)
-- ============================================
-- Name: Users can upload to own folder
-- Allowed operation: INSERT
-- Policy definition:
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]

-- ============================================
-- Policy 2: UPDATE (Update own files)
-- ============================================
-- Name: Users can update own files
-- Allowed operation: UPDATE
-- Policy definition:
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]

-- ============================================
-- Policy 3: DELETE (Delete own files)
-- ============================================
-- Name: Users can delete own files
-- Allowed operation: DELETE
-- Policy definition:
bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]

-- ============================================
-- Policy 4: SELECT (Public read access)
-- ============================================
-- Name: Public read access
-- Allowed operation: SELECT
-- Policy definition:
bucket_id = 'moments'

