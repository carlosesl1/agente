# Design System - iOS Style

Este design system segue fielmente os **iOS Human Interface Guidelines 2024** da Apple.

## 🎨 Princípios

1. **Clareza** - Conteúdo é prioridade, UI é discreta
2. **Deferência** - UI não compete com o conteúdo
3. **Profundidade** - Camadas visuais criam hierarquia

## 📐 Cores

### System Colors (iOS)
- `systemBlue` - #007AFF (light) / #0A84FF (dark)
- `systemRed` - #FF3B30
- `systemGreen` - #34C759
- `systemOrange` - #FF9500
- `systemPurple` - #AF52DE
- `systemIndigo` - #5856D6
- `systemTeal` - #5AC8FA

### Backgrounds
**Light Mode:**
- Primary: #FFFFFF
- Secondary: #F2F2F7 (grouped backgrounds)
- Tertiary: #FFFFFF

**Dark Mode:**
- Primary: #000000 (true black)
- Secondary: #1C1C1E
- Tertiary: #2C2C2E

### Labels (Text Colors)
**Light Mode:**
- Primary: #000000 (100%)
- Secondary: #3C3C43 (60%)
- Tertiary: #3C3C43 (30%)
- Quaternary: #3C3C43 (18%)

**Dark Mode:**
- Primary: #FFFFFF (100%)
- Secondary: #EBEBF5 (60%)
- Tertiary: #EBEBF5 (30%)
- Quaternary: #EBEBF5 (16%)

### Fills (Para controles/inputs)
Semi-transparentes baseados em cinza, variando de 12-36% de opacidade.

## 🔤 Tipografia

Baseada na fonte **SF Pro** com optical sizes corretas:

| Estilo | Tamanho | Peso | Uso |
|--------|---------|------|-----|
| Large Title | 34pt | Bold (700) | Títulos principais de navegação |
| Title 1 | 28pt | Bold (700) | Títulos de seção grandes |
| Title 2 | 22pt | Bold (700) | Subtítulos de seção |
| Title 3 | 20pt | Semibold (600) | Cabeçalhos menores |
| Headline | 17pt | Semibold (600) | Títulos em listas, botões |
| Body | 17pt | Regular (400) | Texto padrão |
| Callout | 16pt | Regular (400) | Texto secundário |
| Subheadline | 15pt | Regular (400) | Legendas |
| Footnote | 13pt | Regular (400) | Notas de rodapé |
| Caption 1 | 12pt | Regular (400) | Metadados |
| Caption 2 | 11pt | Regular (400) | Timestamps |

**Tracking (letter-spacing):**
- Tamanhos maiores (28-34pt): ~0.35-0.38px
- Tamanhos médios (17-22pt): -0.32 a -0.41px (negativo!)
- Tamanhos menores (11-15pt): -0.08 a 0.07px

**Line Height:**
- Calculado proporcional: ~120-140% do font size
- Exemplo: Body 17pt = 22pt leading (129%)

## 📏 Espaçamentos

```dart
spacing4   = 4px
spacing8   = 8px
spacing12  = 12px
spacing16  = 16px
spacing20  = 20px
spacing24  = 24px
spacing32  = 32px
spacing44  = 44px  // Minimum touch target
spacing64  = 64px
```

### Margens Padrão
- Cards internos: 16px
- Margens laterais: 20px (iOS padrão)
- Entre seções: 24-32px

## 🔲 Corner Radius

```dart
cornerRadius8  = 8px   // Badges, chips
cornerRadius10 = 10px  // Inputs
cornerRadius12 = 12px  // Cards, botões
cornerRadius16 = 16px  // Modals menores
cornerRadius20 = 20px  // Sheets, modals grandes
```

## 🌑 Elevação (Shadows)

**Muito sutis!** iOS usa sombras discretas:

### Level 1 (Elementos inline)
- Light: `rgba(0,0,0,0.04)` blur 4px offset (0,1)
- Dark: `rgba(0,0,0,0.3)` blur 4px offset (0,1)

### Level 2 (Cards)
- Light: `rgba(0,0,0,0.08)` blur 8px offset (0,2)
- Dark: `rgba(0,0,0,0.4)` blur 8px offset (0,2)

### Level 3 (Modals)
- Light: `rgba(0,0,0,0.12)` blur 16px offset (0,4)
- Dark: `rgba(0,0,0,0.5)` blur 16px offset (0,4)

## 🧩 Componentes

### Cards
- Background com leve opacidade (0.7-0.9) para blur effect
- Border muito sutil: `rgba(white/black, 0.04-0.08)` width 0.5px
- Corner radius 12px
- Shadow level 1

### Botões
- Height: 50px (toque confortável)
- Padding horizontal: 20px
- Corner radius: 12px
- Sem sombra/elevation
- Texto: Headline style

### Inputs
- Fill color: fillTertiary (semi-transparente)
- Sem border quando não focado
- Border 2px systemBlue quando focado
- Corner radius: 10px
- Padding: 16px horizontal, 12px vertical

### Dividers
- Height/thickness: 0.5px
- Color: separator (opacidade 30-60%)

## 📱 Comportamento

### Touch Targets
- Mínimo: 44x44px (iOS guideline)
- Botões: 50px altura
- List items: mínimo 44px

### Animações
- Duração: 200-400ms
- Curves: `easeOut`, `easeInOut`
- Muito sutis e funcionais

### Acessibilidade
- Contraste mínimo: 4.5:1 (WCAG AA)
- Labels para todos os ícones
- Dynamic Type support
- VoiceOver compatibility

## 🎯 Uso

```dart
// Cores
color: AppDesignSystem.systemBlue
color: isDark ? AppDesignSystem.darkPrimaryLabel : AppDesignSystem.lightPrimaryLabel

// Tipografia
style: AppDesignSystem.largeTitle
style: AppDesignSystem.body.copyWith(color: ...)

// Espaçamentos
padding: const EdgeInsets.all(AppDesignSystem.spacing16)
const SizedBox(height: AppDesignSystem.spacing24)

// Radius
borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12)

// Sombras
boxShadow: AppDesignSystem.shadowLevel1(isDark)

// Componentes
AppDesignSystem.card(child: ..., isDark: isDark)
AppDesignSystem.primaryButton(text: '...', onPressed: ..., isDark: isDark)
AppDesignSystem.inputDecoration(label: '...', isDark: isDark)
```

## 📚 Referências

- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)
- [SF Pro Font](https://developer.apple.com/fonts/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

---

**Última atualização:** 2024 - Baseado em iOS 17/18 guidelines
