-- ============================================================
-- Dashboard Supabase 数据库初始化脚本
-- 在 Supabase SQL Editor 中粘贴并运行此脚本
-- ============================================================
--
-- 重要设置（Supabase 控制台操作，非 SQL）：
-- 1. Authentication > Settings > 取消勾选 "Confirm email"
--    （开发阶段禁用邮箱验证，否则注册后需去邮箱点确认链接）
-- 2. 如果要启用邮箱验证，需配置 SMTP
-- ============================================================

-- 1. 创建表
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL DEFAULT '未命名',
  content TEXT DEFAULT '',
  tags TEXT[] DEFAULT '{}',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  text TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
  category TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT DEFAULT '其他',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  name TEXT DEFAULT '匿名',
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 启用 Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 3. Notes 策略：拥有者完全控制，任何人都能读公开笔记
DROP POLICY IF EXISTS notes_owner_all ON notes;
CREATE POLICY notes_owner_all ON notes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS notes_public_read ON notes;
CREATE POLICY notes_public_read ON notes FOR SELECT
  USING (is_public = true);

-- 4. Todos 策略：仅拥有者
DROP POLICY IF EXISTS todos_owner_all ON todos;
CREATE POLICY todos_owner_all ON todos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Bookmarks 策略：仅拥有者
DROP POLICY IF EXISTS bookmarks_owner_all ON bookmarks;
CREATE POLICY bookmarks_owner_all ON bookmarks FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 6. Messages 策略：任何人可读可写，仅作者或任何登录用户可删除
DROP POLICY IF EXISTS messages_public_read ON messages;
CREATE POLICY messages_public_read ON messages FOR SELECT
  USING (true);

DROP POLICY IF EXISTS messages_public_insert ON messages;
CREATE POLICY messages_public_insert ON messages FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS messages_delete ON messages;
CREATE POLICY messages_delete ON messages FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);

-- 7. 索引
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_public ON notes(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_notes_created ON notes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_todos_user ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
