import 'package:flutter/material.dart';

import 'app/klasflow_demo_app.dart';

// widget_test에서 같은 앱 루트를 재사용할 수 있게 export를 유지한다.
export 'app/klasflow_demo_app.dart';

void main() {
  runApp(const KlasflowDemoApp());
}
