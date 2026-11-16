-- ============================================================
-- FIX: messages FK violation — "conversations" row missing
-- Run this ONCE in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Backfill: create a conversation row for every existing application
--    (the app uses application.id as conversation.id)
INSERT INTO conversations (id)
SELECT id FROM applications
ON CONFLICT (id) DO NOTHING;

-- 2. Auto-create conversation whenever a new application is inserted
--    (belt-and-suspenders alongside the Dart upsert)
CREATE OR REPLACE FUNCTION create_conversation_for_application()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO conversations (id) VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_application_conversation ON applications;
CREATE TRIGGER trg_application_conversation
  AFTER INSERT ON applications
  FOR EACH ROW EXECUTE FUNCTION create_conversation_for_application();

-- 3. RLS: allow participants to read/write in their conversation
--    (the conversation id = application id, so we join through applications)

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view conversation" ON conversations;
CREATE POLICY "Participants can view conversation"
  ON conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM applications a
      WHERE a.id = conversations.id
        AND (
          a.applicant_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM jobs j
            WHERE j.id = a.job_id AND j.posted_by = auth.uid()
          )
        )
    )
  );

DROP POLICY IF EXISTS "Participants can insert conversation" ON conversations;
CREATE POLICY "Participants can insert conversation"
  ON conversations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM applications a
      WHERE a.id = conversations.id
        AND (
          a.applicant_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM jobs j
            WHERE j.id = a.job_id AND j.posted_by = auth.uid()
          )
        )
    )
  );

-- 4. RLS: messages — only conversation participants can read/write
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can read messages" ON messages;
CREATE POLICY "Participants can read messages"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM applications a
      WHERE a.id = messages.conversation_id
        AND (
          a.applicant_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM jobs j
            WHERE j.id = a.job_id AND j.posted_by = auth.uid()
          )
        )
    )
  );

DROP POLICY IF EXISTS "Participants can send messages" ON messages;
CREATE POLICY "Participants can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM applications a
      WHERE a.id = messages.conversation_id
        AND (
          a.applicant_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM jobs j
            WHERE j.id = a.job_id AND j.posted_by = auth.uid()
          )
        )
    )
  );
