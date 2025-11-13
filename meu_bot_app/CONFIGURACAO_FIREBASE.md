# Configuração do Firebase Cloud Messaging

Este guia explica como configurar Firebase Cloud Messaging (FCM) para notificações push no app.

## Passo 1: Criar Projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Clique em **"Adicionar projeto"** (ou selecione um existente)
3. Nomeie seu projeto (ex: "Meu Bot App")
4. Escolha se deseja ativar Google Analytics (opcional)
5. Clique em **"Criar projeto"**

## Passo 2: Adicionar App Android ao Projeto

### 2.1. Registrar o App

1. No Firebase Console, clique no ícone do **Android**
2. Preencha os campos:
   - **Nome do pacote Android**: `com.example.meu_bot_app`
     - Para verificar: abra `android/app/build.gradle.kts` e veja o `applicationId`
   - **Apelido do app**: "Meu Bot App" (opcional)
   - **SHA-1**: (opcional, mas recomendado para produção)
3. Clique em **"Registrar app"**

### 2.2. Baixar google-services.json

1. Clique em **"Baixar google-services.json"**
2. Salve o arquivo

### 2.3. Adicionar google-services.json ao Projeto

**Coloque o arquivo em:**
```
meu_bot_app/android/app/google-services.json
```

**Estrutura esperada:**
```
meu_bot_app/
├── android/
│   ├── app/
│   │   ├── google-services.json  ← AQUI
│   │   ├── build.gradle.kts
│   │   └── src/
│   └── build.gradle.kts
├── lib/
└── pubspec.yaml
```

### 2.4. Configurar build.gradle

**Abra:** `android/build.gradle.kts`

**Adicione na seção `dependencies`:**
```kotlin
dependencies {
    classpath("com.android.tools.build:gradle:8.1.0")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    classpath("com.google.gms:google-services:4.4.0")  // ← ADICIONE ESTA LINHA
}
```

**Abra:** `android/app/build.gradle.kts`

**Adicione no final do arquivo:**
```kotlin
apply(plugin = "com.google.gms.google-services")  // ← ADICIONE ESTA LINHA
```

## Passo 3: Testar a Configuração

### 3.1. Executar o App

```bash
cd meu_bot_app
flutter run
```

### 3.2. Verificar Logs

Procure no console:
```
✓ Firebase inicializado
✓ Notificações inicializadas
📱 Token FCM: ey...
```

Se aparecer erro:
```
✗ Erro ao inicializar Firebase
```
Verifique se o `google-services.json` está no lugar correto.

### 3.3. Obter o Token FCM

O token é impresso no console quando o app inicia. Exemplo:
```
📱 Token FCM: dXyz123...abc
```

**Salve este token!** Você vai precisar dele para enviar notificações de teste.

## Passo 4: Testar Notificações

### 4.1. Via Firebase Console

1. No Firebase Console, vá em **Cloud Messaging**
2. Clique em **"Enviar sua primeira mensagem"**
3. Preencha:
   - **Título**: "Teste"
   - **Texto**: "Notificação de teste"
4. Clique em **"Avançar"**
5. Em **"Destino"**, selecione **"Dispositivo único"**
6. Cole o **Token FCM** do seu dispositivo
7. Clique em **"Testar"**
8. Clique em **"Publicar"**

**Você deve receber a notificação no app!**

### 4.2. Via cURL (API REST)

Primeiro, obtenha a **Server Key**:
1. Firebase Console → **Configurações do projeto** (⚙️)
2. Aba **"Cloud Messaging"**
3. Copie a **"Chave do servidor"** (Server Key)

**Envie notificação:**
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=SUA_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "TOKEN_FCM_DO_DISPOSITIVO",
    "notification": {
      "title": "Nova mensagem do bot",
      "body": "Você recebeu uma resposta!"
    },
    "data": {
      "messageId": "123",
      "userId": "user123"
    }
  }'
```

## Passo 5: Integrar com N8N

### 5.1. Salvar Token FCM no Backend

Quando o usuário faz login, salve o token FCM:

```dart
// Após login bem-sucedido
final token = await NotificationService.getDeviceToken();
if (token != null) {
  await NotificationService.saveTokenToBackend(
    token,
    userId: currentUser.id,
  );
}
```

### 5.2. Criar Workflow N8N para Enviar Notificações

**Workflow básico:**
```
Trigger → Function (formatar) → HTTP Request (FCM API)
```

**Nó HTTP Request:**
- **Method**: POST
- **URL**: `https://fcm.googleapis.com/fcm/send`
- **Headers**:
  - `Authorization`: `key=SUA_SERVER_KEY`
  - `Content-Type`: `application/json`
- **Body**:
```json
{
  "to": "{{$json.fcmToken}}",
  "notification": {
    "title": "Nova mensagem do bot",
    "body": "{{$json.botResponse}}"
  },
  "data": {
    "messageId": "{{$json.messageId}}",
    "userId": "{{$json.userId}}"
  }
}
```

### 5.3. Fluxo Completo

```
1. Usuário envia mensagem para o bot (N8N webhook)
2. Bot processa e gera resposta
3. N8N salva resposta no banco
4. N8N busca token FCM do usuário
5. N8N envia notificação via FCM API
6. Usuário recebe notificação
7. Usuário clica → app abre no chat
```

## Passo 6: Implementar saveTokenToBackend()

**Crie endpoint no N8N:**
```
POST https://seu-n8n.com/webhook/save-fcm-token
```

**Body esperado:**
```json
{
  "userId": "user-id-supabase",
  "fcmToken": "token-fcm",
  "platform": "android",
  "timestamp": "2025-01-13T10:30:00Z"
}
```

**Workflow N8N:**
```
Webhook → Supabase (Insert/Update)
```

**Tabela no Supabase:**
```sql
CREATE TABLE user_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  fcm_token TEXT NOT NULL,
  platform TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índice para buscar rapidamente
CREATE INDEX idx_user_tokens_user_id ON user_tokens(user_id);
```

**No código, implemente:**
```dart
// Em lib/services/notification_service.dart
static Future<void> saveTokenToBackend(
  String token, {
  required String userId,
}) async {
  await dio.post(
    'https://seu-n8n.com/webhook/save-fcm-token',
    data: {
      'userId': userId,
      'fcmToken': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

## Passo 7: Automatizar no Login

**Em LoginScreen, após login bem-sucedido:**
```dart
// Após signIn()
try {
  final token = await NotificationService.getDeviceToken();
  if (token != null) {
    final currentUser = SupabaseService.getCurrentUser();
    if (currentUser != null) {
      await NotificationService.saveTokenToBackend(
        token,
        userId: currentUser.id,
      );
      print('✓ Token FCM salvo no backend');
    }
  }
} catch (e) {
  print('Erro ao salvar token: $e');
}
```

## Passo 8: Remover Token no Logout

**Em ChatScreen, no método de logout:**
```dart
Future<void> _handleLogout() async {
  try {
    final currentUser = SupabaseService.getCurrentUser();
    if (currentUser != null) {
      await NotificationService.removeTokenFromBackend(
        userId: currentUser.id,
      );
    }
    await NotificationService.deleteToken();
    await SupabaseService.signOut();
  } catch (e) {
    print('Erro no logout: $e');
  }
}
```

## Estados da Notificação

### Foreground (App Aberto)
- Notificação é mostrada como banner/toast
- Usuário pode tocar para ver detalhes
- App já está aberto no chat

### Background (App Minimizado)
- Notificação aparece na barra de notificações
- Usuário clica → app abre
- Callback `onNotificationOpenedApp` é chamado
- Navega para o chat automaticamente

### Terminated (App Fechado)
- Notificação aparece na barra de notificações
- Usuário clica → app inicia
- Mensagem é processada em `getInitialMessage()`
- Navega para o chat após inicialização

## Formato da Notificação

### Notificação Simples
```json
{
  "to": "token-fcm",
  "notification": {
    "title": "Nova mensagem",
    "body": "Olá! Como posso ajudar?"
  }
}
```

### Notificação com Dados Extras
```json
{
  "to": "token-fcm",
  "notification": {
    "title": "Nova mensagem do bot",
    "body": "Você recebeu uma resposta!"
  },
  "data": {
    "messageId": "msg_123",
    "userId": "user_456",
    "chatId": "chat_789",
    "action": "open_chat"
  }
}
```

### Apenas Dados (Sem Notificação Visual)
```json
{
  "to": "token-fcm",
  "data": {
    "messageId": "msg_123",
    "silent": "true"
  }
}
```

## Permissões Android

**Já configurado no pubspec.yaml**, mas verifique:

`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Troubleshooting

### "Erro ao inicializar Firebase"
- Verifique se `google-services.json` está em `android/app/`
- Verifique se adicionou `google-services` plugin no gradle
- Execute `flutter clean && flutter pub get`

### "Token FCM null"
- Verifique permissões de notificação
- Aguarde alguns segundos após inicialização
- Teste em dispositivo real (emulador pode falhar)

### "Notificação não recebida"
- Verifique se o token está correto
- Teste com Firebase Console primeiro
- Verifique se Server Key está correta
- Veja logs do N8N

### "App não abre ao clicar na notificação"
- Verifique se implementou `onNotificationOpenedApp`
- Verifique se o callback está navegando corretamente
- Teste em dispositivo real

## Recursos Úteis

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Fire Docs](https://firebase.flutter.dev/)
- [FCM HTTP API Reference](https://firebase.google.com/docs/cloud-messaging/http-server-ref)
- [Teste de Notificações](https://firebase.google.com/docs/cloud-messaging/flutter/first-message)

## Checklist de Implementação

- [ ] Criar projeto no Firebase
- [ ] Adicionar app Android
- [ ] Baixar `google-services.json`
- [ ] Colocar arquivo em `android/app/`
- [ ] Configurar `build.gradle.kts`
- [ ] Testar app e obter token
- [ ] Enviar notificação de teste
- [ ] Criar endpoint N8N para salvar token
- [ ] Criar tabela no Supabase
- [ ] Implementar `saveTokenToBackend()`
- [ ] Adicionar ao login
- [ ] Adicionar ao logout
- [ ] Testar notificação com app:
  - [ ] Aberto (foreground)
  - [ ] Minimizado (background)
  - [ ] Fechado (terminated)
- [ ] Integrar com workflow N8N
- [ ] Enviar notificação quando bot responde

## Próximos Passos

1. Configure Firebase seguindo este guia
2. Teste notificações manualmente
3. Implemente `saveTokenToBackend()` com seu N8N
4. Crie workflow no N8N para enviar notificações
5. Teste o fluxo completo:
   - Envie mensagem
   - Bot responde
   - Receba notificação
   - Clique na notificação
   - App abre no chat
