import 'package:app/services/logging.dart';
import 'package:app/services/profile_storage.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders {
  AppProviders()
      : logger = const AppLogger(),
        profileStorage = ProfileStorage(),
        transferQueue = TransferQueue();

  final AppLogger logger;
  final ProfileStorage profileStorage;
  final TransferQueue transferQueue;

  List<SingleChildWidget> asList() {
    return [
      Provider<AppLogger>.value(value: logger),
      Provider<ProfileStorage>.value(value: profileStorage),
      ChangeNotifierProvider<TransferQueue>.value(value: transferQueue),
    ];
  }
}
