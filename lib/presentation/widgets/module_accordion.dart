import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

typedef _AccordionIdentity = ({Object screen, String? user, String? initial});

final _expandedModule = StateProvider.autoDispose
    .family<String?, _AccordionIdentity>((ref, identity) => identity.initial);

/// Expansion is local to this mounted list and account. Two instances showing
/// the same course deliberately do not share their open module or page storage.
class ModuleAccordion extends ConsumerStatefulWidget {
  const ModuleAccordion({super.key, required this.child, this.initialModuleId});

  final Widget child;
  final String? initialModuleId;

  @override
  ConsumerState<ModuleAccordion> createState() => _ModuleAccordionState();
}

class _ModuleAccordionState extends ConsumerState<ModuleAccordion> {
  final Object _screen = Object();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(
      authControllerProvider.select((state) => state.value?.user?.id),
    );
    final identity = (
      screen: _screen,
      user: user,
      initial: widget.initialModuleId,
    );
    // Keep the coordinator alive even when a scrolling list recycles all rows.
    ref.watch(_expandedModule(identity));
    return _AccordionScope(
      identity: identity,
      child: KeyedSubtree(key: ValueKey(identity), child: widget.child),
    );
  }
}

class _AccordionScope extends InheritedWidget {
  const _AccordionScope({required this.identity, required super.child});
  final _AccordionIdentity identity;

  @override
  bool updateShouldNotify(_AccordionScope oldWidget) =>
      identity != oldWidget.identity;
}

typedef ModuleExpansionBuilder =
    Widget Function(
      BuildContext context,
      ExpansibleController controller,
      bool initiallyExpanded,
      ValueChanged<bool> onExpansionChanged,
    );

/// Owns each tile's controller and synchronizes it with its nearest list scope.
class ModuleAccordionEntry extends ConsumerWidget {
  const ModuleAccordionEntry({
    super.key,
    required this.moduleId,
    required this.builder,
    this.initiallyExpanded = false,
  });
  final String moduleId;
  final bool initiallyExpanded;
  final ModuleExpansionBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AccordionScope>();
    final user = ref.watch(
      authControllerProvider.select((state) => state.value?.user?.id),
    );
    final identity =
        scope?.identity ??
        (
          screen: context,
          user: user,
          initial: initiallyExpanded ? moduleId : null,
        );
    return _ModuleAccordionTile(
      key: ValueKey((identity, moduleId)),
      identity: identity,
      moduleId: moduleId,
      builder: builder,
    );
  }
}

class _ModuleAccordionTile extends ConsumerStatefulWidget {
  const _ModuleAccordionTile({
    super.key,
    required this.identity,
    required this.moduleId,
    required this.builder,
  });
  final _AccordionIdentity identity;
  final String moduleId;
  final ModuleExpansionBuilder builder;

  @override
  ConsumerState<_ModuleAccordionTile> createState() =>
      _ModuleAccordionTileState();
}

class _ModuleAccordionTileState extends ConsumerState<_ModuleAccordionTile> {
  final ExpansibleController _controller = ExpansibleController();
  // ExpansionTile's implicit PageStorage must never override the coordinator
  // when another screen or an earlier login used the same module ID.
  final PageStorageBucket _storage = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final provider = _expandedModule(widget.identity);
    final expanded = ref.watch(provider) == widget.moduleId;
    ref.listen(provider, (_, selected) {
      if (selected == widget.moduleId) {
        if (!_controller.isExpanded) _controller.expand();
      } else if (_controller.isExpanded) {
        _controller.collapse();
      }
    });
    return PageStorage(
      bucket: _storage,
      child: widget.builder(context, _controller, expanded, (open) {
        final notifier = ref.read(provider.notifier);
        if (open) {
          notifier.state = widget.moduleId;
        } else if (notifier.state == widget.moduleId) {
          notifier.state = null;
        }
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
