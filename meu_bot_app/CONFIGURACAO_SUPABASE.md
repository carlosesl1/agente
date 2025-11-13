# Configuração do Supabase

Este guia explica como configurar as credenciais do Supabase no projeto.

## Passo 1: Obter as Credenciais do Supabase

1. Acesse [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Faça login ou crie uma conta
3. Clique em **"New Project"** ou selecione um projeto existente
4. No menu lateral, vá em **Settings** → **API**
5. Você verá duas informações importantes:
   - **Project URL** (algo como: `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon/public key** (uma string longa começando com `eyJ...`)

## Passo 2: Configurar no Código

### Abra o arquivo de serviço:
```
lib/services/supabase_service.dart
```

### Localize as seguintes linhas (no topo da classe):
```dart
// ========== CONFIGURE SUAS CREDENCIAIS AQUI ==========
// TODO: Substituir com suas credenciais reais do Supabase
static const String SUPABASE_URL = 'https://seu-projeto.supabase.co';
static const String SUPABASE_ANON_KEY = 'sua-chave-anonima-aqui';
// =====================================================
```

### Substitua pelos valores reais:
```dart
// ========== CONFIGURE SUAS CREDENCIAIS AQUI ==========
static const String SUPABASE_URL = 'https://xxxxxxxxxxxxx.supabase.co';
static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
// =====================================================
```

## Passo 3: Configurar a Autenticação no Supabase

Para que o login funcione, você precisa habilitar a autenticação por email:

1. No dashboard do Supabase, vá em **Authentication** → **Providers**
2. Certifique-se que **Email** está habilitado
3. Configure as opções conforme necessário:
   - **Enable email confirmations**: Se você quer que usuários confirmem email (recomendado para produção)
   - **Enable email signup**: Permitir novos cadastros

## Passo 4: Testar a Configuração

Depois de configurar as credenciais:

1. Execute o app:
   ```bash
   flutter run
   ```

2. Verifique o console para a mensagem:
   ```
   ✓ Supabase inicializado com sucesso
   ```

3. Se aparecer erro:
   ```
   ✗ Erro ao inicializar Supabase: ...
   ```
   Verifique se as credenciais estão corretas.

## Métodos Disponíveis

O `SupabaseService` fornece os seguintes métodos:

### Autenticação
- `signUp(email, password)` - Cadastrar novo usuário
- `signIn(email, password)` - Fazer login
- `signOut()` - Fazer logout
- `getCurrentUser()` - Obter usuário atual
- `isAuthenticated()` - Verificar se está logado
- `resetPassword(email)` - Recuperar senha
- `updateUser({email, password})` - Atualizar dados do usuário

### Exemplos de Uso

```dart
// Cadastrar usuário
try {
  await SupabaseService.signUp('email@exemplo.com', 'senha123');
  print('Usuário cadastrado com sucesso!');
} catch (e) {
  print('Erro: $e');
}

// Fazer login
try {
  await SupabaseService.signIn('email@exemplo.com', 'senha123');
  print('Login realizado!');
} catch (e) {
  print('Erro: $e');
}

// Verificar se está logado
if (SupabaseService.isAuthenticated()) {
  final user = SupabaseService.getCurrentUser();
  print('Usuário logado: ${user?.email}');
}

// Logout
await SupabaseService.signOut();
```

## Segurança

⚠️ **IMPORTANTE**:
- A `SUPABASE_ANON_KEY` pode ser exposta no código do app (ela é pública)
- NUNCA coloque a **service_role key** no código do app (apenas no backend)
- Configure Row Level Security (RLS) nas tabelas do Supabase para proteger dados

## Próximos Passos

Depois de configurar o Supabase:
1. Crie as telas de login e cadastro
2. Implemente a tela de chat
3. Configure as políticas de segurança (RLS) no Supabase
4. Integre com o backend N8N

## Recursos Úteis

- [Documentação Supabase](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
