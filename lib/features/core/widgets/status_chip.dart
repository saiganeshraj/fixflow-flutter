// Fix bad import path in catalog_screen.dart — it uses 'features/core/widgets'
// but the actual path is 'core/widgets'. Let's create a re-export bridge.
export '../../../core/widgets/status_chip.dart';
export '../../../core/widgets/loading_error_empty.dart';
