# 📱 Resumo: Mensagens Programadas do N8N

## ✅ O que foi implementado

### 1. **Tela de Login Corrigida**
   - Cores adaptáveis ao modo claro/escuro
   - Labels e hints visíveis em ambos os modos
   - Design consistente com o restante do app

### 2. **Recebimento de Mensagens Automáticas**
   - App pode receber mensagens do N8N via push notification
   - Mensagens são salvas automaticamente no chat
   - Notificações funcionam mesmo com app fechado

## 🎯 Como Funciona

### Fluxo Completo:

```
1. Usuário faz login no app
   └─> Token FCM é gerado e salvo no Supabase

2. N8N tem um trigger programado (ex: meio dia)
   └─> Busca todos os tokens FCM dos usuários
   └─> Envia notificação push via Firebase

3. App recebe a notificação
   ├─> Salva mensagem no banco de dados (Supabase)
   ├─> Mostra notificação na barra de status
   └─> Atualiza o chat (se estiver aberto)

4. Usuário vê a mensagem
   └─> No chat + notificação push
```

## 📋 Próximos Passos

### **Passo 1: Criar Tabela no Supabase**

Execute o SQL em `supabase_fcm_tokens_schema.sql`:

1. Abra o Supabase Dashboard
2. Vá em **SQL Editor**
3. Cole o conteúdo do arquivo `supabase_fcm_tokens_schema.sql`
4. Execute

Isso cria a tabela `fcm_tokens` que armazena os tokens de cada usuário.

### **Passo 2: Configurar Firebase**

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. **Configurações do Projeto** → **Contas de Serviço**
4. Clique em **Gerar nova chave privada**
5. Salve o arquivo JSON

### **Passo 3: Configurar N8N**

Siga o guia completo em `CONFIGURACAO_MENSAGENS_N8N.md`:

**Workflow básico:**

1. **Schedule Trigger** → Dispara às 12h (ou horário desejado)
2. **Supabase** → Busca tokens FCM de todos os usuários
3. **Function** → Envia notificação via Firebase Admin SDK

**Código simplificado do Nó Function:**

```javascript
const admin = require('firebase-admin');

// Inicializa Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      "project_id": "seu-projeto-id",
      "private_key": "-----BEGIN PRIVATE KEY-----\n...\n",
      "client_email": "firebase-adminsdk-...@..."
    })
  });
}

// Envia para cada usuário
for (const item of items) {
  await admin.messaging().send({
    token: item.json.fcm_token,
    notification: {
      title: "Lembrete do Bot",
      body: "Olá! São 12h! 🤖"
    },
    data: {
      message: "Olá! São 12h, hora de verificar suas tarefas!",
      type: "text",
      userId: item.json.user_id
    }
  });
}
```

## 🔔 Formato da Mensagem

O N8N deve enviar notificações no seguinte formato:

```json
{
  "notification": {
    "title": "Título da notificação",
    "body": "Corpo da notificação"
  },
  "data": {
    "message": "Texto que será salvo no chat",
    "type": "text",
    "userId": "ID_DO_USUARIO"
  }
}
```

**Campos obrigatórios:**
- `notification.title`: Título da notificação
- `notification.body`: Corpo da notificação
- `data.message`: Texto da mensagem (salvo no chat)
- `data.type`: Tipo ("text", "image", "audio")
- `data.userId`: ID do usuário destinatário

## 🧪 Testando

### 1. Ver o Token FCM do App

Após fazer login, o token será impresso no console do app:

```
📱 Token FCM: fA_1B2c3D4e5...
✓ Token FCM salvo no Supabase
```

### 2. Consultar Tokens no Supabase

```sql
SELECT user_id, fcm_token, platform, updated_at
FROM fcm_tokens
ORDER BY updated_at DESC;
```

### 3. Testar Envio Manual

No N8N, crie um workflow de teste com o token do seu dispositivo:

```javascript
const testToken = "TOKEN_DO_SEU_DISPOSITIVO_AQUI";

await admin.messaging().send({
  token: testToken,
  notification: {
    title: "Teste",
    body: "Mensagem de teste!"
  },
  data: {
    message: "Esta é uma mensagem de teste do N8N",
    type: "text"
  }
});
```

## 📱 Comportamento no App

### Quando a notificação chega:

**App Aberto (Foreground):**
- ✅ Mensagem salva no banco
- ✅ Notificação mostrada
- ✅ Chat atualizado automaticamente

**App Minimizado (Background):**
- ✅ Mensagem salva no banco
- ✅ Notificação na barra de status
- ✅ Ao abrir o app, mensagem está no chat

**App Fechado (Terminated):**
- ✅ Mensagem salva no banco
- ✅ Notificação na barra de status
- ✅ Ao abrir o app, mensagem está no chat

## 🎨 Exemplos de Uso

### Lembrete Diário

```javascript
// N8N - Schedule Trigger: Diário às 9h
const message = {
  title: "Bom dia! ☀️",
  body: "Seu resumo do dia está pronto!",
  data: {
    message: "Bom dia! Você tem 3 tarefas para hoje.",
    type: "text"
  }
};
```

### Notificação Personalizada

```javascript
// Buscar nome do usuário do Supabase
const userName = item.json.user_name;

const message = {
  title: `Olá, ${userName}!`,
  body: "Temos novidades para você!",
  data: {
    message: `Olá ${userName}! Confira as novidades de hoje.`,
    type: "text"
  }
};
```

### Mensagem com Horário Dinâmico

```javascript
const hour = new Date().getHours();

let greeting;
if (hour < 12) greeting = "Bom dia! ☀️";
else if (hour < 18) greeting = "Boa tarde! 🌤️";
else greeting = "Boa noite! 🌙";

const message = {
  title: "Seu Bot",
  body: greeting,
  data: {
    message: `${greeting} Como posso ajudá-lo hoje?`,
    type: "text"
  }
};
```

## 📚 Documentação Completa

- **`CONFIGURACAO_MENSAGENS_N8N.md`**: Guia passo a passo completo
- **`supabase_fcm_tokens_schema.sql`**: Schema da tabela de tokens
- **`FORMATO_ENVIO_AUDIO.md`**: Como enviar áudios (já implementado)

## ⚡ Quick Start

1. Execute o SQL no Supabase (`supabase_fcm_tokens_schema.sql`)
2. Baixe o Service Account Key do Firebase
3. Crie workflow no N8N com Schedule Trigger
4. Configure o nó Function com Firebase Admin SDK
5. Teste com seu token FCM
6. Pronto! 🎉

## 🆘 Precisa de Ajuda?

Consulte a documentação completa em `CONFIGURACAO_MENSAGENS_N8N.md` que contém:
- Troubleshooting detalhado
- Exemplos de workflows
- Códigos prontos para copiar
- Configurações de autenticação
- Monitoramento e logs

## 🎉 Resultado Final

Agora você tem:
- ✅ Mensagens automáticas em horários programados
- ✅ Notificações push funcionando
- ✅ Mensagens salvas no chat
- ✅ Tela de login com cores corrigidas
- ✅ Sistema escalável para múltiplos usuários
