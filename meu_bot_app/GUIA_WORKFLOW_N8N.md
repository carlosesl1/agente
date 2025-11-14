# 🔄 Guia do Workflow N8N - Meu Bot App

## 📋 Visão Geral

Este documento explica como importar e usar o workflow de exemplo do N8N para integrar com o Meu Bot App.

---

## 🚀 Importar Workflow

### Método 1: Via Interface Web (Recomendado)

1. **Abra o N8N**
   ```
   - N8N Cloud: https://app.n8n.cloud
   - N8N Self-hosted: http://localhost:5678
   ```

2. **Importar arquivo JSON**
   - Clique em **"+"** no canto superior direito
   - Selecione **"Import from File"**
   - Escolha o arquivo `n8n_workflow_exemplo.json`
   - Clique em **"Import"**

3. **Ativar Webhook**
   - Clique no nó **"Webhook - Receber Mensagem"**
   - Na aba de configuração, você verá a **Production URL**
   - Copie essa URL (exemplo: `https://seu-n8n.app.n8n.cloud/webhook/bot-chat`)
   - Cole em `lib/config/app_config.dart` → `n8nWebhookUrl`

4. **Ativar Workflow**
   - No canto superior direito, toggle **"Active"** para ON
   - Status deve mudar para verde ✅

### Método 2: Via CLI (Avançado)

```bash
# Importar workflow via N8N CLI
n8n import:workflow --input=n8n_workflow_exemplo.json

# Ativar workflow
n8n workflow:activate --id=<workflow-id>
```

---

## 🧩 Estrutura do Workflow

### Fluxo de Dados

```
📱 App Flutter
    ↓
    POST /webhook/bot-chat
    {
      "userId": "user-123",
      "messageType": "text",
      "content": "Olá!",
      "timestamp": "2025-01-14T10:30:00Z"
    }
    ↓
🔵 Webhook - Receber Mensagem
    ↓
🔷 É Mensagem de Texto?
    ├─ SIM → Extrair Dados → Bot - Processar Texto
    └─ NÃO → É Imagem?
              ├─ SIM → Bot - Processar Imagem
              └─ NÃO → É Áudio?
                        ├─ SIM → Bot - Processar Áudio
                        └─ NÃO → Erro
    ↓
🔵 Responder para App
    ↓
    {
      "success": true,
      "response": {
        "type": "text",
        "text": "Olá! 👋 Como posso ajudar você hoje?",
        "data": null
      }
    }
    ↓
📱 App Flutter (recebe resposta)
```

---

## 📦 Nós do Workflow

### 1. Webhook - Receber Mensagem

**Tipo**: Trigger (Webhook)

**Configuração**:
- **HTTP Method**: POST
- **Path**: `bot-chat`
- **Response Mode**: Response Node

**O que faz**: Recebe requisições do app Flutter

---

### 2. É Mensagem de Texto?

**Tipo**: IF (Conditional)

**Condição**:
```javascript
{{ $json.body.messageType }} === "text"
```

**O que faz**: Verifica se é mensagem de texto

---

### 3. Extrair Dados

**Tipo**: Set (Data Transformation)

**Campos extraídos**:
- `userId` - ID do usuário
- `messageType` - Tipo (text/image/audio)
- `content` - Conteúdo da mensagem
- `timestamp` - Data/hora do envio

**O que faz**: Organiza dados em formato limpo

---

### 4. Bot - Processar Texto

**Tipo**: Code (JavaScript)

**Lógica implementada**:
```javascript
// Comandos reconhecidos:
- "olá", "oi", "hey" → Saudação
- "ajuda", "help" → Menu de ajuda
- "piada", "joke" → Conta piada aleatória
- "horas", "hora" → Mostra horário atual
- "data", "dia" → Mostra data atual
- Outros → Echo + sugestão
```

**Formato de resposta**:
```json
{
  "success": true,
  "response": {
    "type": "text",
    "text": "Resposta do bot aqui",
    "data": null
  },
  "metadata": {
    "processedAt": "2025-01-14T10:30:01Z",
    "userId": "user-123"
  }
}
```

**O que faz**: Processa mensagem de texto e gera resposta

---

### 5. Bot - Processar Imagem

**Tipo**: Code (JavaScript)

**Entrada esperada**:
```json
{
  "userId": "user-123",
  "messageType": "image",
  "content": "data:image/jpeg;base64,/9j/4AAQ...",
  "timestamp": "2025-01-14T10:30:00Z"
}
```

**O que faz**:
- Recebe imagem em base64
- Por enquanto: confirma recebimento
- **Futuro**: Integrar com:
  - Google Vision API (análise de imagem)
  - AWS Rekognition (reconhecimento facial)
  - Cloudinary (storage)

---

### 6. Bot - Processar Áudio

**Tipo**: Code (JavaScript)

**Entrada esperada**:
```json
{
  "userId": "user-123",
  "messageType": "audio",
  "content": "data:audio/m4a;base64,AAAAGG...",
  "timestamp": "2025-01-14T10:30:00Z"
}
```

**O que faz**:
- Recebe áudio em base64
- Por enquanto: confirma recebimento
- **Futuro**: Integrar com:
  - Google Speech-to-Text (transcrever)
  - OpenAI Whisper (transcrever)
  - Google Text-to-Speech (responder com voz)

---

### 7. Responder para App

**Tipo**: Respond to Webhook

**Configuração**:
- **Respond With**: JSON
- **Response Body**: `={{ $json }}`
- **Headers**:
  - Content-Type: application/json

**O que faz**: Envia resposta formatada de volta para o app

---

## 🤖 Integrações Avançadas

### Integrar com ChatGPT (OpenAI)

Adicione um nó **HTTP Request** antes do "Bot - Processar Texto":

```javascript
// Nó: HTTP Request
{
  "method": "POST",
  "url": "https://api.openai.com/v1/chat/completions",
  "headers": {
    "Authorization": "Bearer sk-seu-api-key",
    "Content-Type": "application/json"
  },
  "body": {
    "model": "gpt-3.5-turbo",
    "messages": [
      {
        "role": "system",
        "content": "Você é um assistente virtual amigável e prestativo."
      },
      {
        "role": "user",
        "content": "{{ $json.content }}"
      }
    ]
  }
}
```

**Processar resposta**:
```javascript
// Código JavaScript
return {
  success: true,
  response: {
    type: "text",
    text: $json.choices[0].message.content,
    data: null
  }
};
```

---

### Integrar com Claude (Anthropic)

```javascript
// Nó: HTTP Request
{
  "method": "POST",
  "url": "https://api.anthropic.com/v1/messages",
  "headers": {
    "x-api-key": "sk-ant-seu-api-key",
    "anthropic-version": "2023-06-01",
    "Content-Type": "application/json"
  },
  "body": {
    "model": "claude-3-sonnet-20240229",
    "max_tokens": 1024,
    "messages": [
      {
        "role": "user",
        "content": "{{ $json.content }}"
      }
    ]
  }
}
```

---

### Salvar Mensagens no Supabase

Adicione um nó **Supabase** para persistir conversas:

```javascript
// Nó: Supabase
{
  "operation": "insert",
  "table": "messages",
  "data": {
    "user_id": "{{ $json.userId }}",
    "message_type": "{{ $json.messageType }}",
    "content": "{{ $json.content }}",
    "bot_response": "{{ $json.response.text }}",
    "created_at": "{{ $json.timestamp }}"
  }
}
```

**Criar tabela no Supabase**:
```sql
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  message_type TEXT NOT NULL,
  content TEXT NOT NULL,
  bot_response TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

### Análise de Sentimentos

Use **Google Natural Language API**:

```javascript
// Nó: HTTP Request
{
  "method": "POST",
  "url": "https://language.googleapis.com/v1/documents:analyzeSentiment?key=SUA-API-KEY",
  "body": {
    "document": {
      "type": "PLAIN_TEXT",
      "content": "{{ $json.content }}"
    }
  }
}
```

**Ajustar resposta baseado em sentimento**:
```javascript
const sentiment = $json.documentSentiment.score;

if (sentiment < -0.5) {
  return "Percebi que você está chateado. Como posso ajudar? 😔";
} else if (sentiment > 0.5) {
  return "Que ótimo! Fico feliz em saber! 😊";
} else {
  return "Entendo. Conte-me mais...";
}
```

---

## 🧪 Testar Workflow

### Teste Manual via N8N

1. **Abra o workflow**
2. **Clique em "Execute Workflow"**
3. **No nó Webhook, clique em "Listen for Test Event"**
4. **Use curl ou Postman**:

```bash
curl -X POST https://seu-n8n.app/webhook/bot-chat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "messageType": "text",
    "content": "Olá bot!",
    "timestamp": "2025-01-14T10:30:00Z"
  }'
```

5. **Verifique resposta**:
```json
{
  "success": true,
  "response": {
    "type": "text",
    "text": "Olá! 👋 Como posso ajudar você hoje?",
    "data": null
  }
}
```

---

### Teste via App Flutter

1. **Configure URL em app_config.dart**
2. **Execute app**: `flutter run`
3. **Faça login/cadastro**
4. **Envie mensagem no chat**
5. **Observe no N8N**:
   - Aba "Executions" mostra cada requisição
   - Clique para ver dados de entrada/saída

---

## 📊 Monitoramento

### Ver Execuções

1. **N8N Interface** → Aba **"Executions"**
2. Cada linha mostra:
   - ✅ Sucesso ou ❌ Erro
   - ⏱️ Tempo de execução
   - 📊 Quantidade de nós processados

### Logs Úteis

No nó Code, adicione logs:
```javascript
console.log('Mensagem recebida:', $input.item.json.content);
console.log('Usuário:', $input.item.json.userId);
```

---

## 🔒 Segurança

### Validar Origem

Adicione autenticação no webhook:

```javascript
// Primeiro nó após Webhook
const authHeader = $json.headers.authorization;
const expectedToken = 'seu-token-secreto';

if (authHeader !== `Bearer ${expectedToken}`) {
  throw new Error('Unauthorized');
}
```

**No app Flutter** (`n8n_service.dart`):
```dart
headers: {
  'Authorization': 'Bearer seu-token-secreto',
}
```

### Rate Limiting

Use nó **Function** para limitar requisições:

```javascript
const userId = $json.userId;
const now = Date.now();

// Armazenar último acesso (usar Redis/DB em produção)
if (!global.lastAccess) global.lastAccess = {};

if (global.lastAccess[userId]) {
  const timeDiff = now - global.lastAccess[userId];
  if (timeDiff < 1000) { // < 1 segundo
    throw new Error('Too many requests. Wait 1 second.');
  }
}

global.lastAccess[userId] = now;
```

---

## 🎯 Próximos Passos

1. ✅ Importar workflow básico
2. ✅ Testar com app Flutter
3. 🔄 Integrar com IA (ChatGPT/Claude)
4. 💾 Adicionar persistência (Supabase)
5. 📊 Implementar analytics
6. 🔔 Enviar notificações proativas
7. 🌐 Suportar múltiplos idiomas
8. 🤝 Integrar com APIs externas

---

## 📚 Recursos Adicionais

- **N8N Docs**: https://docs.n8n.io
- **N8N Community**: https://community.n8n.io
- **Workflow Templates**: https://n8n.io/workflows
- **OpenAI API**: https://platform.openai.com/docs
- **Anthropic API**: https://docs.anthropic.com

---

**Última atualização**: 2025-01-14
**Versão do workflow**: 1.0
