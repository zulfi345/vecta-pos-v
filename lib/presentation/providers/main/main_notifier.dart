import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../auth/auth_notifier.dart';
import '../products/products_notifier.dart';
import 'main_state.dart';

final mainNotifierProvider = NotifierProvider<MainNotifier, MainState>(MainNotifier.new);

class MainNotifier extends Notifier<MainState> {
  @override
  MainState build() => const MainState();

  Future<void> initMainProvider() => loadUserData();

  Future<void> loadUserData() async {
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) throw 'Unauthenticated!';

    final authUser = authState.user!;
    final repo = ref.read(userRepositoryProvider);

    var user = (await GetUserUsecase(repo).call(authUser.id)).data;

    if (user == null) {
      await CreateUserUsecase(repo).call(authUser);
      user = authUser;
    }

    state = state.copyWith(user: user, isLoaded: true);
    ref.read(productsNotifierProvider.notifier).getAllProducts();
  }
}
