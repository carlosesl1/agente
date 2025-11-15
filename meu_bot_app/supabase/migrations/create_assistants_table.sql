-- Tabela de assistentes virtuais
-- Permite que cada usuário tenha múltiplos assistentes personalizados

CREATE TABLE IF NOT EXISTS assistants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  avatar_url TEXT,
  webhook_url TEXT NOT NULL,
  primary_color INTEGER NOT NULL DEFAULT 4283215696, -- 0xFF2196F3 (azul)
  secondary_color INTEGER NOT NULL DEFAULT 4288423856, -- 0xFF9E9E9E (cinza)
  unread_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Adicionar foreign key apenas se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'assistants_user_id_fkey'
  ) THEN
    ALTER TABLE assistants
    ADD CONSTRAINT assistants_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_assistants_user_id ON assistants(user_id);
CREATE INDEX IF NOT EXISTS idx_assistants_created_at ON assistants(created_at DESC);

-- RLS (Row Level Security)
ALTER TABLE assistants ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Users can view their own assistants" ON assistants;
DROP POLICY IF EXISTS "Users can insert their own assistants" ON assistants;
DROP POLICY IF EXISTS "Users can update their own assistants" ON assistants;
DROP POLICY IF EXISTS "Users can delete their own assistants" ON assistants;

-- Políticas RLS
CREATE POLICY "Users can view their own assistants"
  ON assistants FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own assistants"
  ON assistants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own assistants"
  ON assistants FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own assistants"
  ON assistants FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_assistants_updated_at ON assistants;

CREATE TRIGGER update_assistants_updated_at
  BEFORE UPDATE ON assistants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Adicionar coluna assistant_id na tabela messages (relacionamento)
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS assistant_id UUID;

-- Adicionar foreign key apenas se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'messages_assistant_id_fkey'
  ) THEN
    ALTER TABLE messages
    ADD CONSTRAINT messages_assistant_id_fkey
    FOREIGN KEY (assistant_id) REFERENCES assistants(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Índice para performance nas mensagens por assistente
CREATE INDEX IF NOT EXISTS idx_messages_assistant_id ON messages(assistant_id);

-- Função para incrementar contador de mensagens não lidas
CREATE OR REPLACE FUNCTION increment_unread_count(assistant_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE assistants
  SET unread_count = unread_count + 1
  WHERE id = assistant_id_param;
END;
$$ LANGUAGE plpgsql;

-- Comentários
COMMENT ON TABLE assistants IS 'Armazena assistentes virtuais personalizados por usuário';
COMMENT ON COLUMN assistants.user_id IS 'ID do usuário dono do assistente';
COMMENT ON COLUMN assistants.name IS 'Nome do assistente (ex: Trabalho, Casa, Finanças)';
COMMENT ON COLUMN assistants.avatar_url IS 'URL do avatar personalizado (opcional)';
COMMENT ON COLUMN assistants.webhook_url IS 'URL do webhook N8N específico deste assistente';
COMMENT ON COLUMN assistants.primary_color IS 'Cor primária do assistente (int ARGB)';
COMMENT ON COLUMN assistants.secondary_color IS 'Cor secundária do assistente (int ARGB)';
COMMENT ON COLUMN assistants.unread_count IS 'Contador de mensagens não lidas';

