import 'dart:async';
import 'package:invoiceninja_flutter/data/models/webhook_model.dart';
import 'package:invoiceninja_flutter/ui/app/entities/entity_actions_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/tables/entity_list.dart';
import 'package:invoiceninja_flutter/ui/webhook/webhook_list_item.dart';
import 'package:invoiceninja_flutter/ui/webhook/webhook_presenter.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/redux/webhook/webhook_selectors.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/webhook/webhook_actions.dart';

class WebhookListBuilder extends StatelessWidget {
  const WebhookListBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, WebhookListVM>(
      converter: WebhookListVM.fromStore,
      builder: (context, viewModel) {
        return EntityList(
            entityType: EntityType.webhook,
            presenter: WebhookPresenter(),
            state: viewModel.state,
            entityList: viewModel.webhookList,
            tableColumns: viewModel.tableColumns,
            onRefreshed: viewModel.onRefreshed,
            onClearEntityFilterPressed: viewModel.onClearEntityFilterPressed,
            onViewEntityFilterPressed: viewModel.onViewEntityFilterPressed,
            onSortColumn: viewModel.onSortColumn,
            itemBuilder: (BuildContext context, index) {
              final state = viewModel.state;
              final webhookId = viewModel.webhookList[index];
              final webhook = viewModel.webhookMap[webhookId];
              final listState = state.getListState(EntityType.webhook);
              final isInMultiselect = listState.isInMultiselect();

              return WebhookListItem(
                user: viewModel.state.user,
                filter: viewModel.filter,
                webhook: webhook,
                onEntityAction: (EntityAction action) {
                  if (action == EntityAction.more) {
                    showEntityActionsDialog(
                      entities: [webhook],
                      context: context,
                    );
                  } else {
                    handleWebhookAction(context, [webhook], action);
                  }
                },
                isChecked: isInMultiselect && listState.isSelected(webhook.id),
              );
            });
      },
    );
  }
}

class WebhookListVM {
  WebhookListVM({
    @required this.state,
    @required this.userCompany,
    @required this.webhookList,
    @required this.webhookMap,
    @required this.filter,
    @required this.isLoading,
    @required this.listState,
    @required this.onRefreshed,
    @required this.onEntityAction,
    @required this.tableColumns,
    @required this.onClearEntityFilterPressed,
    @required this.onViewEntityFilterPressed,
    @required this.onSortColumn,
  });

  static WebhookListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>(null);
      }
      final completer = snackBarCompleter<Null>(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(RefreshData(completer: completer));
      return completer.future;
    }

    final state = store.state;

    return WebhookListVM(
      state: state,
      userCompany: state.userCompany,
      listState: state.webhookListState,
      webhookList: memoizedFilteredWebhookList(state.webhookState.map,
          state.webhookState.list, state.webhookListState),
      webhookMap: state.webhookState.map,
      isLoading: state.isLoading,
      filter: state.webhookUIState.listUIState.filter,
      onClearEntityFilterPressed: () => store.dispatch(ClearEntityFilter()),
      onViewEntityFilterPressed: (BuildContext context) => viewEntityById(
          context: context,
          entityId: state.webhookListState.filterEntityId,
          entityType: state.webhookListState.filterEntityType),
      onEntityAction: (BuildContext context, List<BaseEntity> webhooks,
              EntityAction action) =>
          handleWebhookAction(context, webhooks, action),
      onRefreshed: (context) => _handleRefresh(context),
      tableColumns:
          state.userCompany.settings.getTableColumns(EntityType.webhook) ??
              WebhookPresenter.getAllTableFields(state.userCompany),
      onSortColumn: (field) => store.dispatch(SortWebhooks(field)),
    );
  }

  final AppState state;
  final UserCompanyEntity userCompany;
  final List<String> webhookList;
  final BuiltMap<String, WebhookEntity> webhookMap;
  final ListUIState listState;
  final String filter;
  final bool isLoading;
  final Function(BuildContext) onRefreshed;
  final Function(BuildContext, List<BaseEntity>, EntityAction) onEntityAction;
  final Function onClearEntityFilterPressed;
  final Function(BuildContext) onViewEntityFilterPressed;
  final List<String> tableColumns;
  final Function(String) onSortColumn;
}
