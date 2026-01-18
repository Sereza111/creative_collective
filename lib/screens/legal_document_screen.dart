import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class LegalDocumentScreen extends ConsumerStatefulWidget {
  final String documentType;
  final String title;
  final int? orderId; // Для order_contract
  final VoidCallback? onSigned;

  const LegalDocumentScreen({
    Key? key,
    required this.documentType,
    required this.title,
    this.orderId,
    this.onSigned,
  }) : super(key: key);

  @override
  ConsumerState<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends ConsumerState<LegalDocumentScreen> {
  bool _isLoading = true;
  bool _isSigning = false;
  bool _agreed = false;
  Map<String, dynamic>? _document;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_scrolledToBottom) {
        setState(() {
          _scrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final document = await ApiService.getLegalDocument(widget.documentType);
      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signDocument() async {
    if (!_agreed || !_scrolledToBottom) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Прочитайте документ до конца и поставьте галочку'),
          backgroundColor: AppTheme.bloodRed,
        ),
      );
      return;
    }

    setState(() {
      _isSigning = true;
    });

    try {
      await ApiService.signLegalDocument(
        documentId: _document!['id'],
        documentType: widget.documentType,
        orderId: widget.orderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Документ подписан'),
            backgroundColor: AppTheme.gothicGreen,
          ),
        );
        
        if (widget.onSigned != null) {
          widget.onSigned!();
        }
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: Text(widget.title.toUpperCase()),
        backgroundColor: AppTheme.darkerCharcoal,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.tombstoneWhite,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.bloodRed),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки документа',
                        style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: AppTheme.mistGray),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadDocument,
                        child: Text('ПОВТОРИТЬ'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Документ
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkerCharcoal,
                          border: Border.all(
                            color: AppTheme.dimGray.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Markdown(
                          controller: _scrollController,
                          data: _document!['content'],
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: AppTheme.tombstoneWhite,
                              fontSize: 13,
                              height: 1.6,
                            ),
                            h1: TextStyle(
                              color: AppTheme.ghostWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                            ),
                            h2: TextStyle(
                              color: AppTheme.ashGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                            ),
                            h3: TextStyle(
                              color: AppTheme.mistGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                            code: TextStyle(
                              color: AppTheme.electricBlue,
                              backgroundColor: AppTheme.deepBlack,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppTheme.deepBlack,
                              border: Border.all(
                                color: AppTheme.dimGray.withValues(alpha: 0.3),
                              ),
                            ),
                            blockquote: TextStyle(
                              color: AppTheme.mistGray,
                              fontStyle: FontStyle.italic,
                            ),
                            listBullet: TextStyle(color: AppTheme.ashGray),
                          ),
                        ),
                      ),
                    ),

                    // Индикатор прокрутки
                    if (!_scrolledToBottom)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: AppTheme.darkerCharcoal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, size: 16, color: AppTheme.mistGray),
                            const SizedBox(width: 8),
                            Text(
                              'Прокрутите до конца',
                              style: TextStyle(
                                color: AppTheme.mistGray,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Чекбокс и кнопка подписи
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkerCharcoal,
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.dimGray.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _agreed,
                            onChanged: _scrolledToBottom
                                ? (value) {
                                    setState(() {
                                      _agreed = value ?? false;
                                    });
                                  }
                                : null,
                            title: Text(
                              'Я прочитал(а) и согласен(на) с условиями документа',
                              style: TextStyle(
                                color: _scrolledToBottom ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                                fontSize: 13,
                              ),
                            ),
                            activeColor: AppTheme.gothicGreen,
                            checkColor: AppTheme.charcoal,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_agreed && _scrolledToBottom && !_isSigning)
                                  ? _signDocument
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gothicGreen,
                                foregroundColor: AppTheme.charcoal,
                                disabledBackgroundColor: AppTheme.shadowGray,
                                disabledForegroundColor: AppTheme.mistGray,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: _isSigning
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                                      ),
                                    )
                                  : Text(
                                      'ПОДПИСАТЬ ДОКУМЕНТ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        letterSpacing: 2.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

