# 💾 Configuração de Persistência de Mensagens

## 📋 Visão Geral

Este guia mostra como configurar a persistência de mensagens no Supabase, permitindo que o histórico de conversas seja salvo e carregado automaticamente.

---

## 🎯 O Que Você Vai Conseguir

Depois de configurar a persistência:

- ✅ **Histórico completo**: Todas as mensagens são salvas automaticamente
- ✅ **Sincronização**: Conversas acessíveis em qualquer dispositivo
- ✅ **Backup automático**: Dados seguros no Supabase
- ✅ **Busca avançada**: Pesquisar mensagens antigas
- ✅ **Exportação**: Fazer backup das conversas

---

## ⚡ Setup Rápido (3 minutos)

### Passo 1: Acessar o SQL Editor do Supabase

1. Acesse https://app.supabase.com
2. Selecione seu projeto: **agente-app-16c01**
3. No menu lateral, clique em **SQL Editor**

### Passo 2: Executar o Script SQL

1. No SQL Editor, clique em **"+ New query"**
2. Abra o arquivo `supabase_messages_schema.sql` (está na raiz do projeto)
3. **Copie TODO o conteúdo** do arquivo
4. **Cole** no SQL Editor do Supabase
5. Clique em **"Run"** (ou pressione Ctrl+Enter)

### Passo 3: Verificar Criação

Após executar, você deve ver mensagens de sucesso:

```
Table created
Indexes created
```

Verifique se a tabela foi criada:
1. Vá em **Table Editor** (menu lateral)
2. Procure pela tabela **`messages`**
3. Deve aparecer na lista de tabelas

---

## 📊 Estrutura da Tabela

A tabela `messages` armazena todas as informações sobre cada mensagem:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | ID único no banco de dados |
| `user_id` | UUID | ID do usuário (referência auth.users) |
| `message_id` | TEXT | ID da mensagem no app |
| `author_type` | TEXT | 'user' ou 'bot' |
| `message_type` | TEXT | 'text', 'image', 'audio', 'file' |
| `text_content` | TEXT | Conteúdo textual |
| `media_uri` | TEXT | URL/caminho para mídia |
| `file_name` | TEXT | Nome do arquivo |
| `file_size` | BIGINT | Tamanho em bytes |
| `mime_type` | TEXT | Tipo MIME (para arquivos) |
| `created_at` | BIGINT | Timestamp (milissegundos) |
| `db_created_at` | TIMESTAMP | Data de criação no banco |
| `metadata` | JSONB | Dados adicionais (JSON) |

---

## 🔒 Segurança (Row Level Security)

A tabela já está configurada com **RLS (Row Level Security)**:

### O que isso significa?
- ✅ Cada usuário **só vê** suas próprias mensagens
- ✅ Ninguém pode acessar conversas de outros usuários
- ✅ Totalmente seguro e privado

### Políticas Configuradas:
1. **SELECT**: Ver apenas suas mensagens
2. **INSERT**: Criar apenas suas mensagens
3. **UPDATE**: Editar apenas suas mensagens
4. **DELETE**: Deletar apenas suas mensagens

---

## 🚀 Como Funciona no App

### Salvamento Automático

Toda vez que você **envia ou recebe** uma mensagem:

```dart
// 1. Mensagem é adicionada ao chat
_addMessage(textMessage);

// 2. Automaticamente salva no Supabase
MessageService.saveMessage(message, userId);
```

### Carregamento Automático

Ao **abrir o chat**:

```dart
// 1. Carrega últimas 50 mensagens
final messages = await MessageService.loadMessages(userId, limit: 50);

// 2. Exibe no chat
setState(() {
  _messages.addAll(messages);
});
```

### Indicador Visual

- 🔄 **"Carregando conversas..."** → Buscando do banco
- 💬 **Mensagens aparecem** → Histórico carregado
- ✅ **Pronto para usar** → Pode enviar novas mensagens

---

## 🛠 Operações Disponíveis

O `MessageService` oferece várias operações:

### 1. Salvar Mensagem
```dart
await MessageService.saveMessage(message, userId);
```

### 2. Carregar Mensagens
```dart
// Últimas 50 mensagens
final messages = await MessageService.loadMessages(userId, limit: 50);

// Com paginação
final more = await MessageService.loadMessages(
  userId,
  limit: 20,
  offset: 50, // Próximas 20 após as primeiras 50
);
```

### 3. Buscar por Texto
```dart
final results = await MessageService.searchMessages(
  userId,
  'palavra chave',
);
```

### 4. Deletar Mensagem
```dart
await MessageService.deleteMessage(messageId);
```

### 5. Deletar Todas as Mensagens
```dart
await MessageService.deleteAllMessages(userId);
```

### 6. Contar Mensagens
```dart
final count = await MessageService.countMessages(userId);
print('Total de mensagens: $count');
```

### 7. Exportar Mensagens (Backup)
```dart
final backup = await MessageService.exportMessages(userId);
// Retorna List<Map<String, dynamic>> - pode salvar como JSON
```

---

## 📱 Testando a Persistência

### Teste 1: Enviar e Fechar

1. Abra o app e faça login
2. Envie algumas mensagens para o bot
3. **Feche completamente o app**
4. Abra novamente
5. ✅ As mensagens devem aparecer automaticamente!

### Teste 2: Trocar de Conta

1. Faça login com `usuario1@email.com`
2. Envie mensagens
3. Faça logout
4. Crie/login com `usuario2@email.com`
5. ✅ Não deve ver mensagens do usuario1 (segurança RLS)

### Teste 3: Ver no Supabase

1. Acesse Supabase → **Table Editor**
2. Selecione tabela **`messages`**
3. ✅ Deve ver suas mensagens salvas

---

## 🔍 Consultas SQL Úteis

### Ver suas mensagens (no SQL Editor do Supabase):

```sql
-- Todas as mensagens do usuário autenticado
SELECT * FROM messages
WHERE user_id = auth.uid()
ORDER BY created_at DESC;

-- Contar mensagens
SELECT COUNT(*) as total
FROM messages
WHERE user_id = auth.uid();

-- Mensagens dos últimos 7 dias
SELECT * FROM messages
WHERE user_id = auth.uid()
  AND db_created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

-- Buscar por texto
SELECT * FROM messages
WHERE user_id = auth.uid()
  AND text_content ILIKE '%palavra%'
ORDER BY created_at DESC;
```

---

## 🧹 Manutenção

### Deletar Mensagens Antigas (90+ dias)

Execute no SQL Editor do Supabase:

```sql
SELECT delete_old_messages(90);
```

Isso deleta mensagens com mais de 90 dias (customizável).

### Limpar Todas as Mensagens (Cuidado!)

```sql
DELETE FROM messages
WHERE user_id = auth.uid();
```

---

## 🐛 Troubleshooting

### Mensagens não aparecem ao reabrir app

**Causa**: Possível erro ao carregar do banco

**Solução**:
1. Verificar se a tabela foi criada no Supabase
2. Verificar logs do console:
   ```
   ✓ 5 mensagens carregadas do banco
   ```
3. Se aparecer erro, verificar políticas RLS

### "Permission denied for table messages"

**Causa**: RLS não configurado corretamente

**Solução**:
1. Execute o script SQL completo novamente
2. Verifique se as políticas foram criadas:
   ```sql
   SELECT * FROM pg_policies
   WHERE tablename = 'messages';
   ```

### Mensagens duplicadas

**Causa**: Salvamento múltiplo da mesma mensagem

**Solução**: Já tratado no código - cada mensagem tem ID único

---

## 📈 Melhorias Futuras (Opcionais)

### 1. Paginação Infinita
Carregar mais mensagens ao rolar para cima:
```dart
// Implementar onEndReached no Chat widget
onEndReached: () async {
  final more = await MessageService.loadMessages(
    userId,
    limit: 20,
    offset: _messages.length,
  );
  setState(() {
    _messages.addAll(more);
  });
}
```

### 2. Sincronização em Tempo Real
Usar Supabase Realtime para sincronizar entre dispositivos:
```dart
SupabaseService.client
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) {
    // Atualizar UI com novas mensagens
  });
```

### 3. Upload de Mídia
Salvar imagens/áudios no Supabase Storage:
```dart
final path = await SupabaseService.client.storage
  .from('messages-media')
  .upload('$userId/$messageId.jpg', imageFile);
```

### 4. Backup Automático
Exportar conversas periodicamente:
```dart
// Executar a cada 7 dias
final backup = await MessageService.exportMessages(userId);
await saveToDevice(json.encode(backup));
```

---

## ✅ Checklist de Configuração

Marque conforme completa:

- [ ] Script SQL executado no Supabase
- [ ] Tabela `messages` criada
- [ ] Políticas RLS ativas
- [ ] App testado: enviar mensagens
- [ ] App testado: fechar e reabrir
- [ ] Mensagens persistem entre sessões
- [ ] Segurança RLS verificada (usuários diferentes)

---

## 📚 Arquivos Relacionados

- **SQL**: `supabase_messages_schema.sql` - Schema da tabela
- **Service**: `lib/services/message_service.dart` - Lógica de persistência
- **UI**: `lib/screens/chat_screen.dart` - Integração com chat

---

## 🎉 Pronto!

Sua persistência de mensagens está configurada e funcionando!

**Benefícios**:
- 💾 Histórico completo salvo
- 🔒 Dados seguros e privados
- 🚀 Carregamento rápido
- 🔄 Sincronização automática

**Próximos passos sugeridos**:
1. Testar envio/recebimento de mensagens
2. Verificar persistência ao fechar app
3. Explorar recursos avançados (busca, exportação)
4. Considerar melhorias futuras (paginação, realtime)

---

**Última atualização**: 2025-01-14
**Versão**: 1.0
