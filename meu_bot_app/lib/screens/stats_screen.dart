import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/message_search_service.dart';
import '../services/export_service.dart';
import '../services/image_cache_service.dart';
import '../services/supabase_service.dart';
import '../providers/assistant_provider.dart';
import '../theme/design_system.dart';
import '../theme/theme_provider.dart';

/// Tela de estatísticas e gestão
///
/// Mostra estatísticas de uso e opções de gestão de dados
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  MessageStats? _stats;
  CacheStats? _cacheStats;
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final stats = await MessageSearchService.getStats(userId: userId);
      final cacheStats = await ImageCacheService.getStats();

      setState(() {
        _stats = stats;
        _cacheStats = cacheStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar estatísticas: $e');
    }
  }

  Future<void> _exportData(String format) async {
    setState(() => _isExporting = true);

    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final file = format == 'json'
          ? await ExportService.exportToJson(userId: userId)
          : await ExportService.exportToText(userId: userId);

      await ExportService.shareExport(file, format);

      _showSuccess('Dados exportados com sucesso!');
    } catch (e) {
      _showError('Erro ao exportar: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog(
      'Limpar Cache',
      'Deseja realmente limpar o cache de imagens?\n\n'
          'Isso liberará ${_cacheStats?.totalSizeFormatted ?? "0 B"} de espaço.',
    );

    if (!confirmed) return;

    setState(() => _isClearingCache = true);

    try {
      await ImageCacheService.clearCache();
      await _loadStats();

      _showSuccess('Cache limpo com sucesso!');
    } catch (e) {
      _showError('Erro ao limpar cache: $e');
    } finally {
      setState(() => _isClearingCache = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.systemRed,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppDesignSystem.systemGreen,
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
          : AppDesignSystem.lightGroupedBackground,
      appBar: AppDesignSystem.appBar(
        title: 'Estatísticas e Gestão',
        isDark: isDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: EdgeInsets.all(AppDesignSystem.spacing16),
                children: [
                  _buildStatsSection(isDark),
                  SizedBox(height: AppDesignSystem.spacing24),
                  _buildCacheSection(isDark),
                  SizedBox(height: AppDesignSystem.spacing24),
                  _buildExportSection(isDark),
                ],
              ),
            ),
    );
  }

  /// Seção de estatísticas
  Widget _buildStatsSection(bool isDark) {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDesignSystem.sectionHeader('Estatísticas', isDark),
        _buildStatsCard(isDark),
      ],
    );
  }

  /// Card de estatísticas
  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppDesignSystem.spacing20),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightGroupedSecondaryBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
        boxShadow: AppDesignSystem.shadowLevel1(isDark),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Total de Mensagens',
            _stats!.totalMessages.toString(),
            Icons.chat_bubble_outline,
            isDark,
          ),
          AppDesignSystem.divider(isDark),
          _buildStatRow(
            'Suas Mensagens',
            _stats!.userMessages.toString(),
            Icons.person,
            isDark,
          ),
          AppDesignSystem.divider(isDark),
          _buildStatRow(
            'Respostas do Bot',
            _stats!.botMessages.toString(),
            Icons.smart_toy,
            isDark,
          ),
          AppDesignSystem.divider(isDark),
          _buildStatRow(
            'Imagens',
            _stats!.imageMessages.toString(),
            Icons.image,
            isDark,
          ),
          AppDesignSystem.divider(isDark),
          _buildStatRow(
            'Áudios',
            _stats!.audioMessages.toString(),
            Icons.audiotrack,
            isDark,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDesignSystem.spacing12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDesignSystem.spacing8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppDesignSystem.darkFillTertiary
                  : AppDesignSystem.lightFillTertiary,
              borderRadius:
                  BorderRadius.circular(AppDesignSystem.cornerRadius8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppDesignSystem.darkSecondaryLabel
                  : AppDesignSystem.lightSecondaryLabel,
            ),
          ),
          SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Text(
              label,
              style: AppDesignSystem.body.copyWith(
                color: isDark
                    ? AppDesignSystem.darkPrimaryLabel
                    : AppDesignSystem.lightPrimaryLabel,
              ),
            ),
          ),
          Text(
            value,
            style: AppDesignSystem.headline.copyWith(
              color: isDark
                  ? AppDesignSystem.systemBlueDark
                  : AppDesignSystem.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de cache
  Widget _buildCacheSection(bool isDark) {
    if (_cacheStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDesignSystem.sectionHeader('Armazenamento', isDark),
        Container(
          padding: EdgeInsets.all(AppDesignSystem.spacing20),
          decoration: BoxDecoration(
            color: isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightGroupedSecondaryBackground,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
            boxShadow: AppDesignSystem.shadowLevel1(isDark),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    color: isDark
                        ? AppDesignSystem.systemBlueDark
                        : AppDesignSystem.systemBlue,
                  ),
                  SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cache de Imagens',
                          style: AppDesignSystem.headline.copyWith(
                            color: isDark
                                ? AppDesignSystem.darkPrimaryLabel
                                : AppDesignSystem.lightPrimaryLabel,
                          ),
                        ),
                        Text(
                          '${_cacheStats!.fileCount} arquivos • ${_cacheStats!.totalSizeFormatted}',
                          style: AppDesignSystem.caption1.copyWith(
                            color: isDark
                                ? AppDesignSystem.darkSecondaryLabel
                                : AppDesignSystem.lightSecondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDesignSystem.spacing16),
              SizedBox(
                width: double.infinity,
                child: AppDesignSystem.secondaryButton(
                  text: 'Limpar Cache',
                  onPressed: _isClearingCache ? null : _clearCache,
                  isDark: isDark,
                  isLoading: _isClearingCache,
                  icon: Icons.cleaning_services,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  /// Seção de exportação
  Widget _buildExportSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDesignSystem.sectionHeader('Exportar Dados', isDark),
        Container(
          padding: EdgeInsets.all(AppDesignSystem.spacing20),
          decoration: BoxDecoration(
            color: isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightGroupedSecondaryBackground,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
            boxShadow: AppDesignSystem.shadowLevel1(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportar conversas',
                style: AppDesignSystem.headline.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
              ),
              SizedBox(height: AppDesignSystem.spacing8),
              Text(
                'Faça backup das suas conversas em diferentes formatos',
                style: AppDesignSystem.subheadline.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkSecondaryLabel
                      : AppDesignSystem.lightSecondaryLabel,
                ),
              ),
              SizedBox(height: AppDesignSystem.spacing20),
              Row(
                children: [
                  Expanded(
                    child: AppDesignSystem.secondaryButton(
                      text: 'JSON',
                      onPressed: _isExporting ? null : () => _exportData('json'),
                      isDark: isDark,
                      icon: Icons.code,
                    ),
                  ),
                  SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: AppDesignSystem.secondaryButton(
                      text: 'TXT',
                      onPressed: _isExporting ? null : () => _exportData('txt'),
                      isDark: isDark,
                      icon: Icons.text_snippet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
