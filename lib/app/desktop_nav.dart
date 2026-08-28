import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../domain/models.dart';

/// Что показать в большой правой панели десктопа (master-detail).
sealed class DetailReq {
  const DetailReq();
}

/// Редактировать существующее дело или заметку (панель выбирает редактор по
/// [TaskModel.isNote]).
class EditExisting extends DetailReq {
  const EditExisting(this.task);
  final TaskModel task;
}

/// Создать новое дело (с датой/отложенное/путешествие).
class ComposeTask extends DetailReq {
  const ComposeTask({this.initialDate, this.deferred = false, this.trip = false});
  final DateTime? initialDate;
  final bool deferred;
  final bool trip;
}

/// Создать новую заметку в категории.
class ComposeNote extends DetailReq {
  const ComposeNote(this.category);
  final int category;
}

/// Показать список раздела «Заметки» (категория) в правой панели.
class ShowCategory extends DetailReq {
  const ShowCategory(this.category);
  final int category;
}

/// Рабочая карточка заметки/проекта (не форма настроек): чек-лист, описание,
/// ссылки. Правка полей — по кнопке (открывает [EditExisting]).
class ShowNote extends DetailReq {
  const ShowNote(this.note);
  final TaskModel note;
}

class DetailReqNotifier extends Notifier<DetailReq?> {
  @override
  DetailReq? build() => null;

  void open(DetailReq r) => state = r;
  void close() => state = null;
}

/// Текущее содержимое правой панели десктопа (null — пусто).
final detailReqProvider =
    NotifierProvider<DetailReqNotifier, DetailReq?>(DetailReqNotifier.new);

/// Открывать ли редакторы в правой панели, а не отдельным экраном: только на
/// широком окне И когда мы на главном экране (первый маршрут; на вложенных
/// экранах-списках редактор по-прежнему открывается поверх).
bool useDesktopDetail(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideBreakpoint &&
    (ModalRoute.of(context)?.isFirst ?? false);
