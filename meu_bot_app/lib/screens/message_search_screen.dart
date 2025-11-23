import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/message_search_service.dart';
import '../services/supabase_service.dart';
import '../providers/assistant_provider.dart';
import '../theme/design_system.dart';
import '../theme/theme_provider.dart';

/// Tela de busca de mensagens
///
/// Permite buscar mensagens por texto, data ou tipo
class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<types.Message> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  // Filtros
  String? _selectedAssistantId;
  SearchFilter _selectedFilter = SearchFilter.all;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    // Focus automático no campo de busca
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      List<types.Message> results;

      switch (_selectedFilter) {
        case SearchFilter.all:
          results = await MessageSearchService.searchMessages(
            userId: userId,
            query: query,
            assistantId: _selectedAssistantId,
          );
          break;

        case SearchFilter.images:
          results = await MessageSearchService.searchMediaMessages(
            userId: userId,
            mediaType: 'image',
            assistantId: _selectedAssistantId,
          );
          break;

        case SearchFilter.audios:
          results = await MessageSearchService.searchMediaMessages(
            userId: userId,
            mediaType: 'audio',
            assistantId: _selectedAssistantId,
          );
          break;
      }

      setState(() {
        _searchResults = results;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        _showError('Erro ao buscar: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppDesignSystem.systemRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      appBar: AppDesignSystem.appBar(
        title: 'Buscar Mensagens',
        isDark: isDark,
      ),
      body: Column(
        children: [
          // Campo de busca
          _buildSearchBar(isDark),

          // Filtros
          _buildFilters(isDark),

          // Resultados
          Expanded(
            child: _buildResults(isDark),
          ),
        ],
      ),
    );
  }

  /// Barra de busca
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightSecondaryBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppDesignSystem.darkSeparator
                : AppDesignSystem.lightSeparator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppDesignSystem.darkFillTertiary
                    : AppDesignSystem.lightFillTertiary,
                borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar mensagens...',
                  hintStyle: AppDesignSystem.body.copyWith(
                    color: isDark
                        ? AppDesignSystem.darkTertiaryLabel
                        : AppDesignSystem.lightTertiaryLabel,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark
                        ? AppDesignSystem.darkSecondaryLabel
                        : AppDesignSystem.lightSecondaryLabel,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark
                                ? AppDesignSystem.darkSecondaryLabel
                                : AppDesignSystem.lightSecondaryLabel,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _hasSearched = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing16,
                    vertical: AppDesignSystem.spacing12,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          SizedBox(width: AppDesignSystem.spacing8),
          // Botão de busca
          Material(
            color: isDark
                ? AppDesignSystem.systemBlueDark
                : AppDesignSystem.systemBlue,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(AppDesignSystem.cornerRadius10),
              onTap: _isSearching ? null : _performSearch,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filtros de busca
  Widget _buildFilters(bool isDark) {
    final assistantProvider = Provider.of<AssistantProvider>(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightSecondaryBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppDesignSystem.darkSeparator
                : AppDesignSystem.lightSeparator,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro de tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SearchFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;

                return Padding(
                  padding: EdgeInsets.only(right: AppDesignSystem.spacing8),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      if (_hasSearched) {
                        _performSearch();
                      }
                    },
                    backgroundColor: isDark
                        ? AppDesignSystem.darkFillTertiary
                        : AppDesignSystem.lightFillTertiary,
                    selectedColor: isDark
                        ? AppDesignSystem.systemBlueDark
                        : AppDesignSystem.systemBlue,
                    labelStyle: AppDesignSystem.callout.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppDesignSystem.darkPrimaryLabel
                              : AppDesignSystem.lightPrimaryLabel),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Filtro de assistente
          if (assistantProvider.assistants.length > 1) ...[
            SizedBox(height: AppDesignSystem.spacing8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Opção "Todos"
                  Padding(
                    padding: EdgeInsets.only(right: AppDesignSystem.spacing8),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedAssistantId == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedAssistantId = null;
                        });
                        if (_hasSearched) {
                          _performSearch();
                        }
                      },
                      backgroundColor: isDark
                          ? AppDesignSystem.darkFillTertiary
                          : AppDesignSystem.lightFillTertiary,
                      selectedColor: isDark
                          ? AppDesignSystem.systemBlueDark
                          : AppDesignSystem.systemBlue,
                      labelStyle: AppDesignSystem.callout.copyWith(
                        color: _selectedAssistantId == null
                            ? Colors.white
                            : (isDark
                                ? AppDesignSystem.darkPrimaryLabel
                                : AppDesignSystem.lightPrimaryLabel),
                      ),
                    ),
                  ),

                  // Assistentes
                  ...assistantProvider.assistants.map((assistant) {
                    final isSelected = _selectedAssistantId == assistant.id;

                    return Padding(
                      padding:
                          EdgeInsets.only(right: AppDesignSystem.spacing8),
                      child: FilterChip(
                        label: Text(assistant.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedAssistantId =
                                selected ? assistant.id : null;
                          });
                          if (_hasSearched) {
                            _performSearch();
                          }
                        },
                        backgroundColor: isDark
                            ? AppDesignSystem.darkFillTertiary
                            : AppDesignSystem.lightFillTertiary,
                        selectedColor: assistant.primaryColor,
                        labelStyle: AppDesignSystem.callout.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppDesignSystem.darkPrimaryLabel
                                  : AppDesignSystem.lightPrimaryLabel),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Resultados da busca
  Widget _buildResults(bool isDark) {
    if (!_hasSearched) {
      return _buildEmptyState(isDark);
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults(isDark);
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: EdgeInsets.all(AppDesignSystem.spacing16),
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        return _buildMessageCard(message, isDark)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  /// Card de mensagem
  Widget _buildMessageCard(types.Message message, bool isDark) {
    final timestamp = message.createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(message.createdAt!)
        : DateTime.now();

    final isUser = message.author.id != 'bot';

    return Container(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightGroupedSecondaryBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        boxShadow: AppDesignSystem.shadowLevel1(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          onTap: () {
            // TODO: Navegar para a mensagem no chat
          },
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isUser ? Icons.person : Icons.smart_toy,
                      size: 16,
                      color: isDark
                          ? AppDesignSystem.darkSecondaryLabel
                          : AppDesignSystem.lightSecondaryLabel,
                    ),
                    SizedBox(width: AppDesignSystem.spacing8),
                    Text(
                      message.author.firstName ?? 'Desconhecido',
                      style: AppDesignSystem.headline.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkPrimaryLabel
                            : AppDesignSystem.lightPrimaryLabel,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(timestamp, locale: 'pt_BR'),
                      style: AppDesignSystem.caption1.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkTertiaryLabel
                            : AppDesignSystem.lightTertiaryLabel,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDesignSystem.spacing12),

                // Conteúdo
                if (message is types.TextMessage)
                  Text(
                    message.text,
                    style: AppDesignSystem.body.copyWith(
                      color: isDark
                          ? AppDesignSystem.darkPrimaryLabel
                          : AppDesignSystem.lightPrimaryLabel,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (message is types.ImageMessage)
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: isDark
                            ? AppDesignSystem.darkSecondaryLabel
                            : AppDesignSystem.lightSecondaryLabel,
                      ),
                      SizedBox(width: AppDesignSystem.spacing8),
                      Text(
                        '[Imagem]',
                        style: AppDesignSystem.body.copyWith(
                          color: isDark
                              ? AppDesignSystem.darkSecondaryLabel
                              : AppDesignSystem.lightSecondaryLabel,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else if (message is types.FileMessage)
                  Row(
                    children: [
                      Icon(
                        Icons.audiotrack,
                        color: isDark
                            ? AppDesignSystem.darkSecondaryLabel
                            : AppDesignSystem.lightSecondaryLabel,
                      ),
                      SizedBox(width: AppDesignSystem.spacing8),
                      Text(
                        '[Áudio]',
                        style: AppDesignSystem.body.copyWith(
                          color: isDark
                              ? AppDesignSystem.darkSecondaryLabel
                              : AppDesignSystem.lightSecondaryLabel,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Estado vazio (antes de buscar)
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: isDark
                  ? AppDesignSystem.darkFillTertiary
                  : AppDesignSystem.lightFillTertiary,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(curve: Curves.elasticOut),
            SizedBox(height: AppDesignSystem.spacing16),
            Text(
              'Busque suas mensagens',
              style: AppDesignSystem.headline.copyWith(
                color: isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ),
            SizedBox(height: AppDesignSystem.spacing8),
            Text(
              'Digite algo no campo acima para começar',
              textAlign: TextAlign.center,
              style: AppDesignSystem.subheadline.copyWith(
                color: isDark
                    ? AppDesignSystem.darkTertiaryLabel
                    : AppDesignSystem.lightTertiaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sem resultados
  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: isDark
                  ? AppDesignSystem.darkFillTertiary
                  : AppDesignSystem.lightFillTertiary,
            ).animate().fadeIn(duration: 600.ms).shake(),
            SizedBox(height: AppDesignSystem.spacing16),
            Text(
              'Nenhum resultado encontrado',
              style: AppDesignSystem.headline.copyWith(
                color: isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ),
            SizedBox(height: AppDesignSystem.spacing8),
            Text(
              'Tente buscar com outros termos',
              textAlign: TextAlign.center,
              style: AppDesignSystem.subheadline.copyWith(
                color: isDark
                    ? AppDesignSystem.darkTertiaryLabel
                    : AppDesignSystem.lightTertiaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filtros de busca
enum SearchFilter {
  all('Todas'),
  images('Imagens'),
  audios('Áudios');

  final String label;
  const SearchFilter(this.label);
}
