# 🎤 Formato de Envio de Áudio para N8N

## ✅ Mudança Implementada

O app agora envia áudio como **arquivo MP4** via **multipart/form-data**, permitindo que você faça a transcrição diretamente no N8N.

## 📤 Formato Anterior (Base64)

**❌ Antes** o áudio era enviado assim:

```json
POST /webhook
Content-Type: application/json

{
  "userId": "user123",
  "messageType": "audio",
  "content": "UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=",
  "timestamp": "2025-11-15T12:30:00.000Z",
  "metadata": {
    "fileName": "audio_123456.m4a",
    "mimeType": "audio/m4a",
    "duration": 0
  }
}
```

### Problemas do formato anterior:
- Áudio codificado em base64 (difícil de processar)
- Tamanho maior (base64 aumenta ~33%)
- Necessário decodificar antes de transcrever

## 📤 Formato Atual (Multipart)

**✅ Agora** o áudio é enviado assim:

```http
POST /webhook
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="userId"

user123
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="messageType"

audio
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="timestamp"

2025-11-15T12:30:00.000Z
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="audio"; filename="audio_123456.m4a"
Content-Type: audio/m4a

[BINARY AUDIO DATA]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

### Vantagens do formato atual:
- ✅ Arquivo MP4 nativo (pronto para transcrição)
- ✅ Tamanho menor (sem overhead de base64)
- ✅ Fácil de processar no N8N
- ✅ Compatível com APIs de transcrição (Whisper, etc)

## 🔧 Como Configurar o N8N

### 1. Webhook Node

Configure o Webhook para aceitar **multipart/form-data**:

```json
{
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300],
      "parameters": {
        "httpMethod": "POST",
        "path": "chatbot",
        "responseMode": "responseNode",
        "options": {
          "rawBody": false
        }
      }
    }
  ]
}
```

### 2. Processar o Áudio

O arquivo de áudio estará disponível em `$binary.audio`:

**Exemplo de nó para processar áudio:**

```json
{
  "name": "Process Audio",
  "type": "n8n-nodes-base.function",
  "position": [450, 300],
  "parameters": {
    "functionCode": "// Verifica se é mensagem de áudio\nconst messageType = items[0].json.messageType;\n\nif (messageType === 'audio') {\n  // O arquivo está em $binary.audio\n  const audioData = items[0].binary.audio;\n  \n  // Você pode:\n  // 1. Enviar para Whisper API\n  // 2. Salvar em storage\n  // 3. Processar diretamente\n  \n  return items;\n}\n\nreturn items;"
  }
}
```

### 3. Transcrever com Whisper (OpenAI)

Use o nó HTTP Request para enviar para Whisper API:

```json
{
  "name": "Whisper Transcription",
  "type": "n8n-nodes-base.httpRequest",
  "position": [650, 300],
  "parameters": {
    "method": "POST",
    "url": "https://api.openai.com/v1/audio/transcriptions",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "Bearer {{$credentials.openai.apiKey}}"
        }
      ]
    },
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "file",
          "value": "={{$binary.audio}}",
          "parameterType": "formBinaryData"
        },
        {
          "name": "model",
          "value": "whisper-1"
        },
        {
          "name": "language",
          "value": "pt"
        }
      ]
    },
    "options": {
      "bodyContentType": "multipart-form-data"
    }
  }
}
```

### 4. Workflow Completo de Exemplo

```
┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐
│ Webhook  │───▶│ Check Type   │───▶│ Whisper API  │───▶│ Response │
│  (POST)  │    │ (audio/text) │    │ (transcribe) │    │  (JSON)  │
└──────────┘    └──────────────┘    └──────────────┘    └──────────┘
```

**Pseudocódigo:**

1. **Webhook** recebe o request
2. **Check Type**:
   - Se `messageType === 'audio'`: vai para Whisper
   - Se `messageType === 'text'`: processa direto
3. **Whisper API**: transcreve o áudio
4. **Response**: retorna transcrição + resposta do bot

## 📋 Campos do Request

### Texto (JSON)
```json
{
  "userId": "string",
  "messageType": "text",
  "content": "string (mensagem de texto)",
  "timestamp": "ISO 8601 datetime"
}
```

### Imagem (Multipart)
```
userId: string
messageType: "image"
timestamp: ISO 8601 datetime
image: binary file (JPEG)
```

### Áudio (Multipart) ⭐ NOVO
```
userId: string
messageType: "audio"
timestamp: ISO 8601 datetime
audio: binary file (M4A/MP4)
```

## 🎯 Exemplo de Workflow N8N Completo

Aqui está um exemplo de workflow para processar áudio:

### Nó 1: Webhook
```json
{
  "name": "Chatbot Webhook",
  "type": "n8n-nodes-base.webhook",
  "parameters": {
    "httpMethod": "POST",
    "path": "chatbot",
    "responseMode": "responseNode"
  }
}
```

### Nó 2: Switch (Verificar tipo)
```json
{
  "name": "Check Message Type",
  "type": "n8n-nodes-base.switch",
  "parameters": {
    "rules": {
      "rules": [
        {
          "conditions": {
            "conditions": [
              {
                "value1": "={{$json.messageType}}",
                "value2": "audio"
              }
            ]
          },
          "output": 0
        },
        {
          "conditions": {
            "conditions": [
              {
                "value1": "={{$json.messageType}}",
                "value2": "text"
              }
            ]
          },
          "output": 1
        }
      ]
    }
  }
}
```

### Nó 3: Whisper (para áudio)
```json
{
  "name": "Transcribe Audio",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.openai.com/v1/audio/transcriptions",
    "sendBody": true,
    "contentType": "multipart-form-data",
    "bodyParameters": {
      "parameters": [
        {
          "name": "file",
          "value": "={{$binary.audio}}",
          "parameterType": "formBinaryData"
        },
        {
          "name": "model",
          "value": "whisper-1"
        }
      ]
    },
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "Bearer YOUR_OPENAI_KEY"
        }
      ]
    }
  }
}
```

### Nó 4: Process Response
```json
{
  "name": "Generate Bot Response",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": "// Pega a transcrição (se for áudio) ou texto direto\nconst text = $json.text || $json.content;\n\n// Processa com sua lógica de bot\n// ...\n\nreturn [\n  {\n    json: {\n      response: \"Resposta do bot aqui\",\n      type: \"text\"\n    }\n  }\n];"
  }
}
```

### Nó 5: Respond to Webhook
```json
{
  "name": "Response",
  "type": "n8n-nodes-base.respondToWebhook",
  "parameters": {
    "respondWith": "json",
    "responseBody": "={{$json}}"
  }
}
```

## 🧪 Testando no N8N

### 1. Teste com cURL (Texto)
```bash
curl -X POST https://seu-n8n.com/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test123",
    "messageType": "text",
    "content": "Olá, bot!",
    "timestamp": "2025-11-15T12:00:00.000Z"
  }'
```

### 2. Teste com cURL (Áudio)
```bash
curl -X POST https://seu-n8n.com/webhook/chatbot \
  -F "userId=test123" \
  -F "messageType=audio" \
  -F "timestamp=2025-11-15T12:00:00.000Z" \
  -F "audio=@audio_teste.m4a"
```

## 📱 Como Funciona no App

### Fluxo de Envio de Áudio:

1. **Usuário pressiona o botão de microfone** (quando campo está vazio)
2. **App inicia gravação** (botão fica vermelho)
3. **Usuário pressiona novamente** para parar
4. **App valida o áudio**:
   - Duração mínima: 1 segundo
   - Tamanho máximo: 5 MB
5. **App envia via multipart/form-data**:
   - Método: `N8nService.sendAudioMultipart()`
   - Formato: `audio/m4a`
6. **N8N recebe o arquivo** e pode transcrever
7. **App recebe resposta** do bot

### Fluxo de Envio de Texto:

1. **Usuário digita mensagem**
2. **Botão muda de microfone para seta**
3. **Usuário pressiona seta**
4. **App envia via JSON**
5. **N8N processa e responde**

## 🎨 Características do Novo Input

- ✅ **Botão dinâmico**: Microfone ↔ Seta
- ✅ **Feedback visual**: Vermelho quando gravando
- ✅ **Botão de anexo**: Para enviar imagens
- ✅ **TextField expansível**: Até 5 linhas
- ✅ **Estilo WhatsApp**: UX familiar

## 🔍 Debugging

### Ver dados recebidos no N8N:

Adicione um nó "Set" logo após o Webhook para inspecionar:

```json
{
  "name": "Debug",
  "type": "n8n-nodes-base.set",
  "parameters": {
    "values": {
      "values": [
        {
          "name": "userId",
          "value": "={{$json.userId}}"
        },
        {
          "name": "messageType",
          "value": "={{$json.messageType}}"
        },
        {
          "name": "hasAudioFile",
          "value": "={{!!$binary.audio}}"
        },
        {
          "name": "audioSize",
          "value": "={{$binary.audio?.fileSize || 0}}"
        }
      ]
    }
  }
}
```

## 📚 Recursos Úteis

- [N8N Webhook Docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [OpenAI Whisper API](https://platform.openai.com/docs/guides/speech-to-text)
- [Multipart Form Data](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)

## 💡 Dicas

1. **Use Whisper** para transcrição de qualidade
2. **Valide o tamanho** dos arquivos (limite 5MB no app)
3. **Adicione logging** no N8N para debug
4. **Teste com cURL** antes de integrar
5. **Configure timeout** adequado (áudios podem ser grandes)

## 🆘 Problemas Comuns

### "Binary data not found"
- Certifique-se que o Webhook aceita multipart/form-data
- Verifique se o campo se chama "audio"

### "Transcription failed"
- Confirme que a API key do OpenAI está correta
- Verifique se o formato é M4A/MP4
- Teste com áudio de amostra primeiro

### "Timeout"
- Aumente o timeout do N8N
- Considere processar áudios em background
- Use queue/worker para áudios longos
