# 📅 Configuração de Mensagens Programadas do N8N

## 🎯 Objetivo

Configurar o N8N para enviar mensagens automáticas para o app em horários específicos (ex: meio dia), com notificações push.

## 🔧 Pré-requisitos

1. **Firebase Cloud Messaging (FCM)** configurado
2. **Supabase** com tabela `fcm_tokens` criada
3. **N8N** instalado e rodando
4. **Service Account Key** do Firebase

## 📋 Passo a Passo

### 1. Criar Tabela no Supabase

Execute o SQL em `supabase_fcm_tokens_schema.sql`:

```bash
# No Supabase Dashboard > SQL Editor
# Cole e execute o conteúdo do arquivo
```

A tabela `fcm_tokens` armazenará os tokens FCM de cada usuário.

### 2. Obter Service Account Key do Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. **Configurações do Projeto** (ícone de engrenagem) → **Contas de Serviço**
4. Clique em **Gerar nova chave privada**
5. Salve o arquivo JSON (ex: `firebase-service-account.json`)

**Conteúdo do arquivo:**
```json
{
  "type": "service_account",
  "project_id": "seu-projeto-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-...@seu-projeto-id.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

### 3. Criar Workflow no N8N

#### **Nó 1: Schedule Trigger (Agendamento)**

```json
{
  "name": "Trigger às 12h",
  "type": "n8n-nodes-base.scheduleTrigger",
  "position": [250, 300],
  "parameters": {
    "rule": {
      "interval": [
        {
          "field": "hours",
          "hoursInterval": 1
        }
      ]
    },
    "triggerTimes": {
      "item": [
        {
          "hour": 12,
          "minute": 0
        }
      ]
    }
  }
}
```

**Opções de agendamento:**
- **Diário às 12h**: `hour: 12, minute: 0`
- **A cada hora**: `hoursInterval: 1`
- **Dias específicos**: Configure em `cronExpression`

#### **Nó 2: Supabase - Buscar Tokens FCM**

Busca todos os tokens FCM ativos:

```json
{
  "name": "Get FCM Tokens",
  "type": "n8n-nodes-base.supabase",
  "position": [450, 300],
  "credentials": {
    "supabaseApi": {
      "id": "1",
      "name": "Supabase API"
    }
  },
  "parameters": {
    "operation": "getAll",
    "tableId": "fcm_tokens",
    "returnAll": true
  }
}
```

**Configuração de credenciais Supabase:**
- URL: `https://seu-projeto.supabase.co`
- Service Role Key: Encontrado em Project Settings → API

#### **Nó 3: Function - Preparar Mensagem**

Prepara a mensagem a ser enviada:

```javascript
// items contém todos os tokens FCM

const message = {
  title: "Lembrete do Bot",
  body: "Olá! São 12h, hora de verificar suas tarefas! 🤖",
  data: {
    message: "Olá! São 12h, hora de verificar suas tarefas!",
    type: "text",
    timestamp: new Date().toISOString()
  }
};

// Retorna um item por token
return items.map(item => ({
  json: {
    fcmToken: item.json.fcm_token,
    userId: item.json.user_id,
    platform: item.json.platform,
    notification: message
  }
}));
```

#### **Nó 4: HTTP Request - Enviar via FCM**

Envia notificação push para cada token:

```json
{
  "name": "Send Push Notification",
  "type": "n8n-nodes-base.httpRequest",
  "position": [650, 300],
  "parameters": {
    "method": "POST",
    "url": "https://fcm.googleapis.com/v1/projects/SEU_PROJECT_ID/messages:send",
    "authentication": "genericCredentialType",
    "genericAuthType": "oAuth2Api",
    "sendBody": true,
    "bodyContentType": "json",
    "jsonBody": "={{JSON.stringify({\n  \"message\": {\n    \"token\": $json.fcmToken,\n    \"notification\": {\n      \"title\": $json.notification.title,\n      \"body\": $json.notification.body\n    },\n    \"data\": $json.notification.data,\n    \"android\": {\n      \"priority\": \"high\"\n    },\n    \"apns\": {\n      \"headers\": {\n        \"apns-priority\": \"10\"\n      }\n    }\n  }\n})}}",
    "options": {}
  }
}
```

**⚠️ Importante**: Substitua `SEU_PROJECT_ID` pelo ID do seu projeto Firebase.

### 4. Autenticação OAuth2 do FCM

Para autenticar com FCM v1 API, você precisa usar OAuth2:

#### Opção A: Usar Access Token

1. Instale Google Auth Library:
```bash
npm install google-auth-library
```

2. Crie um nó Function para gerar access token:
```javascript
const { GoogleAuth } = require('google-auth-library');

const serviceAccount = {
  "type": "service_account",
  "project_id": "seu-projeto-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-...@seu-projeto-id.iam.gserviceaccount.com"
};

const auth = new GoogleAuth({
  credentials: serviceAccount,
  scopes: ['https://www.googleapis.com/auth/firebase.messaging']
});

const accessToken = await auth.getAccessToken();

return [{
  json: {
    ...items[0].json,
    accessToken: accessToken
  }
}];
```

3. Use o token no HTTP Request:
```json
{
  "headerParameters": {
    "parameters": [
      {
        "name": "Authorization",
        "value": "=Bearer {{$json.accessToken}}"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  }
}
```

#### Opção B: Usar HTTP Request com Service Account (Mais Simples)

Use a biblioteca Firebase Admin SDK diretamente no N8N:

```javascript
// Nó Function
const admin = require('firebase-admin');

// Inicializa (apenas uma vez)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      "project_id": "seu-projeto-id",
      "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-...@seu-projeto-id.iam.gserviceaccount.com"
    })
  });
}

// Envia notificação para cada token
const results = [];

for (const item of items) {
  try {
    const message = {
      token: item.json.fcmToken,
      notification: {
        title: "Lembrete do Bot",
        body: "Olá! São 12h, hora de verificar suas tarefas! 🤖"
      },
      data: {
        message: "Olá! São 12h, hora de verificar suas tarefas!",
        type: "text",
        userId: item.json.userId,
        timestamp: new Date().toISOString()
      }
    };

    const response = await admin.messaging().send(message);

    results.push({
      json: {
        userId: item.json.userId,
        success: true,
        messageId: response
      }
    });
  } catch (error) {
    results.push({
      json: {
        userId: item.json.userId,
        success: false,
        error: error.message
      }
    });
  }
}

return results;
```

### 5. Workflow Completo Simplificado

```
┌─────────────┐    ┌──────────────┐    ┌───────────────┐    ┌──────────┐
│  Schedule   │───▶│ Get FCM      │───▶│ Send Push     │───▶│   Log    │
│  (12:00)    │    │ Tokens       │    │ Notification  │    │  Result  │
└─────────────┘    └──────────────┘    └───────────────┘    └──────────┘
```

**Exportar JSON completo:**

```json
{
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [250, 300],
      "parameters": {
        "rule": {
          "interval": [{"field": "hours", "hoursInterval": 24}]
        },
        "triggerTimes": {
          "item": [{"hour": 12, "minute": 0}]
        }
      }
    },
    {
      "name": "Get FCM Tokens",
      "type": "n8n-nodes-base.supabase",
      "position": [450, 300],
      "credentials": {"supabaseApi": {"id": "1"}},
      "parameters": {
        "operation": "getAll",
        "tableId": "fcm_tokens",
        "returnAll": true
      }
    },
    {
      "name": "Send Notifications",
      "type": "n8n-nodes-base.function",
      "position": [650, 300],
      "parameters": {
        "functionCode": "// Cole o código Firebase Admin aqui"
      }
    }
  ]
}
```

## 📱 Como Funciona no App

1. **Login do usuário** → App obtém token FCM
2. **Token salvo** → Supabase tabela `fcm_tokens`
3. **N8N Schedule** → Dispara às 12h
4. **N8N busca tokens** → De todos os usuários
5. **N8N envia push** → Via Firebase FCM
6. **App recebe** → NotificationService processa
7. **Mensagem salva** → Supabase tabela `messages`
8. **Notificação exibida** → Local notification + badge

## 🔔 Formato da Notificação

### Push Notification Payload

```json
{
  "message": {
    "token": "TOKEN_FCM_DO_DISPOSITIVO",
    "notification": {
      "title": "Lembrete do Bot",
      "body": "Olá! São 12h!"
    },
    "data": {
      "message": "Olá! São 12h, hora de verificar suas tarefas!",
      "type": "text",
      "userId": "USER_ID",
      "timestamp": "2025-11-15T12:00:00.000Z"
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "default",
        "channel_id": "chat_channel"
      }
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

### Campos Obrigatórios

- `token`: Token FCM do dispositivo
- `notification.title`: Título da notificação
- `notification.body`: Corpo da notificação
- `data.message`: Texto da mensagem (salvo no chat)
- `data.type`: Tipo da mensagem ("text", "image", "audio")

### Campos Opcionais

- `data.userId`: ID do usuário destinatário
- `data.timestamp`: Data/hora do envio
- `android.priority`: Prioridade no Android
- `apns.headers.apns-priority`: Prioridade no iOS

## 🧪 Testando

### 1. Testar Envio Manual

No N8N, crie um workflow de teste:

```javascript
// Nó Function de teste
const testToken = "TOKEN_FCM_DO_SEU_DISPOSITIVO";

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      // ... suas credenciais
    })
  });
}

const message = {
  token: testToken,
  notification: {
    title: "Teste N8N",
    body: "Esta é uma mensagem de teste!"
  },
  data: {
    message: "Mensagem de teste do N8N",
    type: "text"
  }
};

const response = await admin.messaging().send(message);

return [{json: {success: true, messageId: response}}];
```

### 2. Ver Token FCM do Dispositivo

No app, após fazer login, o token será impresso no console:

```
📱 Token FCM: fA_1B2c3D4e5...
```

Ou consulte no Supabase:
```sql
SELECT fcm_token, user_id, platform, updated_at
FROM fcm_tokens
ORDER BY updated_at DESC;
```

### 3. Logs no App

Quando receber a notificação:
```
📩 Notificação recebida (app aberto)
⚙️  Processando mensagem recebida...
💾 Salvando mensagem no banco...
✓ Mensagem salva no banco
✓ Notificação local exibida
```

## 🎨 Personalizando Mensagens

### Mensagens Dinâmicas

```javascript
// Mensagem baseada na hora do dia
const hour = new Date().getHours();

let message;
if (hour < 12) {
  message = "Bom dia! ☀️";
} else if (hour < 18) {
  message = "Boa tarde! 🌤️";
} else {
  message = "Boa noite! 🌙";
}

return [{
  json: {
    notification: {
      title: "Seu Bot",
      body: message
    },
    data: {
      message: message,
      type: "text"
    }
  }
}];
```

### Mensagens Personalizadas por Usuário

```javascript
// Buscar dados do usuário
const userData = await $('Get User Data').all();

return items.map((item, index) => {
  const user = userData[index].json;

  return {
    json: {
      fcmToken: item.json.fcm_token,
      notification: {
        title: "Olá, " + user.name + "!",
        body: "Você tem " + user.pending_tasks + " tarefas pendentes"
      },
      data: {
        message: "Você tem " + user.pending_tasks + " tarefas pendentes",
        type: "text",
        userId: user.id
      }
    }
  };
});
```

## 🔒 Segurança

### Proteja suas Credenciais

1. **Nunca commite** o Service Account Key
2. Use **variáveis de ambiente** no N8N
3. **Restrinja permissões** do Service Account no Firebase
4. **Rotacione chaves** periodicamente

### Variables de Ambiente no N8N

```javascript
const serviceAccount = {
  project_id: $env.FIREBASE_PROJECT_ID,
  private_key: $env.FIREBASE_PRIVATE_KEY,
  client_email: $env.FIREBASE_CLIENT_EMAIL
};
```

## 📊 Monitoramento

### Logs no N8N

Adicione um nó de log após o envio:

```javascript
const results = items;

console.log('=== Relatório de Envio ===');
console.log('Total enviado:', results.length);
console.log('Sucessos:', results.filter(r => r.json.success).length);
console.log('Falhas:', results.filter(r => !r.json.success).length);

// Retorna para próximo nó
return results;
```

### Tabela de Histórico (Opcional)

Crie uma tabela para logs de envio:

```sql
CREATE TABLE notification_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  fcm_token TEXT,
  message TEXT,
  sent_at TIMESTAMP DEFAULT NOW(),
  success BOOLEAN,
  error TEXT
);
```

## 📚 Recursos Adicionais

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [N8N Schedule Trigger](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

## ⚠️ Troubleshooting

### Problema: "Token not valid"
**Solução**: Token FCM pode ter expirado. Usuário precisa fazer login novamente.

### Problema: "Service account key is invalid"
**Solução**: Verifique se copiou o JSON completo do Firebase.

### Problema: "Message not received"
**Solução**:
1. Verifique se o app tem permissão de notificações
2. Teste com o app em foreground primeiro
3. Verifique logs do Firebase Console

### Problema: "Too many requests"
**Solução**: FCM tem limite de 500 mensagens/segundo. Adicione delay entre envios.

## 🎉 Pronto!

Agora você tem:
- ✅ Mensagens automáticas em horários específicos
- ✅ Notificações push funcionando
- ✅ Mensagens salvas no chat
- ✅ Sistema escalável para múltiplos usuários
