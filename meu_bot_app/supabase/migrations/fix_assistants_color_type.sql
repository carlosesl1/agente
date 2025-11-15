-- Corrige o tipo das colunas de cor para suportar valores unsigned de 32 bits
-- Flutter Color.value retorna valores entre 0 e 4294967295 (unsigned int)
-- PostgreSQL INTEGER aceita apenas -2147483648 a 2147483647 (signed int)
-- Solução: usar BIGINT que suporta valores maiores

ALTER TABLE assistants
ALTER COLUMN primary_color TYPE BIGINT;

ALTER TABLE assistants
ALTER COLUMN secondary_color TYPE BIGINT;

-- Atualiza os comentários
COMMENT ON COLUMN assistants.primary_color IS 'Cor primária do assistente (ARGB como BIGINT para suportar valores unsigned)';
COMMENT ON COLUMN assistants.secondary_color IS 'Cor secundária do assistente (ARGB como BIGINT para suportar valores unsigned)';
