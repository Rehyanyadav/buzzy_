-- FINAL NEXUS DATABASE SCHEMA
-- This script contains all tables, columns, and RLS policies for the complete Nexus app.
-- Use this in the Supabase SQL Editor (https://app.supabase.com)

-- 1. PROFILES TABLE
-- Stores user identity, couple linking, mood, and typing status.
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT DEFAULT 'Hey there! Building our world together.',
  partner_id UUID REFERENCES public.profiles(id),
  mood_emoji TEXT DEFAULT '🤍',
  mood_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_typing_in UUID REFERENCES public.profiles(id),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  blocked_ids UUID[] DEFAULT '{}',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration for existing profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT 'Hey there! Building our world together.';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_typing_in UUID REFERENCES public.profiles(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS blocked_ids UUID[] DEFAULT '{}';

-- 2. MESSAGES TABLE
-- Supports text, media, forwarding, and threaded replies.
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text', -- 'text', 'image', 'video', 'audio', 'file'
  media_url TEXT,
  duration_ms INTEGER,
  is_read BOOLEAN DEFAULT FALSE,
  reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  is_forwarded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration for existing messages
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'text';
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS duration_ms INTEGER;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_forwarded BOOLEAN DEFAULT FALSE;

-- 3. SCRAPBOOK TABLE
-- Shared photos and memories.
CREATE TABLE IF NOT EXISTS public.scrapbook_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  uploader_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  couple_id TEXT NOT NULL,
  image_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. VAULT TABLE
-- Private secure items for each user.
CREATE TABLE IF NOT EXISTS public.vault_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. AUTOMATION: PROFILE CREATION
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (new.id, new.email, split_part(new.email, '@', 1));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. ENABLE REALTIME
-- If these fail with "already member", it's safe to ignore.
-- ALTER PUBLICATION supabase_realtime ADD TABLE messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
-- ALTER PUBLICATION supabase_realtime ADD TABLE scrapbook_items;
-- ALTER PUBLICATION supabase_realtime ADD TABLE vault_items;

-- 7. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scrapbook_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;

-- Profile Policies
DROP POLICY IF EXISTS "Profiles viewable by anyone" ON public.profiles;
CREATE POLICY "Profiles viewable by anyone" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Message Policies
DROP POLICY IF EXISTS "Messages viewable by sender and receiver" ON public.messages;
CREATE POLICY "Messages viewable by sender and receiver" ON public.messages 
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert messages" ON public.messages;
CREATE POLICY "Users can insert messages" ON public.messages 
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can delete messages" ON public.messages;
CREATE POLICY "Users can delete messages" ON public.messages 
  FOR DELETE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Scrapbook Policies
DROP POLICY IF EXISTS "Scrapbook items viewable by everyone" ON public.scrapbook_items;
CREATE POLICY "Scrapbook items viewable by everyone" ON public.scrapbook_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert scrapbook items" ON public.scrapbook_items;
CREATE POLICY "Users can insert scrapbook items" ON public.scrapbook_items 
  FOR INSERT WITH CHECK (auth.uid() = uploader_id);

-- Vault Policies (Owner Only)
DROP POLICY IF EXISTS "Vault owner access" ON public.vault_items;
CREATE POLICY "Vault owner access" ON public.vault_items 
  FOR ALL USING (auth.uid() = owner_id);

-- 8. STORAGE BUCKETS (Run these in SQL editor)
-- Note: Supabase Storage also requires its own policies.
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('chat_media', 'chat_media', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('scrapbook', 'scrapbook', true) ON CONFLICT (id) DO NOTHING;

-- Storage Policies (Simplified for development)
-- In a real app, you would restrict these significantly.
-- For now, we allow authenticated users to upload and anyone to read.

-- Chat Media Policies
CREATE POLICY "Chat media public access" ON storage.objects FOR SELECT USING (bucket_id = 'chat_media');
CREATE POLICY "Chat media upload access" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'chat_media' AND auth.role() = 'authenticated');

-- Scrapbook Policies
CREATE POLICY "Scrapbook public access" ON storage.objects FOR SELECT USING (bucket_id = 'scrapbook');
CREATE POLICY "Scrapbook upload access" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'scrapbook' AND auth.role() = 'authenticated');
