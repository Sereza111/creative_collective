import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../models/transaction.dart' as transaction_model;
import 'export_result.dart';

class ExportService {
  static Future<ExportResult> exportProjectsToCSV(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/projects_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final List<List<dynamic>> rows = [
      ['ID', 'Название', 'Описание', 'Статус', 'Бюджет', 'Потрачено', 'Прогресс %', 'Старт', 'Дедлайн'],
    ];

    for (var project in projects) {
      rows.add([
        project.id,
        project.name,
        project.description ?? '',
        project.status,
        project.budget,
        project.spent,
        project.progress,
        project.startDate.toString().split(' ')[0],
        project.endDate.toString().split(' ')[0],
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csv);

    return ExportResult('Проекты экспортированы: ${file.path}');
  }

  static Future<ExportResult> exportTasksToCSV(List<Task> tasks) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/tasks_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final List<List<dynamic>> rows = [
      ['ID', 'Название', 'Описание', 'Статус', 'Приоритет', 'Проект ID', 'Дедлайн', 'Создано'],
    ];

    for (var task in tasks) {
      rows.add([
        task.id,
        task.title,
        task.description ?? '',
        task.status,
        task.priority,
        task.projectId,
        task.dueDate.toString().split(' ')[0],
        task.createdAt.toString().split(' ')[0],
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csv);

    return ExportResult('Задачи экспортированы: ${file.path}');
  }

  static Future<ExportResult> exportTransactionsToCSV(
    List<transaction_model.TransactionModel> transactions,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final List<List<dynamic>> rows = [
      ['ID', 'Тип', 'Сумма', 'Описание', 'Категория', 'Дата'],
    ];

    for (var transaction in transactions) {
      rows.add([
        transaction.id,
        transaction.type,
        transaction.amount,
        transaction.description ?? '',
        transaction.status,
        transaction.createdAt.toString().split(' ')[0],
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csv);

    return ExportResult('Транзакции экспортированы: ${file.path}');
  }

  static Future<ExportResult> exportAllDataToCSV({
    required List<Project> projects,
    required List<Task> tasks,
    required List<transaction_model.TransactionModel> transactions,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/all_data_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final List<List<dynamic>> rows = [
      ['=== ПРОЕКТЫ ==='],
      ['ID', 'Название', 'Статус', 'Бюджет', 'Потрачено', 'Прогресс %'],
    ];

    for (var project in projects) {
      rows.add([
        project.id,
        project.name,
        project.status,
        project.budget,
        project.spent,
        project.progress,
      ]);
    }

    rows.addAll([
      [],
      ['=== ЗАДАЧИ ==='],
      ['ID', 'Название', 'Статус', 'Приоритет', 'Дедлайн'],
    ]);

    for (var task in tasks) {
      rows.add([
        task.id,
        task.title,
        task.status,
        task.priority,
        task.dueDate.toString().split(' ')[0],
      ]);
    }

    rows.addAll([
      [],
      ['=== ТРАНЗАКЦИИ ==='],
      ['ID', 'Тип', 'Сумма', 'Описание', 'Дата'],
    ]);

    for (var transaction in transactions) {
      rows.add([
        transaction.id,
        transaction.type,
        transaction.amount,
        transaction.description ?? '',
        transaction.createdAt.toString().split(' ')[0],
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csv);

    return ExportResult('Все данные экспортированы: ${file.path}');
  }
}
