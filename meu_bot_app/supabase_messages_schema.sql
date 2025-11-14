-- ============================================================================
-- TABELA DE MENSAGENS - Meu Bot App
-- ============================================================================
-- Esta tabela armazena o histórico completo de conversas entre usuários e bot
--
-- Para executar:
-- 1. Acesse https://app.supabase.com
-- 2. Vá em SQL Editor
-- 3. Cole e execute este script

-- Criar tabela de mensagens
CREATE TABLE IF NOT EXISTS messages (
  -- ID único da mensagem
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- ID do usuário (vem do auth.users)
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- ID único da mensagem no app (compatível com flutter_chat_ui)
  message_id TEXT NOT NULL,

  -- Autor da mensagem: 'user' ou 'bot'
  author_type TEXT NOT NULL CHECK (author_type IN ('user', 'bot')),

  -- Tipo da mensagem: 'text', 'image', 'audio', 'file'
  message_type TEXT NOT NULL CHECK (message_type IN ('text', 'image', 'audio', 'file')),

  -- Conteúdo da mensagem
  text_content TEXT,

  -- URI para imagem/áudio/arquivo (URL ou path local)
  media_uri TEXT,

  -- Nome do arquivo (para image/audio/file)
  file_name TEXT,

  -- Tamanho do arquivo em bytes
  file_size BIGINT,

  -- MIME type (para arquivos)
  mime_type TEXT,

  -- Timestamp da mensagem (milliseconds since epoch)
  created_at BIGINT NOT NULL,

  -- Data de criação no banco (para queries)
  db_created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Metadata adicional (JSON)
  metadata JSONB
);

-- Índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_user_created ON messages(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_message_id ON messages(message_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Garante que usuários só vejam suas próprias mensagens

-- Habilitar RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver apenas suas próprias mensagens
CREATE POLICY "Users can view own messages"
  ON messages
  FOR SELECT
  USING (auth.uid() = user_id);

-- Política: Usuários podem inserir suas próprias mensagens
CREATE POLICY "Users can insert own messages"
  ON messages
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: Usuários podem atualizar suas próprias mensagens
CREATE POLICY "Users can update own messages"
  ON messages
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Política: Usuários podem deletar suas próprias mensagens
CREATE POLICY "Users can delete own messages"
  ON messages
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- FUNÇÕES ÚTEIS
-- ============================================================================

-- Função para buscar mensagens recentes de um usuário
CREATE OR REPLACE FUNCTION get_recent_messages(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS SETOF messages
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM messages
  WHERE user_id = p_user_id
  ORDER BY created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- Função para contar mensagens de um usuário
CREATE OR REPLACE FUNCTION count_user_messages(p_user_id UUID)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::INT
  FROM messages
  WHERE user_id = p_user_id;
$$;

-- Função para deletar mensagens antigas (opcional - para manutenção)
CREATE OR REPLACE FUNCTION delete_old_messages(days_old INT DEFAULT 90)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM messages
  WHERE db_created_at < NOW() - (days_old || ' days')::INTERVAL;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- ============================================================================
-- COMENTÁRIOS NA TABELA
-- ============================================================================

COMMENT ON TABLE messages IS 'Armazena histórico de conversas entre usuários e bot';
COMMENT ON COLUMN messages.id IS 'ID único da mensagem no banco de dados';
COMMENT ON COLUMN messages.user_id IS 'ID do usuário dono da mensagem';
COMMENT ON COLUMN messages.message_id IS 'ID da mensagem no app (compatível com flutter_chat_ui)';
COMMENT ON COLUMN messages.author_type IS 'Quem enviou: user ou bot';
COMMENT ON COLUMN messages.message_type IS 'Tipo: text, image, audio, file';
COMMENT ON COLUMN messages.text_content IS 'Conteúdo textual da mensagem';
COMMENT ON COLUMN messages.media_uri IS 'URL ou caminho para mídia';
COMMENT ON COLUMN messages.created_at IS 'Timestamp em milliseconds since epoch';

-- ============================================================================
-- DADOS DE TESTE (OPCIONAL)
-- ============================================================================
-- Descomentar para adicionar mensagens de exemplo

/*
INSERT INTO messages (user_id, message_id, author_type, message_type, text_content, created_at)
VALUES
  (auth.uid(), gen_random_uuid()::text, 'bot', 'text', 'Olá! Como posso ajudar você hoje?', EXTRACT(EPOCH FROM NOW())::BIGINT * 1000),
  (auth.uid(), gen_random_uuid()::text, 'user', 'text', 'Olá! Tudo bem?', EXTRACT(EPOCH FROM NOW())::BIGINT * 1000 + 1000);
*/

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Execute para verificar se tudo foi criado corretamente

SELECT
  'Table created' as status,
  COUNT(*) as policies_count
FROM pg_policies
WHERE tablename = 'messages';

SELECT
  'Indexes created' as status,
  COUNT(*) as indexes_count
FROM pg_indexes
WHERE tablename = 'messages';

-- ============================================================================
-- SUCESSO! 🎉
-- ============================================================================
-- A tabela de mensagens está pronta para uso!
--
-- Próximos passos:
-- 1. O app Flutter já está configurado para usar esta tabela
-- 2. Mensagens serão salvas automaticamente ao enviar/receber
-- 3. Histórico será carregado ao abrir o chat
--
-- Consultas úteis:
-- - Ver todas suas mensagens: SELECT * FROM messages ORDER BY created_at DESC;
-- - Contar mensagens: SELECT count_user_messages(auth.uid());
-- - Deletar mensagens antigas: SELECT delete_old_messages(90);
