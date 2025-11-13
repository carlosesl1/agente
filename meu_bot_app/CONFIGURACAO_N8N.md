# Configuração do N8N

Este guia explica como configurar o webhook do N8N para integração com o app de chat.

## Passo 1: Criar Workflow no N8N

1. Acesse seu N8N (cloud ou self-hosted)
2. Crie um novo workflow
3. Adicione um nó **Webhook** como trigger
4. Configure o Webhook:
   - **HTTP Method**: POST
   - **Path**: `/webhook/chat` (ou qualquer outro)
   - **Response Mode**: "When Last Node Finishes"

## Passo 2: Obter a URL do Webhook

Após configurar o webhook, você verá uma URL como:
```
https://seu-n8n.com/webhook/chat
```

Copie esta URL completa.

## Passo 3: Configurar no App

### Abra o arquivo:
```
lib/services/n8n_service.dart
```

### Localize a seguinte linha:
```dart
static const String WEBHOOK_URL = 'https://seu-n8n.com/webhook/chat';
```

### Substitua pela URL real:
```dart
static const String WEBHOOK_URL = 'https://sua-url-real.n8n.cloud/webhook/chat';
```

## Passo 4: Estrutura de Dados

### O app envia para o N8N:

```json
{
  "userId": "id-do-usuario-supabase",
  "messageType": "text|image|audio",
  "content": "texto ou base64 da mídia",
  "timestamp": "2025-01-13T10:30:00.000Z",
  "metadata": {
    "fileName": "image.jpg",
    "mimeType": "image/jpeg"
  }
}
```

**Tipos de mensagem:**
- `text` - Mensagem de texto simples
- `image` - Imagem em base64
- `audio` - Áudio em base64

### O N8N deve retornar:

```json
{
  "response": "Texto da resposta do bot",
  "type": "text|image|audio",
  "data": "URL ou base64 (se for mídia)",
  "metadata": {
    // Metadados opcionais
  }
}
```

**Campos:**
- `response` (obrigatório) - Texto da resposta
- `type` (obrigatório) - Tipo de resposta: "text", "image" ou "audio"
- `data` (opcional) - URL ou base64 se a resposta for mídia
- `metadata` (opcional) - Dados extras

## Passo 5: Exemplo de Workflow N8N

### Workflow Básico (Apenas Texto)

```
Webhook → Function → Respond to Webhook
```

**Nó Function (exemplo em JavaScript):**
```javascript
// Recebe os dados do app
const userId = $json.userId;
const messageType = $json.messageType;
const content = $json.content;

// Sua lógica de processamento aqui
// Exemplo: chamar OpenAI, Claude, etc.

// Retorna a resposta
return {
  json: {
    response: "Esta é a resposta do bot para: " + content,
    type: "text"
  }
};
```

### Workflow com IA (OpenAI/Claude)

```
Webhook → OpenAI → Function → Respond to Webhook
```

**Nó OpenAI:**
- Configure suas credenciais
- Use o texto recebido como prompt
- Modelo: GPT-4, GPT-3.5, etc.

**Nó Function:**
```javascript
// Formata a resposta da OpenAI
const aiResponse = $json.choices[0].message.content;

return {
  json: {
    response: aiResponse,
    type: "text"
  }
};
```

### Workflow com Imagens

Se quiser processar imagens:

```
Webhook → Function (decode base64) → Vision AI → Respond
```

**Nó Function (decode):**
```javascript
const imageBase64 = $json.content;

// Decodifica base64 se necessário
// Ou passa direto para o próximo nó

return {
  json: {
    image: imageBase64,
    userId: $json.userId
  }
};
```

## Passo 6: Testar a Integração

### No código, você pode testar a conexão:

```dart
// Em algum lugar do app (por exemplo, ao iniciar)
final isConnected = await N8nService.testConnection();
if (isConnected) {
  print('✓ N8N conectado!');
} else {
  print('✗ Erro ao conectar com N8N');
}
```

### Teste manual com cURL:

```bash
curl -X POST https://sua-url-n8n.com/webhook/chat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test123",
    "messageType": "text",
    "content": "Olá, bot!",
    "timestamp": "2025-01-13T10:30:00.000Z"
  }'
```

Deve retornar:
```json
{
  "response": "Resposta do bot",
  "type": "text"
}
```

## Formatos de Envio

### Por padrão, o app envia:
- **Texto**: JSON simples
- **Imagem**: Base64 no campo `content`
- **Áudio**: Base64 no campo `content`

### Se preferir enviar arquivos (multipart):

No código, use os métodos alternativos:
```dart
// Em vez de sendImage(), use:
await N8nService.sendImageMultipart(file, userId);

// Em vez de sendAudio(), use:
await N8nService.sendAudioMultipart(file, userId);
```

Isso envia os arquivos como `multipart/form-data` em vez de base64.

## Tratamento de Erros

O app já trata os seguintes erros:
- ✅ Timeout (30 segundos)
- ✅ Sem internet
- ✅ Erro do servidor (500, 404, etc)
- ✅ Requisição cancelada
- ✅ Certificado SSL inválido

Mensagens amigáveis são mostradas ao usuário automaticamente.

## Exemplo Completo de Workflow N8N

### Para um bot conversacional básico:

1. **Webhook** - Recebe mensagem
2. **IF Node** - Verifica tipo de mensagem
   - Se `text` → vai para OpenAI
   - Se `image` → vai para Vision AI
   - Se `audio` → vai para Transcrição
3. **OpenAI/Claude** - Processa a mensagem
4. **Function** - Formata resposta
5. **Respond to Webhook** - Retorna ao app

### Exemplo de resposta com imagem do bot:

```javascript
return {
  json: {
    response: "Aqui está a imagem que você pediu:",
    type: "image",
    data: "https://url-da-imagem.com/foto.jpg"
    // Ou use base64:
    // data: "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  }
};
```

## Debug e Logs

O app imprime logs úteis no console:
```
📤 Enviando mensagem para N8N: Olá!
📥 Resposta recebida do N8N: {...}
```

No N8N, ative **"Save Execution Progress"** para ver os dados em tempo real.

## Próximos Passos

Depois de configurar:
1. Teste enviar mensagens de texto
2. Teste enviar imagens
3. Teste gravação de áudio (quando implementado)
4. Configure IA (OpenAI, Claude, etc.) no N8N
5. Adicione lógica customizada ao workflow

## Recursos Úteis

- [Documentação N8N Webhooks](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [N8N Community](https://community.n8n.io/)
- [Exemplos de Workflows](https://n8n.io/workflows/)

## Troubleshooting

### "Timeout: Não foi possível conectar ao servidor"
- Verifique se a URL está correta
- Verifique se o N8N está online
- Teste a URL no navegador

### "Erro de conexão: Verifique sua internet"
- Verifique conexão WiFi/dados móveis
- Teste abrir outros sites

### "Erro do servidor (500)"
- Verifique os logs do workflow no N8N
- Veja se há erro em algum nó
- Teste o webhook manualmente com cURL

### App não recebe resposta
- Verifique se o workflow termina com "Respond to Webhook"
- Certifique-se que retorna JSON no formato correto
- Use Response Mode: "When Last Node Finishes"
