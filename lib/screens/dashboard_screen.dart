import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<ProjectNode> nodes;

  @override
  void initState() {
    super.initState();
    nodes = [
      ProjectNode(
        id: '1',
        title: 'Видеоклип "Cyberpunk"',
        status: 'active',
        position: const Offset(50, 100),
        budget: 50000,
        spent: 37500,
      ),
      ProjectNode(
        id: '2',
        title: 'Музыка (Битмейк)',
        status: 'in_progress',
        position: const Offset(350, 50),
        assignedTo: 'Иван',
      ),
      ProjectNode(
        id: '3',
        title: 'Видео (Монтаж)',
        status: 'todo',
        position: const Offset(650, 50),
        assignedTo: 'Мария',
      ),
      ProjectNode(
        id: '4',
        title: 'Финальный микс',
        status: 'done',
        position: const Offset(350, 250),
        assignedTo: 'Денис',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавить проект'),
                  backgroundColor: AppTheme.shadowGray,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppTheme.fadeInAnimation(
                child: Column(
                  children: [
                    AppTheme.gothicTitle('Карта проектов'),
                    const SizedBox(height: 16),
                    Text(
                      'Перетаскивайте узлы',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mistGray,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            AppTheme.gothicDivider(),
            const SizedBox(height: 32),
            
            // Канвас
            AppTheme.fadeInAnimation(
              duration: const Duration(milliseconds: 1200),
              child: Container(
                height: 500,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlack,
                  border: Border.all(
                    color: AppTheme.dimGray.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Stack(
                  children: [
                    // Сетка
                    CustomPaint(
                      painter: GridPainter(),
                      size: const Size(double.infinity, 500),
                    ),
                    // Соединения
                    CustomPaint(
                      painter: ConnectionPainter(nodes: nodes),
                      size: const Size(double.infinity, 500),
                    ),
                    // Узлы
                    ...nodes.map((node) {
                      return Positioned(
                        left: node.position.dx,
                        top: node.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              node.position = Offset(
                                (node.position.dx + details.delta.dx).clamp(0.0, 700.0),
                                (node.position.dy + details.delta.dy).clamp(0.0, 450.0),
                              );
                            });
                          },
                          child: _buildNode(node),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildStatsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(ProjectNode node) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.voidBlack,
              border: Border.all(
                color: AppTheme.dimGray.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.tombstoneWhite,
                    height: 1.4,
                    letterSpacing: 1.0,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                if (node.budget != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₽${((node.budget! - (node.spent ?? 0)) / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.ashGray,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '${((node.spent ?? 0) / (node.budget ?? 1) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mistGray,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      color: AppTheme.shadowGray,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (node.spent ?? 0) / (node.budget ?? 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.ashGray,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ],
                if (node.assignedTo != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    node.assignedTo!,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.mistGray,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppTheme.gothicBadge(node.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    double totalBudget = 0;
    double totalSpent = 0;
    int activeProjects = 0;

    for (var node in nodes) {
      if (node.budget != null) {
        totalBudget += node.budget!;
        totalSpent += node.spent ?? 0;
      }
      if (node.status == 'active' || node.status == 'in_progress') {
        activeProjects++;
      }
    }

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 1400),
      child: AppTheme.gothicCard(
        title: 'Статистика',
        borderColor: AppTheme.dimGray.withOpacity(0.5),
        padding: const EdgeInsets.all(28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statCard('Всего', nodes.length.toString()),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            _statCard('Активные', activeProjects.toString()),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            _statCard('Бюджет', '₽${(totalBudget / 1000).toStringAsFixed(0)}K'),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            _statCard('Потрачено', '₽${(totalSpent / 1000).toStringAsFixed(0)}K'),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w200,
            color: AppTheme.tombstoneWhite,
            fontFamily: 'serif',
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.mistGray,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}

class ProjectNode {
  final String id;
  final String title;
  final String status;
  Offset position;
  final double? budget;
  final double? spent;
  final String? assignedTo;

  ProjectNode({
    required this.id,
    required this.title,
    required this.status,
    required this.position,
    this.budget,
    this.spent,
    this.assignedTo,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.dimGray.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSpacing = 50.0;

    // Вертикальные линии
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Горизонтальные линии
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}

class ConnectionPainter extends CustomPainter {
  final List<ProjectNode> nodes;

  ConnectionPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.dimGray.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (nodes.length >= 2) {
      final start = Offset(nodes[0].position.dx + 100, nodes[0].position.dy + 50);
      final end = Offset(nodes[1].position.dx + 100, nodes[1].position.dy + 50);
      canvas.drawLine(start, end, paint);
    }

    if (nodes.length >= 4) {
      final start = Offset(nodes[1].position.dx + 100, nodes[1].position.dy + 50);
      final end = Offset(nodes[3].position.dx + 100, nodes[3].position.dy + 50);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) => true;
}
