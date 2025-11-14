# 🤖 Meu Bot App

Aplicativo Flutter de chat inteligente com integração a N8N, autenticação Supabase e notificações Firebase.

## 📱 Descrição

**Meu Bot App** é um aplicativo de chat móvel completo que permite conversar com um assistente virtual inteligente. O app suporta mensagens de texto, envio de imagens (câmera e galeria) e gravação de áudio, com respostas processadas através de webhooks N8N.

## ✨ Funcionalidades

### Autenticação
- ✅ Cadastro de usuários com email e senha
- ✅ Login seguro via Supabase
- ✅ Persistência de sessão (login automático)
- ✅ Logout com confirmação
- ✅ Validação de email e senha

### Chat
- ✅ Interface moderna usando `flutter_chat_ui`
- ✅ Mensagens de texto
- ✅ Envio de fotos (câmera ou galeria)
- ✅ Gravação e envio de áudio
- ✅ Avatares personalizados para usuário e bot
- ✅ Indicador visual "digitando..." quando bot processa
- ✅ Timestamps formatados em português ("há 5 minutos", "ontem", etc)
- ✅ Estado vazio visual quando não há mensagens
- ✅ Validação de conexão com internet antes de enviar

### Notificações
- ✅ Firebase Cloud Messaging (FCM)
- ✅ Notificações push quando app está em background
- ✅ Notificações quando app está fechado
- ✅ Handler customizado para notificações

### UX/UI
- ✅ Splash screen animada
- ✅ Loading indicators em todas ações
- ✅ Snackbars de sucesso/erro/info com cores e ícones
- ✅ Diálogos de confirmação
- ✅ Design Material 3 moderno
- ✅ Tema azul/branco profissional
- ✅ Textos em português

## 🛠 Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento mobile
- **Supabase** - Autenticação e backend
- **N8N** - Processamento de mensagens via webhooks
- **Firebase Cloud Messaging** - Notificações push
- **flutter_chat_ui** - Interface de chat profissional
- **image_picker** - Captura de fotos e imagens
- **record** - Gravação de áudio
- **connectivity_plus** - Verificação de internet
- **timeago** - Formatação de timestamps

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

### 1. Flutter SDK
- Versão: 3.0.0 ou superior
- [Instruções de instalação](https://docs.flutter.dev/get-started/install)

```bash
# Verificar instalação
flutter doctor
```

### 2. Android Studio
- Android SDK instalado
- Emulador Android ou dispositivo físico

### 3. Contas necessárias
- **Supabase** - [Criar conta gratuita](https://supabase.com)
- **Firebase** - [Criar projeto](https://console.firebase.google.com)
- **N8N** - [Servidor N8N](https://n8n.io) ou instância própria

## 🚀 Configuração do Projeto

### Passo 1: Clonar o Repositório

```bash
git clone <seu-repositorio>
cd meu_bot_app
```

### Passo 2: Instalar Dependências

```bash
flutter pub get
```

### Passo 3: Configurar Supabase

1. **Criar projeto no Supabase**
   - Acesse [https://app.supabase.com](https://app.supabase.com)
   - Clique em "New Project"
   - Anote a **URL** e **anon key** do projeto

2. **Configurar credenciais no app**
   - Abra `lib/config/app_config.dart`
   - Substitua os valores placeholder:

```dart
// TODO: Substituir com suas credenciais do Supabase
static const String supabaseUrl = 'https://SEU-PROJETO.supabase.co';
static const String supabaseAnonKey = 'SUA-CHAVE-ANON-AQUI';
```

3. **Configurar autenticação**
   - No painel Supabase, vá em **Authentication** → **Providers**
   - Habilite **Email** como provider
   - Configure URLs de redirecionamento (opcional)

### Passo 4: Configurar Firebase

1. **Criar projeto no Firebase Console**
   - Acesse [https://console.firebase.google.com](https://console.firebase.google.com)
   - Clique em "Adicionar projeto"
   - Siga o assistente de criação

2. **Adicionar app Android ao projeto**
   - No projeto Firebase, clique em "Adicionar app" → Android
   - **Package name**: `com.example.meu_bot_app` (deve ser o mesmo do `android/app/build.gradle`)
   - Baixe o arquivo `google-services.json`

3. **Configurar google-services.json**
   - Copie o arquivo baixado para:
   ```
   meu_bot_app/android/app/google-services.json
   ```

4. **Habilitar Firebase Cloud Messaging**
   - No Firebase Console, vá em **Build** → **Cloud Messaging**
   - Anote o **Server Key** (opcional, para backend)

### Passo 5: Configurar N8N

1. **Criar workflow no N8N**
   - Crie um workflow que recebe webhooks
   - Adicione um nó **Webhook** com método POST
   - Configure a lógica de resposta do bot

2. **Obter URL do webhook**
   - No nó Webhook, copie a **Production URL**
   - Exemplo: `https://seu-n8n.com/webhook/bot-chat`

3. **Configurar URL no app**
   - Abra `lib/config/app_config.dart`
   - Substitua o valor placeholder:

```dart
// TODO: Substituir com URL do seu webhook N8N
static const String n8nWebhookUrl = 'https://seu-n8n.com/webhook/bot-chat';
```

4. **Formato esperado do webhook**

   **Request (do app para N8N):**
   ```json
   {
     "userId": "user-id",
     "messageType": "text|image|audio",
     "content": "texto da mensagem ou base64",
     "timestamp": "2024-01-15T10:30:00.000Z"
   }
   ```

   **Response (do N8N para app):**
   ```json
   {
     "success": true,
     "response": {
       "type": "text|image|audio",
       "text": "Resposta do bot",
       "data": "URL ou base64 (para image/audio)"
     }
   }
   ```

### Passo 6: Verificar Configuração

Execute o comando para verificar se tudo está OK:

```bash
flutter doctor
```

Todos os itens devem estar com ✓ (checkmark).

## ▶️ Executando o App

### Modo Debug (Desenvolvimento)

```bash
# Listar dispositivos disponíveis
flutter devices

# Rodar no emulador/dispositivo
flutter run

# Rodar com hot reload
# Pressione 'r' para hot reload
# Pressione 'R' para hot restart
```

### Modo Release (Teste de performance)

```bash
flutter run --release
```

## 📦 Gerando Build de Produção

### APK (Android Package)

```bash
# Gerar APK para todas as arquiteturas
flutter build apk

# Gerar APK dividido por arquitetura (menor tamanho)
flutter build apk --split-per-abi

# O APK estará em: build/app/outputs/flutter-apk/app-release.apk
```

### AAB (Android App Bundle) - Recomendado para Google Play

```bash
# Gerar AAB para Google Play
flutter build appbundle

# O AAB estará em: build/app/outputs/bundle/release/app-release.aab
```

### Assinar o App (Obrigatório para produção)

1. **Criar keystore**

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Criar arquivo key.properties**

Crie o arquivo `android/key.properties`:

```properties
storePassword=<senha-do-keystore>
keyPassword=<senha-da-chave>
keyAlias=upload
storeFile=<caminho-para-upload-keystore.jks>
```

3. **Configurar build.gradle**

O arquivo `android/app/build.gradle` já está configurado para ler o `key.properties`.

4. **Gerar build assinado**

```bash
flutter build appbundle --release
```

## 🗂 Estrutura do Projeto

```
meu_bot_app/
├── lib/
│   ├── config/
│   │   └── app_config.dart          # Configurações centralizadas
│   ├── models/
│   │   └── message_model.dart       # Modelo de mensagem
│   ├── screens/
│   │   ├── splash_screen.dart       # Tela de splash
│   │   ├── login_screen.dart        # Tela de login
│   │   ├── register_screen.dart     # Tela de cadastro
│   │   └── chat_screen.dart         # Tela principal de chat
│   ├── services/
│   │   ├── supabase_service.dart    # Autenticação Supabase
│   │   ├── n8n_service.dart         # Comunicação com N8N
│   │   ├── notification_service.dart # Firebase Cloud Messaging
│   │   ├── media_service.dart       # Captura de imagens
│   │   ├── audio_service.dart       # Gravação de áudio
│   │   └── connectivity_service.dart # Verificação de internet
│   └── main.dart                    # Ponto de entrada
├── android/
│   └── app/
│       ├── google-services.json     # Configuração Firebase (você cria)
│       └── build.gradle
├── pubspec.yaml                     # Dependências
└── README.md                        # Este arquivo
```

## 🔧 Configurações Importantes

### Permissões Android (android/app/src/main/AndroidManifest.xml)

O app já solicita as seguintes permissões:

- `INTERNET` - Comunicação com backend
- `CAMERA` - Tirar fotos
- `RECORD_AUDIO` - Gravar áudio
- `READ_EXTERNAL_STORAGE` - Acessar galeria (Android < 13)
- `READ_MEDIA_IMAGES` - Acessar galeria (Android 13+)
- `WRITE_EXTERNAL_STORAGE` - Salvar arquivos

### Package Name

O package name padrão é `com.example.meu_bot_app`. Para mudar:

1. Edite `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       applicationId "com.seudominio.seuapp"
   }
   ```

2. Reconfigure Firebase com o novo package name

## 🐛 Troubleshooting

### Erro: "Supabase credentials not configured"

**Solução**: Verifique se você configurou as credenciais em `lib/config/app_config.dart`

### Erro: "google-services.json not found"

**Solução**: Baixe o arquivo do Firebase Console e coloque em `android/app/`

### Erro: "Failed to connect to N8N"

**Solução**:
- Verifique se a URL do webhook está correta em `lib/config/app_config.dart`
- Teste a URL em ferramentas como Postman
- Certifique-se que o servidor N8N está acessível

### App não recebe notificações

**Solução**:
- Verifique se o `google-services.json` está configurado
- Teste notificações via Firebase Console → Cloud Messaging → Send test message
- Verifique permissões de notificação no dispositivo

### Erro ao gravar áudio

**Solução**:
- Verifique permissões de microfone no dispositivo
- Em emulador, verifique se o áudio está habilitado

### Imagens muito grandes

**Solução**: O app já valida tamanho (max 10MB para imagens, 5MB para áudio). Se necessário, ajuste em:
- `lib/services/media_service.dart` (linha ~309)
- `lib/services/audio_service.dart` (linha ~389)

## 📚 Documentação Adicional

- **Supabase Auth**: Veja `CONFIGURACAO_SUPABASE.md`
- **Firebase FCM**: Veja `CONFIGURACAO_FIREBASE.md`
- **N8N Integration**: Veja `CONFIGURACAO_N8N.md`

## 🔒 Segurança

⚠️ **IMPORTANTE**: Nunca commite credenciais reais no Git!

- Use `.gitignore` para excluir arquivos sensíveis
- Para produção, use variáveis de ambiente ou serviços como:
  - [Flutter dotenv](https://pub.dev/packages/flutter_dotenv)
  - [flutter_config](https://pub.dev/packages/flutter_config)

## 📄 Licença

Este projeto é de uso educacional/pessoal.

## 👨‍💻 Suporte

Para dúvidas ou problemas:
1. Verifique a seção de Troubleshooting acima
2. Consulte os arquivos de configuração específicos (CONFIGURACAO_*.md)
3. Abra uma issue no repositório

---

**Desenvolvido com ❤️ usando Flutter**
