import 'package:cma_registrator/core/widgets/future_builder_scaffold.dart';
import 'package:davi/davi.dart';
import 'package:flutter/cupertino.dart';
import 'package:hmi_core/hmi_core.dart';
import 'package:hmi_networking/hmi_networking.dart';
import 'package:hmi_widgets/hmi_widgets.dart';
///
class SignalsPage extends StatelessWidget {
  final JdsService _jdsService;
  final DsClient _dsClient;
  ///
  const SignalsPage({
    super.key,
    required JdsService jdsService,
    required DsClient dsClient,
  }) : _dsClient = dsClient, _jdsService = jdsService;
  //
  @override
  Widget build(BuildContext context) {
    return FutureBuilderScaffold(
      title: const Localized("Signals").v,
      appBarRightWidgets: const [Spacer()],
      onFuture: () => _jdsService.points(),
      caseData: (context, data) {
        return Davi(
          DaviModel<String>(
            rows: data.names,
            columns: [
              DaviColumn(
                grow: 1,
                name: const Localized('Source').v,
                stringValue: (row) => row.split('/')[1],
              ),
              DaviColumn(
                grow: 1,
                name: const Localized('IED').v,
                stringValue: (row) => row.split('/')[2],
              ),
              DaviColumn(
                grow: 1,
                name: const Localized('DB').v,
                stringValue: (row) {
                  final split = row.split('/');
                  return split.length > 4 ? row.split('/')[3] : '-';
                },
              ),
              DaviColumn(
                grow: 2,
                name: const Localized('Name').v,
                stringValue: (row) {
                  final split = row.split('/');
                  return split.length > 4 ? row.split('/')[4] : row.split('/')[3];
                },
              ),
              DaviColumn(
                grow: 1,
                name: const Localized('Value').v,
                cellBuilder: (context, row) {
                  _dsClient.requestAll();
                  final pointName = DsPointName(row.data);
                  return FittedBox(
                    child: TextValueIndicator(
                      stream: _dsClient
                        .streamReal(pointName.name)
                        .where((point) => point.name == pointName),
                    ),
                  );
                },
              )
            ]
          ),
        );
      },
      caseError: (context, error) => Center(
        child: Text(error.toString()),
      ),
      caseLoading: (_) => const Center(
        child: CupertinoActivityIndicator(),
      ),
      caseNothing: (context) => Center(
        child: Text(
          const Localized("There are no signals in server config").v,
        ),
      ),
    );
  }
}