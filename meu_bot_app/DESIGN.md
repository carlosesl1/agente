# 🎨 Design do App - Meu Bot

## 📱 Visão Geral

O app possui um design moderno e profissional com suporte para **modo escuro** e **modo claro**, oferecendo uma experiência visual agradável em qualquer condição de iluminação.

---

## 🌓 Sistema de Temas

### **Modo Claro**
- **AppBar**: Azul vibrante (#2196F3)
- **Background**: Cinza claro (#F5F5F5)
- **Mensagens do Usuário**: Azul (#2196F3) com texto branco
- **Mensagens do Bot**: Azul claro (#E3F2FD) com texto escuro
- **Input Field**: Cinza claro (#F0F0F0)

### **Modo Escuro**
- **AppBar**: Superfície escura (#1E1E1E)
- **Background**: Preto profundo (#121212)
- **Mensagens do Usuário**: Azul (#2196F3) com texto branco
- **Mensagens do Bot**: Cinza escuro (#2C2C2C) com texto claro
- **Input Field**: Cinza escuro (#2C2C2C)

---

## 🎯 Características de Design

### **1. Temas Personalizados**
- ✅ 2 temas completos (claro e escuro)
- ✅ Cores consistentes em todo o app
- ✅ Material Design 3
- ✅ Transições suaves entre temas

### **2. Persistência de Tema**
- ✅ Preferência salva em SharedPreferences
- ✅ Tema restaurado ao abrir o app
- ✅ 3 opções: Claro, Escuro, Sistema

### **3. Interface do Chat**
- ✅ Bordas arredondadas (20px)
- ✅ Cores diferenciadas para usuário e bot
- ✅ Input field com design moderno
- ✅ Avatar do bot com ícone
- ✅ Skeleton screens animados

### **4. AppBar Refinado**
- ✅ Ícone do bot com destaque
- ✅ Toggle de tema acessível
- ✅ Botão de logout
- ✅ Indicador de loading discreto

---

## 🎨 Paleta de Cores

### **Cores Principais**

| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primary | #2196F3 | #2196F3 |
| Accent | #03DAC6 | #03DAC6 |
| Background | #F5F5F5 | #121212 |
| Surface | #FFFFFF | #1E1E1E |
| Error | #B00020 | #CF6679 |

### **Cores do Chat**

| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Mensagem Usuário | #2196F3 | #2196F3 |
| Texto Usuário | #FFFFFF | #FFFFFF |
| Mensagem Bot | #E3F2FD | #2C2C2C |
| Texto Bot | #1A1A1A | #E0E0E0 |
| Input Background | #F0F0F0 | #2C2C2C |
| Input Text | #1A1A1A | #E0E0E0 |

---

## 🔧 Implementação Técnica

### **Arquivos Principais**

1. **`lib/theme/app_themes.dart`**
   - Define temas claro e escuro
   - Paleta de cores completa
   - Configurações de Material Design 3

2. **`lib/theme/theme_provider.dart`**
   - Gerencia estado do tema
   - Persistência com SharedPreferences
   - Métodos para alternar temas

3. **`lib/main.dart`**
   - Integra ThemeProvider com Provider
   - Aplica temas ao MaterialApp
   - Inicializa preferências

4. **`lib/screens/chat_screen.dart`**
   - Toggle de tema no AppBar
   - Cores dinâmicas baseadas no tema
   - Design refinado do chat

---

## 📖 Como Usar

### **Alternar Tema**
```dart
// Via ThemeProvider
final themeProvider = Provider.of<ThemeProvider>(context);

// Toggle entre claro e escuro
await themeProvider.toggleTheme();

// Definir tema específico
await themeProvider.setLightMode();
await themeProvider.setDarkMode();
await themeProvider.setSystemMode();
```

### **Verificar Tema Atual**
```dart
final themeProvider = Provider.of<ThemeProvider>(context);

// Verifica se está em modo escuro
bool isDark = themeProvider.isDarkMode;

// Obtém o ThemeMode atual
ThemeMode mode = themeProvider.themeMode;

// Nome amigável do tema
String name = themeProvider.themeName; // "Claro", "Escuro", "Sistema"

// Ícone correspondente
IconData icon = themeProvider.themeIcon; // Icons.light_mode ou Icons.dark_mode
```

---

## 🎨 Customizações

### **Alterando Cores**

Para customizar as cores, edite `lib/theme/app_themes.dart`:

```dart
// Exemplo: Mudar cor primária
static const Color lightPrimary = Color(0xFF6200EE); // Roxo

// Exemplo: Mudar cor das mensagens do usuário
static const Color lightUserBubble = Color(0xFF00BCD4); // Ciano
```

### **Adicionando Novo Tema**

1. Adicione as cores em `AppThemes`:
```dart
static const Color customPrimary = Color(0xFFFF5722);
static const Color customBackground = Color(0xFFFFF3E0);
```

2. Crie o tema:
```dart
static ThemeData get customTheme {
  return ThemeData(
    useMaterial3: true,
    primaryColor: customPrimary,
    scaffoldBackgroundColor: customBackground,
    // ... outras configurações
  );
}
```

3. Adicione ao ThemeProvider se necessário.

---

## 📱 Screenshots

### Modo Claro
```
┌────────────────────────────────┐
│  🤖 Meu Bot        ☀️ 🚪      │ ← AppBar azul
├────────────────────────────────┤
│                                │
│  ┌──────────────────────┐      │
│  │ Olá! Como posso...   │  🤖  │ ← Mensagem bot (azul claro)
│  └──────────────────────┘      │
│                                │
│        ┌──────────────────┐    │
│    👤  │ Preciso de ajuda │    │ ← Mensagem usuário (azul)
│        └──────────────────┘    │
│                                │
│  ┌─────────────────────────┐   │
│  │ Digite uma mensagem... 📎│   │ ← Input field
│  └─────────────────────────┘   │
└────────────────────────────────┘
```

### Modo Escuro
```
┌────────────────────────────────┐
│  🤖 Meu Bot        🌙 🚪      │ ← AppBar escuro
├────────────────────────────────┤
│                                │ ← Background preto
│  ┌──────────────────────┐      │
│  │ Olá! Como posso...   │  🤖  │ ← Mensagem bot (cinza escuro)
│  └──────────────────────┘      │
│                                │
│        ┌──────────────────┐    │
│    👤  │ Preciso de ajuda │    │ ← Mensagem usuário (azul)
│        └──────────────────┘    │
│                                │
│  ┌─────────────────────────┐   │
│  │ Digite uma mensagem... 📎│   │ ← Input field escuro
│  └─────────────────────────┘   │
└────────────────────────────────┘
```

---

## ✨ Melhorias Futuras

Sugestões para evoluir o design:

- [ ] Temas adicionais (Teal, Purple, etc)
- [ ] Customização de cores pelo usuário
- [ ] Animações de transição entre temas
- [ ] Gradientes nas mensagens
- [ ] Avatares personalizados
- [ ] Temas premium
- [ ] Modo AMOLED (preto puro para economia de bateria)

---

## 📚 Referências

- [Material Design 3](https://m3.material.io/)
- [Flutter ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Provider Package](https://pub.dev/packages/provider)
- [Dark Mode Best Practices](https://material.io/design/color/dark-theme.html)

---

**Última atualização**: 2025-01-15
**Versão**: 1.0.0
