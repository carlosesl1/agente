-- ========================================
-- SCHEMA: Tabela para armazenar tokens FCM
-- ========================================

-- Criação da tabela fcm_tokens
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    UNIQUE(user_id, platform)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON public.fcm_tokens(fcm_token);

-- ========================================
-- RLS (Row Level Security)
-- ========================================

-- Habilita RLS
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Usuário pode ver apenas seus próprios tokens
CREATE POLICY "Users can view own tokens"
    ON public.fcm_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Usuário pode inserir/atualizar seus próprios tokens
CREATE POLICY "Users can insert own tokens"
    ON public.fcm_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens"
    ON public.fcm_tokens
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Usuário pode deletar seus próprios tokens
CREATE POLICY "Users can delete own tokens"
    ON public.fcm_tokens
    FOR DELETE
    USING (auth.uid() = user_id);

-- ========================================
-- Função para atualizar updated_at automaticamente
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_fcm_tokens_updated_at ON public.fcm_tokens;
CREATE TRIGGER update_fcm_tokens_updated_at
    BEFORE UPDATE ON public.fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- Comentários
-- ========================================

COMMENT ON TABLE public.fcm_tokens IS 'Armazena tokens FCM para notificações push';
COMMENT ON COLUMN public.fcm_tokens.user_id IS 'ID do usuário (referencia auth.users)';
COMMENT ON COLUMN public.fcm_tokens.fcm_token IS 'Token FCM do dispositivo';
COMMENT ON COLUMN public.fcm_tokens.platform IS 'Plataforma: android ou ios';
COMMENT ON COLUMN public.fcm_tokens.updated_at IS 'Última atualização do token';
